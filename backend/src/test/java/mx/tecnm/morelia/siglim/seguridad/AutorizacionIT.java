package mx.tecnm.morelia.siglim.seguridad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import mx.tecnm.morelia.siglim.BaseDatosPrueba;
import mx.tecnm.morelia.siglim.compartido.contexto.AutenticacionSiglim;
import mx.tecnm.morelia.siglim.compartido.error.RecursoNoEncontradoException;
import mx.tecnm.morelia.siglim.compartido.error.ReglaNegocioException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Criterio de terminado de H-02.1 contra PostgreSQL real: los ámbitos {@code LIGA}, {@code CLUB} y
 * {@code PROPIO} de la matriz de permisos de la migración.
 *
 * <p>Cada prueba crea su perfil (como dueño del esquema), le pone la sesión y llama a
 * {@code exigir} a través del componente, que abre su transacción con {@code siglim_app} y el
 * contexto de usuario. Así se prueba la regla completa: decisión, SQL y función {@code es_titular}
 * de la base.
 */
class AutorizacionIT extends BaseDatosPrueba {

    private static final UUID LIGA = UUID.fromString("a0000000-0000-4000-8000-000000000001");
    private static final String PARTIDO_CONSULTAR = "partidos.partido:CONSULTAR";
    private static final String REGISTRO_CONSULTAR = "registros.registro:CONSULTAR";
    private static final String TEMPORADA_EDITAR = "temporadas.temporada:EDITAR";

    @Autowired
    private Autorizacion autorizacion;

    @Autowired
    private PlatformTransactionManager transacciones;

    @Test
    @DisplayName("RF-094: el ámbito LIGA alcanza el recurso de cualquier club")
    void ligaAlcanzaCualquierClub() {
        UUID perfil = crearPerfil("Ana López");
        asignarRol(perfil, "PROGRAMADOR", null, true);
        UUID clubAjeno = crearClub();
        iniciarSesion(perfil);

        assertThatCode(() -> autorizacion.exigir(PARTIDO_CONSULTAR, ObjetivoAutorizacion.deClubes(clubAjeno)))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("RF-094: el ámbito CLUB alcanza su club, también en un partido contra otro club")
    void clubAlcanzaSuClub() {
        UUID perfil = crearPerfil("Beto Ruiz");
        UUID clubPropio = crearClub();
        asignarRol(perfil, "DIRECTIVA_CLUB", clubPropio, true);
        iniciarSesion(perfil);

        assertThatCode(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.deClubes(clubPropio)))
                .doesNotThrowAnyException();
        assertThatCode(() -> autorizacion.exigir(REGISTRO_CONSULTAR,
                ObjetivoAutorizacion.deClubes(clubPropio, crearClub())))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("VAL-024: el ámbito CLUB no alcanza el club de otro y coincide con club_visible de RLS")
    void clubNoAlcanzaOtroClub() {
        UUID perfil = crearPerfil("Carla Díaz");
        UUID clubPropio = crearClub();
        UUID clubAjeno = crearClub();
        asignarRol(perfil, "DIRECTIVA_CLUB", clubPropio, true);
        iniciarSesion(perfil);

        assertThatThrownBy(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.deClubes(clubAjeno)))
                .isInstanceOf(RecursoNoEncontradoException.class);

        // ADR-0007 §4: la regla de ámbito del servicio y la política RLS deben coincidir.
        assertThat(clubVisible(clubPropio)).as("su club").isTrue();
        assertThat(clubVisible(clubAjeno)).as("el club de otro").isFalse();
    }

