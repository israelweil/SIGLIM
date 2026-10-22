package mx.tecnm.morelia.siglim.compartido.contexto;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import javax.sql.DataSource;
import mx.tecnm.morelia.siglim.BaseDatosPrueba;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Criterio de terminado de T-02.3, contra PostgreSQL real con el esquema del repositorio: el
 * trigger registra el perfil del token y, sin contexto, la base de datos niega.
 *
 * <p>El contenedor, el esquema y las cuentas de prueba vienen de {@link BaseDatosPrueba}; su pool
 * de una conexión permite comprobar que el contexto no se filtra entre transacciones.
 */
class ContextoTransaccionIT extends BaseDatosPrueba {

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
                // Se compara el SQLSTATE y no el texto: Spring 7 no copia el mensaje de la causa y
                // PostgreSQL traduce sus mensajes según el idioma del servidor.
                .rootCause()
                .isInstanceOfSatisfying(SQLException.class, error ->
                        assertThat(error.getSQLState()).as("42501 insufficient_privilege").isEqualTo("42501"));
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

    private long contarPerfilesComoDueno() {
        return jdbc.sql("SELECT count(*) FROM siglim.perfiles").query(Long.class).single();
    }
}
