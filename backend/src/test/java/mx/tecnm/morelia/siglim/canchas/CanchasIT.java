package mx.tecnm.morelia.siglim.canchas;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.catchThrowable;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.function.Consumer;
import mx.tecnm.morelia.siglim.BaseDatosPrueba;
import mx.tecnm.morelia.siglim.PartidosPrueba;
import mx.tecnm.morelia.siglim.compartido.contexto.AutenticacionSiglim;
import mx.tecnm.morelia.siglim.compartido.error.RecursoNoEncontradoException;
import mx.tecnm.morelia.siglim.compartido.error.ReglaNegocioException;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.postgresql.util.PSQLException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * H-07.1 contra PostgreSQL real, con {@link CanchaService} completo: autorización, SQL, RLS y
 * triggers. Cada prueba usa canchas nuevas; las fechas son futuras para que los partidos cuenten como
 * programados por venir.
 */
class CanchasIT extends BaseDatosPrueba {

    private static final UUID LIGA = UUID.fromString("a0000000-0000-4000-8000-000000000001");
    private static final OffsetDateTime DIEZ = OffsetDateTime.parse("2031-03-10T10:00:00-06:00");
    private static final String MOTIVO = "Riego de la cancha programado";

    @Autowired
    private CanchaService servicio;

    private PartidosPrueba partidos() {
        return new PartidosPrueba(jdbc);
    }

    // ── Catálogo ──────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("RF-027: una cancha registrada aparece en el catálogo y se filtra por texto, ubicación y activa")
    void catalogoConFiltros() {
        iniciarSesionComoAdministrador();
        String token = "Filtro" + UUID.randomUUID();
        CanchaDto externa = crearCancha(token + " A", UbicacionCancha.EXTERNA);
        crearCancha(token + " B", UbicacionCancha.UNIDAD_DEPORTIVA);

        var porUbicacion = servicio.listar(new FiltroCanchas(true, UbicacionCancha.EXTERNA, null, token.toLowerCase(),
                0, 20, "nombre,asc"));

        assertThat(porUbicacion.contenido()).containsExactly(externa);
        assertThat(porUbicacion.totalElementos()).isEqualTo(1);
    }

    @Test
    @DisplayName("RF-027: el listado pagina, ordena y cuenta el total de todas las páginas")
    void catalogoPaginado() {
        iniciarSesionComoAdministrador();
        String token = "Pagina" + UUID.randomUUID();
        crearCancha(token + " A", UbicacionCancha.EXTERNA);
        crearCancha(token + " B", UbicacionCancha.EXTERNA);
        crearCancha(token + " C", UbicacionCancha.EXTERNA);

        var segunda = servicio.listar(new FiltroCanchas(null, null, null, token, 1, 2, "nombre,desc"));

        assertThat(segunda.contenido()).extracting(CanchaDto::nombre).containsExactly(token + " A");
        assertThat(segunda.totalElementos()).isEqualTo(3);
        assertThat(segunda.totalPaginas()).isEqualTo(2);
    }