    @Test
    @DisplayName("RF-144: el ámbito PROPIO alcanza la persona del titular y no un recurso de liga")
    void propioAlcanzaSuPersona() {
        UUID perfil = crearPerfil("Diana Soto");
        UUID persona = crearPersona("Diana Soto");
        vincularPersona(perfil, persona);
        asignarRol(perfil, "JUGADOR_TUTOR", null, true);
        iniciarSesion(perfil);

        assertThatCode(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.dePersonas(persona)))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.deLiga()))
                .as("un recurso sin personas no pertenece a nadie en ámbito propio")
                .isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("RF-106: el ámbito PROPIO alcanza al menor bajo tutela vigente")
    void propioAlcanzaAlMenorBajoTutela() {
        UUID perfil = crearPerfil("Elena Mora");
        UUID tutor = crearPersona("Elena Mora");
        UUID menor = crearPersona("Fernanda Mora");
        vincularPersona(perfil, tutor);
        crearTutela(menor, tutor, true);
        asignarRol(perfil, "JUGADOR_TUTOR", null, true);
        iniciarSesion(perfil);

        assertThatCode(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.dePersonas(menor)))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("RF-144: el ámbito PROPIO no alcanza a una persona sin tutela vigente")
    void propioNoAlcanzaSinTutelaVigente() {
        UUID perfil = crearPerfil("Fabián Nava");
        UUID tutor = crearPersona("Fabián Nava");
        UUID menor = crearPersona("Greta Nava");
        vincularPersona(perfil, tutor);
        crearTutela(menor, tutor, false);
        asignarRol(perfil, "JUGADOR_TUTOR", null, true);
        iniciarSesion(perfil);

        assertThatThrownBy(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.dePersonas(menor)))
                .isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("VAL-024: el ámbito PROPIO no alcanza la persona de otro")
    void propioNoAlcanzaOtraPersona() {
        UUID perfil = crearPerfil("Hugo Pineda");
        UUID persona = crearPersona("Hugo Pineda");
        vincularPersona(perfil, persona);
        asignarRol(perfil, "JUGADOR_TUTOR", null, true);
        iniciarSesion(perfil);

        assertThatThrownBy(() -> autorizacion.exigir(REGISTRO_CONSULTAR,
                ObjetivoAutorizacion.dePersonas(crearPersona("Irene Vargas"))))
                .isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("VAL-015: sin ninguna asignación que otorgue el permiso responde 403")
    void sinElPermiso() {
        UUID perfil = crearPerfil("Jorge Ávalos");
        asignarRol(perfil, "CAPTURISTA", null, true);
        iniciarSesion(perfil);

        assertThatThrownBy(() -> autorizacion.exigir(TEMPORADA_EDITAR, ObjetivoAutorizacion.deLiga()))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error -> {
                    assertThat(error.estado()).isEqualTo(HttpStatus.FORBIDDEN);
                    assertThat(error.codigo()).isEqualTo("VAL-015");
                });
    }

    @Test
    @DisplayName("RF-094: una asignación revocada ya no otorga el permiso")
    void asignacionRevocadaNoOtorgaPermiso() {
        UUID perfil = crearPerfil("Karla Reyes");
        UUID club = crearClub();
        asignarRol(perfil, "DIRECTIVA_CLUB", club, false);
        iniciarSesion(perfil);

        assertThatThrownBy(() -> autorizacion.exigir(REGISTRO_CONSULTAR, ObjetivoAutorizacion.deClubes(club)))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error ->
                        assertThat(error.codigo()).isEqualTo("VAL-015"));
    }

    // ── Apoyo ─────────────────────────────────────────────────────────────────────────────────

    /** Política de ámbito de RLS, para comparar con la decisión del servicio (ADR-0007 §4). */
    private boolean clubVisible(UUID club) {
        return new TransactionTemplate(transacciones).execute(estado -> jdbc.sql("SELECT club_visible(:club)")
                .param("club", club).query(Boolean.class).single());
    }

    /**
     * Los datos se crean como dueño del esquema (fuera de transacción) y quedan en el contenedor:
     * cada prueba usa sus propios perfiles, clubes y personas para no depender de las demás.
     */
    private UUID crearPerfil(String nombre) {
        return jdbc.sql("INSERT INTO siglim.perfiles (nombre_mostrado) VALUES (:nombre) RETURNING id")
                .param("nombre", nombre).query(UUID.class).single();
    }

    /** Identidad única por CURP (RF-010); la CURP cumple el formato que exige la migración. */
    private UUID crearPersona(String nombre) {
        String curp = "LOPA%06dHDFRRS0%d".formatted(ThreadLocalRandom.current().nextInt(1_000_000),
                ThreadLocalRandom.current().nextInt(10));
        return jdbc.sql("""
                        INSERT INTO siglim.personas (curp, nombre, apellido_paterno, fecha_nacimiento)
                        VALUES (:curp, :nombre, 'Prueba', DATE '2008-06-06')
                        RETURNING id
                        """)
                .param("curp", curp).param("nombre", nombre).query(UUID.class).single();
    }

    private void vincularPersona(UUID perfil, UUID persona) {
        jdbc.sql("UPDATE siglim.perfiles SET persona_id = :persona WHERE id = :perfil")
                .param("persona", persona).param("perfil", perfil).update();
    }

    private void crearTutela(UUID menor, UUID tutor, boolean vigente) {
        jdbc.sql("""
                        INSERT INTO siglim.tutelas (menor_id, tutor_id, parentesco, vigente)
                        VALUES (:menor, :tutor, 'Madre', :vigente)
                        """)
                .param("menor", menor).param("tutor", tutor).param("vigente", vigente).update();
    }

    private UUID crearClub() {
        return jdbc.sql("INSERT INTO siglim.clubes (liga_id, nombre) VALUES (:liga, :nombre) RETURNING id")
                .param("liga", LIGA)
                .param("nombre", "Club de prueba " + UUID.randomUUID())
                .query(UUID.class).single();
    }

    /** Asigna el rol con ámbito CLUB si se indica club; si no, con el ámbito predeterminado del rol. */
    private void asignarRol(UUID perfil, String rol, UUID club, boolean activa) {
        jdbc.sql("""
                        INSERT INTO siglim.asignaciones_rol (perfil_id, rol_id, liga_id, ambito, club_id, activa,
                                                            revocada_en)
                        SELECT :perfil, r.id, r.liga_id,
                               CASE WHEN CAST(:club AS uuid) IS NULL THEN r.ambito_predeterminado ELSE 'CLUB' END,
                               :club, :activa, CASE WHEN :activa THEN NULL ELSE now() END
                          FROM siglim.roles r
                         WHERE r.codigo = :rol
                        """)
                .param("perfil", perfil)
                .param("rol", rol)
                .param("club", club)
                .param("activa", activa)
                .update();
    }

    /** Pone en la petición la sesión de ese perfil, como lo haría la cadena de seguridad. */
    private static void iniciarSesion(UUID perfil) {
        Jwt token = Jwt.withTokenValue("token-de-prueba")
                .header("alg", "ES256")
                .subject(UUID.randomUUID().toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        SecurityContextHolder.getContext().setAuthentication(new AutenticacionSiglim(token, perfil));
    }
}
