package mx.tecnm.morelia.siglim.compartido.error;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.postgresql.util.PSQLException;
import org.postgresql.util.ServerErrorMessage;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.CannotGetJdbcConnectionException;

/**
 * Traducción de errores de PostgreSQL (convenciones de API §3.2). Prueba unitaria, sin Spring ni
 * base de datos: las excepciones se construyen con el mismo formato que envía el servidor
 * ({@code C} = SQLSTATE, {@code M} = mensaje, {@code H} = HINT, {@code n} = restricción).
 */
class TraductorErroresBdTest {

    /** Comentarios como los de la migración (COMMENT ON CONSTRAINT … IS 'VAL-004: …'). */
    private static final Map<String, String> COMENTARIOS = Map.of(
            "ex_partidos_cancha_ocupada", "VAL-004: la cancha ya está ocupada en ese horario.",
            "ux_registro_curp_temporada", "VAL-006: la CURP ya tiene un registro activo en la temporada.");

    private final TraductorErroresBd traductor =
            new TraductorErroresBd(nombre -> Optional.ofNullable(COMENTARIOS.get(nombre)));

    /** Excepción como la que Spring entrega al controlador, con la de PostgreSQL como causa. */
    private static RuntimeException errorBd(String sqlState, String mensaje, String hint, String restriccion) {
        StringBuilder servidor = new StringBuilder("SERROR\0C").append(sqlState).append("\0M").append(mensaje).append('\0');
        if (hint != null) {
            servidor.append('H').append(hint).append('\0');
        }
        if (restriccion != null) {
            servidor.append('n').append(restriccion).append('\0');
        }
        return new DataIntegrityViolationException("error de prueba",
                new PSQLException(new ServerErrorMessage(servidor.toString())));
    }

    private ErrorTraducido escritura(RuntimeException error) {
        return traductor.traducir(error, false);
    }

    @Nested
    @DisplayName("Criterio de terminado de T-02.4")
    class CriterioDeTerminado {

        @Test
        @DisplayName("VAL-003: P0001 con HINT VAL-003 responde 409 con el mensaje sin el prefijo del código")
        void p0001ConHintVal003() {
            var error = errorBd("P0001", "VAL-003: El equipo Halcones ya juega a esa hora.", "VAL-003", null);

            assertThat(escritura(error)).isEqualTo(new ErrorTraducido(
                    HttpStatus.CONFLICT, "VAL-003", "El equipo Halcones ya juega a esa hora."));
        }

        @Test
        @DisplayName("VAL-004: 23P01 (exclusión de la cancha) responde 409 VAL-004")
        void exclusionDeCancha() {
            var error = errorBd("23P01", "conflicting key value violates exclusion constraint", null,
                    "ex_partidos_cancha_ocupada");

            assertThat(escritura(error)).isEqualTo(new ErrorTraducido(
                    HttpStatus.CONFLICT, "VAL-004", "La cancha ya está ocupada en ese horario."));
        }

        @Test
        @DisplayName("VAL-024: 42501 en una lectura responde 404 NO_ENCONTRADO")
        void privilegioEnLectura() {
            var error = errorBd("42501", "permission denied for table perfiles", null, null);

            ErrorTraducido traducido = traductor.traducir(error, true);

            assertThat(traducido.estado()).isEqualTo(HttpStatus.NOT_FOUND);
            assertThat(traducido.codigo()).isEqualTo("NO_ENCONTRADO");
            assertThat(traducido.detalle()).doesNotContain("perfiles").doesNotContain("permission");
        }
    }

    @Nested
    @DisplayName("P0001: errores de negocio de los triggers")
    class ErroresDeNegocio {

        @Test
        @DisplayName("El estado HTTP sale de TablaCodigosHttp: 400, 403 y 422")
        void estadoSegunLaTabla() {
            assertThat(escritura(errorBd("P0001", "RN-021: Falta el motivo.", "RN-021", null)).estado())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(escritura(errorBd("P0001", "VAL-021: No puede aprobar su propia cédula.", "VAL-021", null)).estado())
                    .isEqualTo(HttpStatus.FORBIDDEN);
            assertThat(escritura(errorBd("P0001", "VAL-018: Faltan documentos.", "VAL-018", null)).estado())
                    .isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT);
        }