    @Test
    @DisplayName("VAL-024: un ámbito de club solo lista y cuenta las canchas de su club")
    void listadoFiltraPorAmbitoDeClub() {
        iniciarSesionComoAdministrador();
        String token = "Ambito" + UUID.randomUUID();
        UUID club = crearClub();
        UUID otroClub = crearClub();
        CanchaDto propia = servicio.crear(new CrearCanchaRequest(token + " propia", UbicacionCancha.EXTERNA, null,
                PropietarioCancha.CLUB, club, null, null));
        CanchaDto ajena = servicio.crear(new CrearCanchaRequest(token + " ajena", UbicacionCancha.EXTERNA, null,
                PropietarioCancha.CLUB, otroClub, null, null));
        crearCancha(token + " liga", UbicacionCancha.EXTERNA);

        iniciarSesion(perfilConRolDeClub(club));
        var pagina = servicio.listar(new FiltroCanchas(null, null, null, token, 0, 20, "nombre,asc"));

        assertThat(pagina.contenido()).extracting(CanchaDto::id).containsExactly(propia.id());
        assertThat(pagina.totalElementos()).isEqualTo(1);
        assertThat(pagina.contenido().getFirst().club().nombre()).isNotBlank();
        assertThatThrownBy(() -> servicio.consultar(ajena.id())).isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("RF-027: editar cambia lo indicado y conserva lo demás")
    void editar() {
        iniciarSesionComoAdministrador();
        CanchaDto cancha = servicio.crear(new CrearCanchaRequest("Edición " + UUID.randomUUID(),
                UbicacionCancha.UNIDAD_DEPORTIVA, "Calle 1", PropietarioCancha.LIGA, null, null, "Pasto"));
        String nombre = "Editada " + UUID.randomUUID();

        CanchaDto editada = servicio.actualizar(cancha.id(), new ActualizarCanchaRequest(nombre, null, null, null, null,
                null, " ", null, null, null));

        assertThat(editada.nombre()).isEqualTo(nombre);
        assertThat(editada.direccion()).isEqualTo("Calle 1");
        assertThat(editada.caracteristicas()).as("en blanco se vacía").isNull();
    }

    @Test
    @DisplayName("RF-027: un nombre repetido en la liga responde 409 DUPLICADO")
    void nombreDuplicado() {
        iniciarSesionComoAdministrador();
        CanchaDto existente = crearCancha("Duplicada " + UUID.randomUUID(), UbicacionCancha.EXTERNA);

        assertThatThrownBy(() -> crearCancha(existente.nombre(), UbicacionCancha.EXTERNA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.CONFLICT, "DUPLICADO"));
    }

    @Test
    @DisplayName("RF-027: un club inexistente lo rechaza la llave foránea con 23503 (D10)")
    void clubInexistente() {
        iniciarSesionComoAdministrador();

        PSQLException error = errorBd(() -> servicio.crear(new CrearCanchaRequest("Sin club " + UUID.randomUUID(),
                UbicacionCancha.EXTERNA, null, PropietarioCancha.CLUB, UUID.randomUUID(), null, null)));

        assertThat(error.getSQLState()).isEqualTo("23503");
    }

    // ── Disponibilidad ────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("RF-029: hasta es exclusivo: [10:00, 12:00) y [12:00, 14:00) no se traslapan")
    void intervalosContiguos() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();

        disponible(cancha, DIEZ, DIEZ.plusHours(2));
        disponible(cancha, DIEZ.plusHours(2), DIEZ.plusHours(4));

        assertThat(servicio.listarDisponibilidad(cancha, DIEZ, DIEZ.plusDays(1))).hasSize(2)
                .extracting(registro -> registro.periodo().desde().toInstant())
                .containsExactly(DIEZ.toInstant(), DIEZ.plusHours(2).toInstant());
    }

    @Test
    @DisplayName("RF-029: una disponibilidad traslapada con otra responde 409 y no se guarda")
    void disponibilidadTraslapada() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        disponible(cancha, DIEZ, DIEZ.plusHours(2));

