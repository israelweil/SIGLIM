package mx.tecnm.morelia.siglim.seguridad;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import mx.tecnm.morelia.siglim.BaseDatosPrueba;
import mx.tecnm.morelia.siglim.compartido.contexto.AutenticacionSiglim;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PerfilDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PermisoDto;
import mx.tecnm.morelia.siglim.seguridad.YoRepository.FilaAsignacion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Consultas de {@code GET /api/v1/yo} contra PostgreSQL real, con los roles y la matriz de
 * permisos de la migración. Cada prueba crea su propio perfil (como dueño del esquema) y consulta
 * dentro de una transacción de solo lectura con la sesión de ese perfil, es decir, como
 * {@code siglim_app} sujeto a RLS.
 */
class YoRepositoryIT extends BaseDatosPrueba {

    private static final UUID LIGA = UUID.fromString("a0000000-0000-4000-8000-000000000001");

    @Autowired
    private YoRepository repositorio;

    @Autowired
    private PlatformTransactionManager transacciones;

    @Test
    @DisplayName("RF-094: devuelve el perfil y sus asignaciones LIGA y CLUB, primero LIGA, con el nombre del club")
    void asignacionesLigaYClub() {
        UUID perfil = crearPerfil("Ana López");
        UUID club = crearClub();
        UUID liga = asignar(perfil, "PROGRAMADOR", null, true);
        UUID deClub = asignar(perfil, "DIRECTIVA_CLUB", club, true);

        PerfilDto encontrado = conSesion(perfil, () -> repositorio.buscarPerfil(perfil));
        List<FilaAsignacion> asignaciones = conSesion(perfil, () -> repositorio.listarAsignacionesActivas(perfil));

        assertThat(encontrado).isEqualTo(new PerfilDto(perfil, "Ana López", null));
        assertThat(asignaciones).containsExactly(
                new FilaAsignacion(liga, "PROGRAMADOR", "Programador de partidos", "LIGA", null, null),
                new FilaAsignacion(deClub, "DIRECTIVA_CLUB", "Directiva de club", "CLUB", club,
                        nombreClub(club)));
    }

    @Test
    @DisplayName("H-01.1: excluye una asignación revocada y los permisos que solo ella daba")
    void excluyeAsignacionRevocada() {
        UUID perfil = crearPerfil("Beto Ruiz");
        UUID activa = asignar(perfil, "ARBITRO", null, true);
        asignar(perfil, "CAPTURISTA", null, false);

        List<FilaAsignacion> asignaciones = conSesion(perfil, () -> repositorio.listarAsignacionesActivas(perfil));
        List<PermisoDto> permisos = conSesion(perfil, () -> repositorio.listarPermisosEfectivos(perfil));

        assertThat(asignaciones).extracting(FilaAsignacion::id).containsExactly(activa);
        assertThat(permisos).extracting(PermisoDto::codigo)
                .contains("partidos.cedula:APROBAR")
                .doesNotContain("partidos.cedula:CAPTURAR");
    }

    @Test
    @DisplayName("H-01.1: no devuelve asignaciones ni permisos de otro perfil")
    void noDevuelveDatosDeOtroPerfil() {
        UUID perfil = crearPerfil("Carla Díaz");
        UUID otro = crearPerfil("Daniel Soto");
        UUID propia = asignar(perfil, "JUGADOR_TUTOR", null, true);
        asignar(otro, "TESORERO", null, true);

        List<FilaAsignacion> asignaciones = conSesion(perfil, () -> repositorio.listarAsignacionesActivas(perfil));
        List<PermisoDto> permisos = conSesion(perfil, () -> repositorio.listarPermisosEfectivos(perfil));

        assertThat(asignaciones).extracting(FilaAsignacion::id).containsExactly(propia);
        assertThat(permisos).extracting(PermisoDto::codigo).noneMatch(codigo -> codigo.startsWith("tesoreria."));
    }

