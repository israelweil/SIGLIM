package mx.tecnm.morelia.siglim.compartido.error;

import java.io.Serial;

/**
 * El recurso no existe <b>o</b> está fuera del ámbito del usuario: ambos casos responden
 * {@code 404 NO_ENCONTRADO} con el mismo mensaje, para no revelar cuál de los dos es (VAL-024).
 *
 * <p>El texto que recibe el constructor solo va a la bitácora, nunca a la respuesta.
 *
 * <p>Refs: T-02.4, VAL-024, convenciones de API §3.1
 */
public final class RecursoNoEncontradoException extends RuntimeException {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * @param descripcion qué se buscó, para la bitácora (por ejemplo {@code "temporada 3f2a…"});
     *                    sin datos personales
     */
    public RecursoNoEncontradoException(String descripcion) {
        super(descripcion);
    }
}