        assertThatThrownBy(() -> disponible(cancha, DIEZ.plusHours(1), DIEZ.plusHours(3)))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.CONFLICT, "RF-029"));
        assertThat(servicio.listarDisponibilidad(cancha, DIEZ, DIEZ.plusDays(1))).hasSize(1);
    }

    // ── Bloqueo sobre partidos (PEN-007) ──────────────────────────────────────────────────────

    @Test
    @DisplayName("RF-030: un bloqueo sobre un partido responde 409 con el partido; con confirmación se guarda y el partido no cambia")
    void bloqueoSobrePartido() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        UUID partido = partidos().programar(cancha, DIEZ);
        var antes = estadoDelPartido(partido);

        assertThatThrownBy(() -> bloquear(cancha, DIEZ, DIEZ.plusHours(1), null))
                .isInstanceOfSatisfying(ReglaNegocioException.class, excepcion -> {
                    error(HttpStatus.CONFLICT, "RF-030").accept(excepcion);
                    assertThat(excepcion.propiedades()).containsEntry("aceptable", true);
                    assertThat((List<?>) excepcion.propiedades().get("partidosAfectados")).hasSize(1);
                });
        assertThat(servicio.listarDisponibilidad(cancha, DIEZ, DIEZ.plusDays(1))).as("no se guardó").isEmpty();

        RegistroDisponibilidadDto registro = bloquear(cancha, DIEZ, DIEZ.plusHours(1), true);

        assertThat(registro.partidosAfectados()).extracting(PartidoEnCanchaDto::id).containsExactly(partido);
        assertThat(registro.partidosAfectados().getFirst().periodo().hasta().toInstant())
                .as("el trigger calcula el bloque de 120 min").isEqualTo(DIEZ.plusHours(2).toInstant());
        assertThat(estadoDelPartido(partido)).as("estado, inicio y cancha").isEqualTo(antes);
    }

    @Test
    @DisplayName("RF-030: un bloqueo contiguo al bloque del partido no lo afecta")
    void bloqueoContiguo() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        partidos().programar(cancha, DIEZ);

        RegistroDisponibilidadDto registro = bloquear(cancha, DIEZ.plusHours(2), DIEZ.plusHours(3), null);

        assertThat(registro.partidosAfectados()).isEmpty();
    }

    @Test
    @DisplayName("VAL-005: el trigger rechaza un partido nuevo que cae en un bloqueo")
    void partidoEnBloqueo() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        bloquear(cancha, DIEZ, DIEZ.plusHours(2), null);

        PSQLException error = errorBd(() -> partidos().programar(cancha, DIEZ.plusHours(1)));

        assertThat(error.getServerErrorMessage().getHint()).isEqualTo("VAL-005");
    }

    @Test
    @DisplayName("VAL-005: el trigger rechaza un partido nuevo en una cancha inactiva")
    void partidoEnCanchaInactiva() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        servicio.actualizar(cancha, desactivar(null));

        PSQLException error = errorBd(() -> partidos().programar(cancha, DIEZ));

        assertThat(error.getServerErrorMessage().getHint()).isEqualTo("VAL-005");
    }

    @Test
    @DisplayName("RF-030: desactivar una cancha con partidos futuros pide confirmación (D8)")
    void desactivarConPartidosFuturos() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        partidos().programar(cancha, DIEZ);

        assertThatThrownBy(() -> servicio.actualizar(cancha, desactivar(null)))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.CONFLICT, "RF-030"));
        assertThat(servicio.consultar(cancha).activa()).isTrue();

        assertThat(servicio.actualizar(cancha, desactivar(true)).activa()).isFalse();
    }

    // ── Ocupación ─────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("RF-029: la ocupación de una semana une disponibilidad, bloqueo y partido, ordenados por inicio")
    void ocupacionDeUnaSemana() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        disponible(cancha, DIEZ.minusHours(2), DIEZ.plusHours(8));
        UUID partido = partidos().programar(cancha, DIEZ);
        bloquear(cancha, DIEZ.plusHours(4), DIEZ.plusHours(5), null);

        OcupacionDto ocupacion = servicio.consultarOcupacion(cancha, DIEZ.minusDays(1), DIEZ.plusDays(6));

        assertThat(ocupacion.bloques()).extracting(OcupacionDto.BloqueOcupacionDto::tipo).containsExactly(
                TipoBloqueOcupacion.DISPONIBLE, TipoBloqueOcupacion.PARTIDO, TipoBloqueOcupacion.BLOQUEO);
        assertThat(ocupacion.bloques().get(1).partido().id()).isEqualTo(partido);
        assertThat(ocupacion.bloques().get(2).motivo()).isEqualTo(MOTIVO);
        assertThat(ocupacion.bloques().get(1).periodo().desde().getOffset().getTotalSeconds())
                .as("en la zona de negocio, America/Mexico_City").isEqualTo(-6 * 3600);
    }

    // ── Auditoría ─────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("RF-093: cada escritura se audita y el detalle no lleva datos del propietario externo")
    void auditoria() {
        UUID perfil = iniciarSesionComoAdministrador();
        CanchaDto cancha = servicio.crear(new CrearCanchaRequest("Auditada " + UUID.randomUUID(),
                UbicacionCancha.EXTERNA, "Calle Secreta 123", PropietarioCancha.EXTERNO, null, "Sr. Dueño", null));
        servicio.actualizar(cancha.id(), new ActualizarCanchaRequest(null, null, "Calle Nueva 45", null, null,
                "Sra. Dueña", null, null, null, null));
        servicio.actualizar(cancha.id(), desactivar(null));
        servicio.actualizar(cancha.id(), new ActualizarCanchaRequest(null, null, null, null, null, null, null, true,
                MOTIVO, null));

        record Fila(String accion, UUID perfilId, String motivo, String detalle) {
        }
        List<Fila> filas = jdbc.sql("""
                        SELECT accion, perfil_id, motivo, CAST(detalle AS text) AS detalle
                          FROM siglim.auditoria
                         WHERE modulo = 'M-06' AND entidad = 'canchas' AND entidad_id = :id
                         ORDER BY id
                        """)
                .param("id", cancha.id().toString())
                .query(Fila.class)
                .list();

        assertThat(filas).extracting(Fila::accion)
                .containsExactly("REGISTRAR_CANCHA", "EDITAR_CANCHA", "DESACTIVAR_CANCHA", "ACTIVAR_CANCHA");
        assertThat(filas).allSatisfy(fila -> {
            assertThat(fila.perfilId()).isEqualTo(perfil);
            assertThat(fila.detalle()).doesNotContain("Dueñ", "Secreta", "Nueva", "propietarioExterno");
        });
        assertThat(filas.get(2).motivo()).isEqualTo(MOTIVO);
    }

    @Test
    @DisplayName("RF-093: el bloqueo y la disponibilidad se auditan con su periodo")
    void auditoriaDeDisponibilidad() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();

        UUID registro = disponible(cancha, DIEZ, DIEZ.plusHours(1)).disponibilidad().id();
        UUID bloqueo = bloquear(cancha, DIEZ, DIEZ.plusHours(1), null).disponibilidad().id();

        assertThat(accionAuditada(registro)).isEqualTo("REGISTRAR_DISPONIBILIDAD");
        assertThat(accionAuditada(bloqueo)).isEqualTo("BLOQUEAR_CANCHA");
    }

    // ── Permisos con la matriz de la migración ────────────────────────────────────────────────

    @Test
    @DisplayName("VAL-015: el Programador consulta canchas, disponibilidad y ocupación pero no escribe")
    void programadorSoloLee() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        iniciarSesion(perfilConRol("PROGRAMADOR"));

        assertThat(servicio.consultar(cancha).id()).isEqualTo(cancha);
        assertThat(servicio.listarDisponibilidad(cancha, DIEZ, DIEZ.plusDays(1))).isEmpty();
        assertThat(servicio.consultarOcupacion(cancha, DIEZ, DIEZ.plusDays(1)).bloques()).isEmpty();
        assertThatThrownBy(() -> bloquear(cancha, DIEZ, DIEZ.plusHours(1), null))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.FORBIDDEN, "VAL-015"));
        assertThatThrownBy(() -> crearCancha("No debe " + UUID.randomUUID(), UbicacionCancha.EXTERNA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.FORBIDDEN, "VAL-015"));
    }

    @Test
    @DisplayName("VAL-015: un rol sin canchas.* no consulta ni lista")
    void rolSinPermisos() {
        iniciarSesionComoAdministrador();
        UUID cancha = nuevaCancha();
        iniciarSesion(perfilConRol("CAPTURISTA"));

        assertThatThrownBy(() -> servicio.consultar(cancha))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.FORBIDDEN, "VAL-015"));
        assertThatThrownBy(() -> servicio.listar(new FiltroCanchas(null, null, null, null, 0, 20, "nombre,asc")))
                .isInstanceOfSatisfying(ReglaNegocioException.class, error(HttpStatus.FORBIDDEN, "VAL-015"));
    }

    // ── Apoyo ─────────────────────────────────────────────────────────────────────────────────

    private CanchaDto crearCancha(String nombre, UbicacionCancha ubicacion) {
        return servicio.crear(new CrearCanchaRequest(nombre, ubicacion, null, PropietarioCancha.LIGA, null, null, null));
    }

    private UUID nuevaCancha() {
        return crearCancha("Cancha " + UUID.randomUUID(), UbicacionCancha.UNIDAD_DEPORTIVA).id();
    }

    private RegistroDisponibilidadDto disponible(UUID cancha, OffsetDateTime desde, OffsetDateTime hasta) {
        return servicio.registrarDisponibilidad(cancha, new RegistrarDisponibilidadRequest(
                TipoDisponibilidad.DISPONIBLE, new Intervalo(desde, hasta), null, null));
    }

    private RegistroDisponibilidadDto bloquear(UUID cancha, OffsetDateTime desde, OffsetDateTime hasta, Boolean confirmar) {
        return servicio.registrarDisponibilidad(cancha, new RegistrarDisponibilidadRequest(
                TipoDisponibilidad.BLOQUEO, new Intervalo(desde, hasta), MOTIVO, confirmar));
    }

    private static ActualizarCanchaRequest desactivar(Boolean confirmar) {
        return new ActualizarCanchaRequest(null, null, null, null, null, null, null, false, MOTIVO, confirmar);
    }

    private String estadoDelPartido(UUID partido) {
        return jdbc.sql("SELECT estado || ' ' || inicio || ' ' || cancha_id FROM siglim.partidos WHERE id = :id")
                .param("id", partido).query(String.class).single();
    }

    private String accionAuditada(UUID entidad) {
        return jdbc.sql("""
                        SELECT accion FROM siglim.auditoria
                         WHERE entidad = 'disponibilidad_canchas' AND entidad_id = :id
                        """)
                .param("id", entidad.toString()).query(String.class).single();
    }

    private UUID crearClub() {
        return jdbc.sql("INSERT INTO siglim.clubes (liga_id, nombre) VALUES (:liga, :nombre) RETURNING id")
                .param("liga", LIGA).param("nombre", "Club " + UUID.randomUUID()).query(UUID.class).single();
    }

    private UUID crearPerfil() {
        return jdbc.sql("INSERT INTO siglim.perfiles (nombre_mostrado) VALUES ('Usuario de prueba') RETURNING id")
                .query(UUID.class).single();
    }

    /** Perfil con un rol de la matriz de la migración, con su ámbito predeterminado. */
    private UUID perfilConRol(String rol) {
        UUID perfil = crearPerfil();
        jdbc.sql("""
                        INSERT INTO siglim.asignaciones_rol (perfil_id, rol_id, liga_id, ambito)
                        SELECT :perfil, id, liga_id, ambito_predeterminado FROM siglim.roles WHERE codigo = :rol
                        """)
                .param("perfil", perfil).param("rol", rol).update();
        return perfil;
    }

    /**
     * Perfil con un rol propio que da {@code CONSULTAR} en ámbito de club: ningún rol de la matriz lo
     * tiene hoy, y el filtro del listado debe funcionar cuando la Liga configure uno (DD-009).
     */
    private UUID perfilConRolDeClub(UUID club) {
        UUID rol = jdbc.sql("""
                        INSERT INTO siglim.roles (liga_id, codigo, nombre, ambito_predeterminado)
                        VALUES (:liga, :codigo, 'Rol de prueba', 'CLUB') RETURNING id
                        """)
                .param("liga", LIGA)
                .param("codigo", "PRUEBA_" + UUID.randomUUID().toString().substring(0, 8))
                .query(UUID.class).single();
        jdbc.sql("""
                        INSERT INTO siglim.rol_permisos (rol_id, permiso_id)
                        SELECT :rol, id FROM siglim.permisos WHERE codigo = 'canchas.cancha:CONSULTAR'
                        """)
                .param("rol", rol).update();
        UUID perfil = crearPerfil();
        jdbc.sql("""
                        INSERT INTO siglim.asignaciones_rol (perfil_id, rol_id, liga_id, ambito, club_id)
                        VALUES (:perfil, :rol, :liga, 'CLUB', :club)
                        """)
                .param("perfil", perfil).param("rol", rol).param("liga", LIGA).param("club", club).update();
        return perfil;
    }

    private static void iniciarSesion(UUID perfil) {
        Jwt token = Jwt.withTokenValue("token-de-prueba").header("alg", "ES256")
                .subject(UUID.randomUUID().toString())
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600)).build();
        SecurityContextHolder.getContext().setAuthentication(new AutenticacionSiglim(token, perfil));
    }

    private static Consumer<ReglaNegocioException> error(HttpStatus estado, String codigo) {
        return excepcion -> {
            assertThat(excepcion.estado()).isEqualTo(estado);
            assertThat(excepcion.codigo()).isEqualTo(codigo);
        };
    }

    /** El error de PostgreSQL de la cadena de causas; se compara SQLSTATE o HINT, nunca el texto. */
    private static PSQLException errorBd(ThrowingCallable operacion) {
        Throwable error = catchThrowable(operacion);
        for (Throwable causa = error; causa != null; causa = causa.getCause()) {
            if (causa instanceof PSQLException psql) {
                return psql;
            }
        }
        throw new AssertionError("Se esperaba un error de PostgreSQL y se obtuvo: " + error, error);
    }
}
