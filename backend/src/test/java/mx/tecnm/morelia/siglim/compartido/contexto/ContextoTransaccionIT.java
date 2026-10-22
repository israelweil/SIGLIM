package mx.tecnm.morelia.siglim.compartido.contexto;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;
import javax.sql.DataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.MountableFile;

/**
 * Criterio de terminado de T-02.3, contra PostgreSQL real con el esquema del repositorio: el
 * trigger registra el perfil del token y, sin contexto, la base de datos niega.
 *
 * <p>El contenedor usa PostgreSQL 17, la versión del proyecto de Supabase, y se carga igual que
 * {@code supabase/pruebas/ejecutar.sh}: la simulación de Supabase y todas las migraciones en
 * orden, con {@code psql}. El pool tiene una sola conexión para comprobar que el contexto no se
 * filtra de una transacción a la siguiente, como ocurriría en el pooler de Supabase.
 *
 * <p>Requiere Docker; sin Docker la clase se omite (decisión del equipo del 22 oct 2026).
 */
@SpringBootTest(properties = {
        "SUPABASE_URL=https://proyecto-prueba.supabase.co",
        "SIGLIM_CORS_ORIGEN=http://localhost:5173",
        "spring.datasource.hikari.maximum-pool-size=1"
})
@Testcontainers(disabledWithoutDocker = true)
class ContextoTransaccionIT {

    private static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:17-alpine");

    private static final UUID SUB_ADMIN = UUID.fromString("6f1d2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b");
    private static final UUID SUB_INACTIVO = UUID.fromString("1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d");

    @DynamicPropertySource
    static void baseDeDatos(DynamicPropertyRegistry registro) {
        if (!POSTGRES.isRunning()) {
            POSTGRES.start();
            cargarEsquema();
        }
        // Las mismas variables de backend/.env: también prueba la configuración de T-02.1.
        registro.add("DB_URL", POSTGRES::getJdbcUrl);
        registro.add("DB_USERNAME", POSTGRES::getUsername);
        registro.add("DB_PASSWORD", POSTGRES::getPassword);
    }

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private DataSource fuenteDatos;

    @Autowired
    private PlatformTransactionManager transacciones;

    @Autowired
    private MotivoOperacion motivoOperacion;

    @Autowired
    private ResolutorPerfil resolutorPerfil;

    /** Lo que se observa dentro de una transacción con sesión. */
    record Resultado(String rolBd, UUID usuarioActual, UUID cambiadoPor) {
    }

    /** Estado de la conexión fuera de la transacción. */
    record Sesion(String rolBd, String claims, String searchPath) {
    }

    @AfterEach
    void cerrarSesion() {
        SecurityContextHolder.clearContext();
    }

    // ── Criterio de terminado ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("T-02.3: con sesión, la transacción es siglim_app y el trigger registra el perfil del token")
    void triggerRegistraElPerfilDelToken() {
        UUID perfil = iniciarSesionComoAdministrador();

        Resultado resultado = new TransactionTemplate(transacciones).execute(estado -> {
            String rolBd = jdbc.sql("SELECT current_user").query(String.class).single();
            UUID usuarioActual = jdbc.sql("SELECT siglim.usuario_actual()").query(UUID.class).single();
            UUID comunicado = crearComunicado(perfil);
            enviarARevision(comunicado);
            UUID cambiadoPor = jdbc.sql("SELECT cambiado_por FROM historial_publicacion WHERE entidad_id = :id")
                    .param("id", comunicado).query(UUID.class).single();
            return new Resultado(rolBd, usuarioActual, cambiadoPor);
        });

        assertThat(resultado.rolBd()).isEqualTo("siglim_app");
        assertThat(resultado.usuarioActual()).isEqualTo(perfil);
        assertThat(resultado.cambiadoPor()).as("historial_publicacion.cambiado_por").isEqualTo(perfil);
    }

    @Test
    @DisplayName("T-02.3: sin contexto de usuario, RLS no deja ver ningún perfil a siglim_app")
    void sinContextoRlsNiega() throws SQLException {
        // Simula un error de programación: adoptar siglim_app sin fijar el perfil.
        try (Connection conexion = fuenteDatos.getConnection()) {
            conexion.setAutoCommit(false);
            try (Statement sentencia = conexion.createStatement()) {
                sentencia.execute("SET LOCAL ROLE siglim_app");
                try (ResultSet filas = sentencia.executeQuery("SELECT count(*) FROM siglim.perfiles")) {
                    filas.next();
                    assertThat(filas.getLong(1)).as("perfiles visibles sin contexto").isZero();
                }
            } finally {
                conexion.rollback();
                conexion.setAutoCommit(true);
            }
        }
        assertThat(contarPerfilesComoDueno()).as("los perfiles sí existen").isGreaterThanOrEqualTo(2);
    }

