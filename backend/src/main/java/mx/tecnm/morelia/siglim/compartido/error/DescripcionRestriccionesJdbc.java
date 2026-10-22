package mx.tecnm.morelia.siglim.compartido.error;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lee los comentarios de restricciones e índices del catálogo de PostgreSQL y los guarda en caché:
 * cambian solo con una migración, que reinicia la aplicación al desplegarse.
 *
 * <p>Se consulta al traducir un error, cuando la transacción que falló ya se revirtió: corre fuera
 * del contexto de usuario, pero solo lee el catálogo del esquema, sin datos de la liga. Si la base
 * no responde, devuelve vacío y el error se traduce con su código por omisión.
 */
@Repository
class DescripcionRestriccionesJdbc implements DescripcionRestricciones {

    private static final Logger log = LoggerFactory.getLogger(DescripcionRestriccionesJdbc.class);

    private final JdbcClient jdbc;
    private final Map<String, Optional<String>> cache = new ConcurrentHashMap<>();

    DescripcionRestriccionesJdbc(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<String> comentario(String nombre) {
        Optional<String> guardado = cache.get(nombre);
        if (guardado != null) {
            return guardado;
        }
        try {
            // coalesce siempre devuelve una fila; su valor es NULL si no hay comentario.
            var filas = jdbc.sql("""
                            SELECT coalesce(
                                     (SELECT obj_description(c.oid, 'pg_constraint')
                                        FROM pg_constraint c
                                        JOIN pg_namespace n ON n.oid = c.connamespace
                                       WHERE n.nspname = 'siglim' AND c.conname = :nombre
                                       LIMIT 1),
                                     (SELECT obj_description(i.oid, 'pg_class')
                                        FROM pg_class i
                                        JOIN pg_namespace n ON n.oid = i.relnamespace
                                       WHERE n.nspname = 'siglim' AND i.relname = :nombre AND i.relkind = 'i'))
                            """)
                    .param("nombre", nombre)
                    .query(String.class)
                    .list();
            Optional<String> leido = filas.isEmpty() ? Optional.empty() : Optional.ofNullable(filas.get(0));
            cache.put(nombre, leido);
            return leido;
        } catch (DataAccessException e) {
            // Sin caché: si la base vuelve, el siguiente error sí obtiene el código.
            log.warn("No se pudo leer el comentario de la restricción {}: {}", nombre, e.getMessage());
            return Optional.empty();
        }
    }
}
