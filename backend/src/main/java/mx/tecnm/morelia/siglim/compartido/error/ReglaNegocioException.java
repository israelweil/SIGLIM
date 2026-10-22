package mx.tecnm.morelia.siglim.compartido.error;

import java.io.Serial;
import org.springframework.http.HttpStatus;

/**
 * Una operación incumple una regla de negocio del ERS. El servicio la lanza al validar
 * <b>antes</b> de escribir, con un mensaje que explica la causa a la persona; el
 * {@link ManejadorGlobalErrores} la convierte en RFC 9457 con su {@code codigo}.
 *
 * <pre>{@code
 * throw ReglaNegocioException.conflicto("VAL-004",
 *         "La cancha «Unidad Deportiva Morelos 2» ya tiene el partido Halcones vs. Toros de 10:00 a 11:45.");
 * }</pre>
 *
 * <p>El estado HTTP sigue las convenciones de API §3.1: el método de fábrica dice el tipo de regla.
 *
 * <p>Refs: T-02.4, convenciones de API §3
 */
public final class ReglaNegocioException extends RuntimeException {

    @Serial
    private static final long serialVersionUID = 1L;

    private final HttpStatus estado;
    private final String codigo;

    private ReglaNegocioException(HttpStatus estado, String codigo, String mensaje) {
        super(mensaje);
        this.estado = estado;
        this.codigo = codigo;
    }

    /** 400: falta un dato obligatorio para la regla, como el motivo (RN-021). */
    public static ReglaNegocioException invalida(String codigo, String mensaje) {
        return new ReglaNegocioException(HttpStatus.BAD_REQUEST, codigo, mensaje);
    }

    /** 403: la persona no puede hacer la acción aunque tenga el permiso (VAL-021, VAL-022). */
    public static ReglaNegocioException prohibida(String codigo, String mensaje) {
        return new ReglaNegocioException(HttpStatus.FORBIDDEN, codigo, mensaje);
    }

    /** 409: choca con el estado actual de otros datos (programación, unicidad, transición). */
    public static ReglaNegocioException conflicto(String codigo, String mensaje) {
        return new ReglaNegocioException(HttpStatus.CONFLICT, codigo, mensaje);
    }

    /** 422: la petición está bien formada pero su contenido incumple una regla (elegibilidad). */
    public static ReglaNegocioException noProcesable(String codigo, String mensaje) {
        return new ReglaNegocioException(HttpStatus.UNPROCESSABLE_CONTENT, codigo, mensaje);
    }

    public HttpStatus estado() {
        return estado;
    }

    /** Código del ERS incumplido: {@code VAL-xxx}, {@code RF-xxx} o {@code RN-xxx}. */
    public String codigo() {
        return codigo;
    }
}