    @Test
    @DisplayName("H-01.1: un permiso de dos roles con el mismo ámbito y club aparece una sola vez")
    void permisoDeDosRolesSinDuplicados() {
        UUID perfil = crearPerfil("Elena Mora");
        UUID club = crearClub();
        // PROGRAMADOR y COMISION_ARBITRAJE comparten partidos.partido:CONSULTAR, ambos con ámbito LIGA.
        asignar(perfil, "PROGRAMADOR", null, true);
        asignar(perfil, "COMISION_ARBITRAJE", null, true);
        asignar(perfil, "DIRECTIVA_CLUB", club, true);

        List<PermisoDto> permisos = conSesion(perfil, () -> repositorio.listarPermisosEfectivos(perfil));

        assertThat(permisos).filteredOn(permiso -> permiso.codigo().equals("partidos.partido:CONSULTAR"))
                .as("uno por ámbito y club, LIGA antes que CLUB (orden del enum)")
                .containsExactly(
                        new PermisoDto("partidos.partido:CONSULTAR", "M-08", "LIGA", null),
                        new PermisoDto("partidos.partido:CONSULTAR", "M-08", "CLUB", club));
        assertThat(permisos).doesNotHaveDuplicates();
    }

    // ── Apoyo ─────────────────────────────────────────────────────────────────────────────────

    /** Ejecuta la consulta en una transacción de solo lectura con la sesión del perfil. */
    private <T> T conSesion(UUID perfil, Supplier<T> consulta) {
        Jwt token = Jwt.withTokenValue("token-de-prueba")
                .header("alg", "ES256")
                .subject(UUID.randomUUID().toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        SecurityContextHolder.getContext().setAuthentication(new AutenticacionSiglim(token, perfil));
        TransactionTemplate lectura = new TransactionTemplate(transacciones);
        lectura.setReadOnly(true);
        return lectura.execute(estado -> {
            assertThat(jdbc.sql("SELECT current_user").query(String.class).single()).isEqualTo("siglim_app");
            return consulta.get();
        });
    }

    // Los datos se crean como dueño del esquema (fuera de transacción) y quedan en el contenedor:
    // cada prueba usa perfiles y clubes nuevos para no depender de las demás.

    private UUID crearPerfil(String nombre) {
        return jdbc.sql("INSERT INTO siglim.perfiles (nombre_mostrado) VALUES (:nombre) RETURNING id")
                .param("nombre", nombre).query(UUID.class).single();
    }

    private UUID crearClub() {
        return jdbc.sql("INSERT INTO siglim.clubes (liga_id, nombre) VALUES (:liga, :nombre) RETURNING id")
                .param("liga", LIGA)
                .param("nombre", "Club de prueba " + UUID.randomUUID())
                .query(UUID.class).single();
    }

    private String nombreClub(UUID club) {
        return jdbc.sql("SELECT nombre FROM siglim.clubes WHERE id = :id").param("id", club)
                .query(String.class).single();
    }

    /** Asigna el rol con ámbito CLUB si se indica club; si no, con el ámbito predeterminado del rol. */
    private UUID asignar(UUID perfil, String rol, UUID club, boolean activa) {
        return jdbc.sql("""
                        INSERT INTO siglim.asignaciones_rol (perfil_id, rol_id, liga_id, ambito, club_id, activa, revocada_en)
                        SELECT :perfil, r.id, r.liga_id,
                               CASE WHEN CAST(:club AS uuid) IS NULL THEN r.ambito_predeterminado ELSE 'CLUB' END,
                               :club, :activa, CASE WHEN :activa THEN NULL ELSE now() END
                          FROM siglim.roles r
                         WHERE r.codigo = :rol
                        RETURNING id
                        """)
                .param("perfil", perfil)
                .param("rol", rol)
                .param("club", club)
                .param("activa", activa)
                .query(UUID.class).single();
    }
}