    // ── Comportamiento del contexto ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("ADR-0014: sin sesión, la transacción es siglim_publico: lee vistas públicas, no tablas")
    void sinSesionEsPublico() {
        TransactionTemplate plantilla = new TransactionTemplate(transacciones);

        String rolBd = plantilla.execute(estado -> {
            jdbc.sql("SELECT count(*) FROM v_publica_programacion").query(Long.class).single();
            return jdbc.sql("SELECT current_user").query(String.class).single();
        });
        assertThat(rolBd).isEqualTo("siglim_publico");

        assertThatThrownBy(() -> plantilla.execute(estado ->
                jdbc.sql("SELECT count(*) FROM perfiles").query(Long.class).single()))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("permission denied");
    }

    @Test
    @DisplayName("ADR-0005 punto 5: el contexto no se filtra a lo que sigue en la misma conexión")
    void contextoNoSeFiltra() {
        iniciarSesionComoAdministrador();
        new TransactionTemplate(transacciones).execute(estado ->
                jdbc.sql("SELECT siglim.usuario_actual()").query(UUID.class).single());

        // Pool de una conexión: esta consulta usa la misma conexión física, ya fuera de la transacción.
        Sesion despues = jdbc.sql("""
                        SELECT current_user AS rol_bd,
                               coalesce(current_setting('request.jwt.claims', true), '') AS claims,
                               current_setting('search_path') AS search_path
                        """).query(Sesion.class).single();

        assertThat(despues.rolBd()).isEqualTo(POSTGRES.getUsername());
        assertThat(despues.claims()).isEmpty();
        assertThat(despues.searchPath()).doesNotContain("siglim");
    }

    @Test
    @DisplayName("RN-021: el motivo fijado con MotivoOperacion lo exige y lo guarda el trigger")
    void motivoDeLaOperacion() {
        UUID perfil = iniciarSesionComoAdministrador();
        TransactionTemplate plantilla = new TransactionTemplate(transacciones);

        assertThatThrownBy(() -> plantilla.execute(estado -> {
            UUID comunicado = crearComunicado(perfil);
            enviarARevision(comunicado);
            return devolverABorrador(comunicado);
        })).as("devolver sin motivo").isInstanceOf(DataAccessException.class)
                .hasMessageContaining("La devolución requiere observaciones");

        String motivoGuardado = plantilla.execute(estado -> {
            UUID comunicado = crearComunicado(perfil);
            enviarARevision(comunicado);
            motivoOperacion.fijar("Falta la sede del torneo");
            devolverABorrador(comunicado);
            return jdbc.sql("""
                            SELECT motivo FROM historial_publicacion
                             WHERE entidad_id = :id AND estado_nuevo = 'BORRADOR'
                            """).param("id", comunicado).query(String.class).single();
        });
        assertThat(motivoGuardado).isEqualTo("Falta la sede del torneo");
    }