        @Test
        @DisplayName("Un código sin mapeo responde 409 con ese código (convenciones §3.2)")
        void codigoSinMapeo() {
            var error = errorBd("P0001", "VAL-099: Regla nueva.", "VAL-099", null);

            assertThat(escritura(error)).isEqualTo(new ErrorTraducido(HttpStatus.CONFLICT, "VAL-099", "Regla nueva."));
        }

        @Test
        @DisplayName("Un RAISE sin HINT no es una regla del ERS: 500 ERROR_INTERNO")
        void raiseSinCodigo() {
            var error = errorBd("P0001", "Ya existe un Administrador general", null, null);

            assertThat(escritura(error).codigo()).isEqualTo("ERROR_INTERNO");
            assertThat(escritura(error).esInterno()).isTrue();
        }
    }

    @Nested
    @DisplayName("Restricciones de integridad")
    class Restricciones {

        @Test
        @DisplayName("23505 con el código documentado en el comentario del índice")
        void unicidadDocumentada() {
            var error = errorBd("23505", "duplicate key value", null, "ux_registro_curp_temporada");

            assertThat(escritura(error)).isEqualTo(new ErrorTraducido(
                    HttpStatus.CONFLICT, "VAL-006", "La CURP ya tiene un registro activo en la temporada."));
        }

        @Test
        @DisplayName("23505 sin comentario: 409 DUPLICADO")
        void unicidadSinComentario() {
            var error = errorBd("23505", "duplicate key value", null, "ux_sin_comentario");

            assertThat(escritura(error).codigo()).isEqualTo("DUPLICADO");
            assertThat(escritura(error).estado()).isEqualTo(HttpStatus.CONFLICT);
        }

        @Test
        @DisplayName("23P01 sin comentario sigue siendo VAL-004")
        void exclusionSinComentario() {
            var error = errorBd("23P01", "conflicting key value", null, "ex_otra");

            assertThat(escritura(error).codigo()).isEqualTo("VAL-004");
        }

        @Test
        @DisplayName("23503 (llave foránea): 422 REFERENCIA_INVALIDA")
        void llaveForanea() {
            assertThat(escritura(errorBd("23503", "violates foreign key", null, "fk_x")))
                    .extracting(ErrorTraducido::estado, ErrorTraducido::codigo)
                    .containsExactly(HttpStatus.UNPROCESSABLE_CONTENT, "REFERENCIA_INVALIDA");
        }

        @Test
        @DisplayName("23514 (CHECK): 400 VALIDACION")
        void check() {
            assertThat(escritura(errorBd("23514", "violates check constraint", null, "ck_x")))
                    .extracting(ErrorTraducido::estado, ErrorTraducido::codigo)
                    .containsExactly(HttpStatus.BAD_REQUEST, "VALIDACION");
        }

        @Test
        @DisplayName("VAL-015: 42501 en una escritura responde 403")
        void privilegioEnEscritura() {
            assertThat(escritura(errorBd("42501", "permission denied", null, null)))
                    .extracting(ErrorTraducido::estado, ErrorTraducido::codigo)
                    .containsExactly(HttpStatus.FORBIDDEN, "VAL-015");
        }
    }

    @Nested
    @DisplayName("Concurrencia e infraestructura")
    class Infraestructura {

        @Test
        @DisplayName("40001 y 40P01: 409 CONCURRENCIA")
        void concurrencia() {
            assertThat(escritura(errorBd("40001", "could not serialize access", null, null)).codigo())
                    .isEqualTo("CONCURRENCIA");
            assertThat(escritura(errorBd("40P01", "deadlock detected", null, null)).codigo())
                    .isEqualTo("CONCURRENCIA");
        }

        @Test
        @DisplayName("Conexión caída (08xxx) o sin conexión del pool: 503 SERVICIO_NO_DISPONIBLE")
        void baseNoDisponible() {
            assertThat(escritura(errorBd("08006", "connection failure", null, null)).estado())
                    .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
            assertThat(escritura(new CannotGetJdbcConnectionException("sin conexión")).codigo())
                    .isEqualTo("SERVICIO_NO_DISPONIBLE");
        }

        @Test
        @DisplayName("Cualquier otro error: 500 ERROR_INTERNO")
        void errorInesperado() {
            assertThat(escritura(new IllegalStateException("fallo")).esInterno()).isTrue();
            assertThat(escritura(errorBd("42P01", "relation does not exist", null, null)).esInterno()).isTrue();
        }
    }
}
