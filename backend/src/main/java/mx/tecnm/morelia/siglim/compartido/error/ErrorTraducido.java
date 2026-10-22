package mx.tecnm.morelia.siglim.compartido.error;

import org.springframework.http.HttpStatus;

/**
 * Resultado de traducir un error a la respuesta RFC 9457.
 *
 * @param estado  estado HTTP
 * @param codigo  código del ERS o técnico (convenciones de API §3.1)
 * @param detalle mensaje en español para la persona
 */
public record ErrorTraducido(HttpStatus estado, String codigo, String detalle) {

    static ErrorTraducido interno() {
        return new ErrorTraducido(HttpStatus.INTERNAL_SERVER_ERROR, ErroresTecnicos.ERROR_INTERNO,
                ErroresTecnicos.DETALLE_INTERNO);
    }

    /** Si es un error inesperado: se registra completo en la bitácora con un identificador. */
    public boolean esInterno() {
        return estado.is5xxServerError() && !ErroresTecnicos.SERVICIO_NO_DISPONIBLE.equals(codigo);
    }
}
