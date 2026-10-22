package mx.tecnm.morelia.siglim.compartido.error;

import java.sql.SQLException;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.postgresql.util.PSQLException;
import org.postgresql.util.ServerErrorMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.util.StringUtils;

/**
 * Traduce un error de PostgreSQL a {@code (estado HTTP, codigo, detail)} según las convenciones de
 * API §3.2. Los triggers y restricciones son la <b>última garantía</b>: el servicio valida antes y
 * explica mejor; si aun así la base rechaza la operación, esta clase decide la respuesta.
 *
 * <p>Se decide por el <b>SQLSTATE</b>, nunca por el texto del mensaje: el texto cambia con el
 * idioma del servidor y entre versiones; el SQLSTATE es parte del estándar SQL.
 *
 * <table>
 *   <caption>Traducción (convenciones de API §3.2)</caption>
 *   <tr><th>SQLSTATE</th><th>Respuesta</th></tr>
 *   <tr><td>P0001</td><td>{@code codigo} = HINT, {@code detail} = MESSAGE sin el prefijo del código, estado según {@link TablaCodigosHttp}</td></tr>
 *   <tr><td>23P01</td><td>409; código del comentario de la restricción o {@code VAL-004}</td></tr>
 *   <tr><td>23505</td><td>409; código del comentario de la restricción o del índice, o {@code DUPLICADO}</td></tr>
 *   <tr><td>23503</td><td>422 {@code REFERENCIA_INVALIDA}</td></tr>
 *   <tr><td>23514</td><td>400 {@code VALIDACION}</td></tr>
 *   <tr><td>42501</td><td>lectura: 404 {@code NO_ENCONTRADO} (VAL-024); escritura: 403 {@code VAL-015}</td></tr>
 *   <tr><td>40001, 40P01</td><td>409 {@code CONCURRENCIA}</td></tr>
 *   <tr><td>08xxx, 53300, 57P0x</td><td>503 {@code SERVICIO_NO_DISPONIBLE}</td></tr>
 *   <tr><td>otro</td><td>500 {@code ERROR_INTERNO}</td></tr>
 * </table>
 *
 * <p>Refs: T-02.4, VAL-004, VAL-015, VAL-024, convenciones de API §3.2
 */
@Component
public class TraductorErroresBd {

    private static final Logger log = LoggerFactory.getLogger(TraductorErroresBd.class);

    /** «VAL-004: la cancha ya está ocupada…» en el comentario de una restricción. */
    private static final Pattern CODIGO_EN_COMENTARIO =
            Pattern.compile("^\\s*((?:VAL|RF|RNF|RN)-\\d{3})\\s*:\\s*(.+)$", Pattern.DOTALL);

    private static final String DETALLE_CANCHA_OCUPADA = "La cancha ya está ocupada en ese horario.";

    /** Conexión rechazada, demasiadas conexiones o servidor apagándose. */
    private static final Set<String> NO_DISPONIBLE = Set.of("53300", "57P01", "57P02", "57P03");

    private final DescripcionRestricciones restricciones;

    public TraductorErroresBd(DescripcionRestricciones restricciones) {
        this.restricciones = restricciones;
    }

    /**
     * @param error   la excepción que llegó al controlador (normalmente una
     *                {@code DataAccessException} con la {@link SQLException} como causa)
     * @param lectura si la petición solo leía datos (GET o HEAD); decide la respuesta de 42501
     */
    public ErrorTraducido traducir(Throwable error, boolean lectura) {
        Optional<SQLException> causa = causaSql(error);
        String sqlState = causa.map(SQLException::getSQLState).orElse(null);
        if (sqlState == null) {
            return sinSqlState(error);
        }
        ServerErrorMessage servidor = causa
                .filter(PSQLException.class::isInstance)
                .map(e -> ((PSQLException) e).getServerErrorMessage())
                .orElse(null);

        return switch (sqlState) {
            case "P0001" -> errorDeNegocio(servidor);
            case "23P01" -> desdeComentario(servidor, "VAL-004", DETALLE_CANCHA_OCUPADA);
            case "23505" -> desdeComentario(servidor, ErroresTecnicos.DUPLICADO, ErroresTecnicos.DETALLE_DUPLICADO);
            case "23503" -> new ErrorTraducido(HttpStatus.UNPROCESSABLE_CONTENT,
                    ErroresTecnicos.REFERENCIA_INVALIDA, ErroresTecnicos.DETALLE_REFERENCIA);
            case "23514" -> new ErrorTraducido(HttpStatus.BAD_REQUEST,
                    ErroresTecnicos.VALIDACION, ErroresTecnicos.DETALLE_REGLA);
            case "42501" -> lectura
                    ? new ErrorTraducido(HttpStatus.NOT_FOUND, ErroresTecnicos.NO_ENCONTRADO,
                            ErroresTecnicos.DETALLE_NO_ENCONTRADO)
                    : new ErrorTraducido(HttpStatus.FORBIDDEN, ErroresTecnicos.SIN_PERMISO,
                            ErroresTecnicos.DETALLE_SIN_PERMISO);
            case "40001", "40P01" -> new ErrorTraducido(HttpStatus.CONFLICT,
                    ErroresTecnicos.CONCURRENCIA, ErroresTecnicos.DETALLE_CONCURRENCIA);
            default -> sqlState.startsWith("08") || NO_DISPONIBLE.contains(sqlState)
                    ? noDisponible()
                    : ErrorTraducido.interno();
        };
    }

