package mx.tecnm.morelia.siglim.compartido.error;

import java.util.Optional;

/**
 * Comentario de una restricción o índice del esquema {@code siglim}, donde la migración puede
 * documentar el código del ERS que protege ({@code COMMENT ON CONSTRAINT … IS 'VAL-004: …'}).
 *
 * <p>Convenciones de API §3.2: para {@code 23505} (unicidad) y {@code 23P01} (exclusión), el código
 * de la respuesta sale de ese comentario.
 */
public interface DescripcionRestricciones {

    /**
     * @param nombre nombre de la restricción o del índice que reporta PostgreSQL
     * @return su comentario, si tiene
     */
    Optional<String> comentario(String nombre);
}