    @Test
    @DisplayName("RN-021: MotivoOperacion fuera de una transacción es un error de programación")
    void motivoFueraDeTransaccion() {
        assertThatThrownBy(() -> motivoOperacion.fijar("motivo"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("ADR-0005: readOnly también se fuerza en PostgreSQL y conserva el contexto")
    void soloLecturaEnLaBaseDeDatos() {
        iniciarSesionComoAdministrador();
        TransactionTemplate lectura = new TransactionTemplate(transacciones);
        lectura.setReadOnly(true);

        String soloLectura = lectura.execute(estado -> {
            assertThat(jdbc.sql("SELECT current_user").query(String.class).single()).isEqualTo("siglim_app");
            return jdbc.sql("SELECT current_setting('transaction_read_only')").query(String.class).single();
        });
        assertThat(soloLectura).isEqualTo("on");
    }

    @Test
    @DisplayName("ADR-0003 punto 6: el resolutor encuentra perfiles activos e inactivos por auth.users.id")
    void resolutorDePerfiles() {
        assertThat(resolutorPerfil.buscarPorUsuarioAuth(SUB_ADMIN))
                .hasValueSatisfying(perfil -> assertThat(perfil.activo()).isTrue());
        assertThat(resolutorPerfil.buscarPorUsuarioAuth(SUB_INACTIVO))
                .hasValueSatisfying(perfil -> assertThat(perfil.activo()).isFalse());
        assertThat(resolutorPerfil.buscarPorUsuarioAuth(UUID.randomUUID())).isEmpty();
    }

    // ── Apoyo ─────────────────────────────────────────────────────────────────────────────────

    /** Pone en la petición la sesión del Administrador general, como lo haría la cadena de seguridad. */
    private UUID iniciarSesionComoAdministrador() {
        UUID perfil = jdbc.sql("SELECT id FROM siglim.perfiles WHERE usuario_auth_id = :sub")
                .param("sub", SUB_ADMIN).query(UUID.class).single();
        Jwt token = Jwt.withTokenValue("token-de-prueba")
                .header("alg", "ES256")
                .subject(SUB_ADMIN.toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        SecurityContextHolder.getContext().setAuthentication(new AutenticacionSiglim(token, perfil));
        return perfil;
    }

    private long contarPerfilesComoDueno() {
        return jdbc.sql("SELECT count(*) FROM siglim.perfiles").query(Long.class).single();
    }

    private UUID crearComunicado(UUID redactor) {
        return jdbc.sql("""
                        INSERT INTO comunicados (liga_id, titulo, cuerpo, redactado_por)
                        SELECT id, 'Comunicado de prueba', 'Cuerpo', :redactor FROM ligas LIMIT 1
                        RETURNING id
                        """).param("redactor", redactor).query(UUID.class).single();
    }

    private void enviarARevision(UUID comunicado) {
        jdbc.sql("UPDATE comunicados SET estado_publicacion = 'REVISION' WHERE id = :id")
                .param("id", comunicado).update();
    }

    private int devolverABorrador(UUID comunicado) {
        return jdbc.sql("UPDATE comunicados SET estado_publicacion = 'BORRADOR' WHERE id = :id")
                .param("id", comunicado).update();
    }

    /** Carga el esquema como {@code supabase/pruebas/ejecutar.sh} y crea las cuentas de prueba. */
    private static void cargarEsquema() {
        Path supabase = Path.of("..", "supabase").toAbsolutePath().normalize();
        List<Path> scripts = new ArrayList<>();
        scripts.add(supabase.resolve("pruebas/mock_supabase.sql"));
        try (Stream<Path> migraciones = Files.list(supabase.resolve("migrations"))) {
            migraciones.filter(ruta -> ruta.toString().endsWith(".sql")).sorted().forEach(scripts::add);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudieron listar las migraciones de " + supabase, e);
        }
        for (Path script : scripts) {
            String destino = "/tmp/" + script.getFileName();
            POSTGRES.copyFileToContainer(MountableFile.forHostPath(script), destino);
            psql("-f", destino);
        }
        psql("-c", """
                INSERT INTO auth.users (id, email, aud, role) VALUES
                  ('%s', 'admin@prueba.mx', 'authenticated', 'authenticated'),
                  ('%s', 'inactivo@prueba.mx', 'authenticated', 'authenticated');
                SELECT siglim.registrar_administrador_inicial('admin@prueba.mx');
                INSERT INTO siglim.perfiles (usuario_auth_id, nombre_mostrado, correo, activo)
                VALUES ('%s', 'inactivo', 'inactivo@prueba.mx', false);
                """.formatted(SUB_ADMIN, SUB_INACTIVO, SUB_INACTIVO));
    }

    private static void psql(String... argumentos) {
        List<String> comando = new ArrayList<>(List.of("psql", "-q", "-v", "ON_ERROR_STOP=1",
                "-U", POSTGRES.getUsername(), "-d", POSTGRES.getDatabaseName()));
        comando.addAll(List.of(argumentos));
        try {
            Container.ExecResult resultado = POSTGRES.execInContainer(comando.toArray(String[]::new));
            if (resultado.getExitCode() != 0) {
                throw new IllegalStateException("psql " + String.join(" ", argumentos) + " falló:\n"
                        + resultado.getStderr());
            }
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo ejecutar psql en el contenedor", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrumpido al cargar el esquema", e);
        }
    }
}