    /** {@code siglim.error_negocio(codigo, mensaje)}: el código viaja en HINT. */
    private ErrorTraducido errorDeNegocio(ServerErrorMessage servidor) {
        String codigo = servidor == null ? null : servidor.getHint();
        if (!StringUtils.hasText(codigo)) {
            // Un RAISE sin código no es una regla del ERS: es un error de programación.
            return ErrorTraducido.interno();
        }
        String detalle = sinPrefijo(servidor.getMessage(), codigo);
        HttpStatus estado = TablaCodigosHttp.estadoDe(codigo).orElseGet(() -> {
            log.warn("Código {} de la base de datos sin mapeo en TablaCodigosHttp; se responde 409. "
                    + "Agrégalo a la tabla y a convenciones de API §3.2.", codigo);
            return HttpStatus.CONFLICT;
        });
        return new ErrorTraducido(estado, codigo, detalle);
    }

    /** 23505 y 23P01: el código sale del comentario de la restricción, si lo documenta. */
    private ErrorTraducido desdeComentario(ServerErrorMessage servidor, String codigoPorOmision,
            String detallePorOmision) {
        String restriccion = servidor == null ? null : servidor.getConstraint();
        if (StringUtils.hasText(restriccion)) {
            Optional<Matcher> documentado = restricciones.comentario(restriccion)
                    .map(CODIGO_EN_COMENTARIO::matcher)
                    .filter(Matcher::matches);
            if (documentado.isPresent()) {
                Matcher m = documentado.get();
                return new ErrorTraducido(HttpStatus.CONFLICT, m.group(1), conMayuscula(m.group(2).strip()));
            }
        }
        return new ErrorTraducido(HttpStatus.CONFLICT, codigoPorOmision, detallePorOmision);
    }

    /** Sin SQLSTATE: falla de conexión o de infraestructura, o un error de programación. */
    private static ErrorTraducido sinSqlState(Throwable error) {
        return error instanceof DataAccessResourceFailureException
                || error instanceof CannotCreateTransactionException
                ? noDisponible()
                : ErrorTraducido.interno();
    }

    private static ErrorTraducido noDisponible() {
        return new ErrorTraducido(HttpStatus.SERVICE_UNAVAILABLE,
                ErroresTecnicos.SERVICIO_NO_DISPONIBLE, ErroresTecnicos.DETALLE_NO_DISPONIBLE);
    }

    /** La primera {@link SQLException} con SQLSTATE en la cadena de causas. */
    static Optional<SQLException> causaSql(Throwable error) {
        for (Throwable actual = error; actual != null; actual = actual.getCause()) {
            if (actual instanceof SQLException sql && sql.getSQLState() != null) {
                return Optional.of(sql);
            }
            if (actual.getCause() == actual) {
                break;
            }
        }
        return Optional.empty();
    }

    /** {@code error_negocio} arma MESSAGE como «VAL-003: texto»; la persona solo debe ver el texto. */
    static String sinPrefijo(String mensaje, String codigo) {
        if (!StringUtils.hasText(mensaje)) {
            return ErroresTecnicos.DETALLE_REGLA;
        }
        String prefijo = codigo + ":";
        return mensaje.startsWith(prefijo) ? mensaje.substring(prefijo.length()).strip() : mensaje.strip();
    }

    private static String conMayuscula(String texto) {
        return texto.isEmpty() ? texto : texto.substring(0, 1).toUpperCase(Locale.ROOT) + texto.substring(1);
    }
}
