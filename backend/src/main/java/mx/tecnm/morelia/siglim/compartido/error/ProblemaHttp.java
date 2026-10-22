package mx.tecnm.morelia.siglim.compartido.error;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;

/**
 * Construye las respuestas de error RFC 9457 con el formato de las convenciones de API §3:
 * {@code type} estable por código, {@code title}, {@code status}, {@code detail} para la persona,
 * {@code instance} y la extensión {@code codigo}.
 *
 * <p>Lo usan los componentes que responden errores fuera de Spring MVC (filtros de seguridad,
 * T-02.2) y lo puede reutilizar el manejador global de errores (T-02.4), para que el frontend
 * reciba una sola estructura.
 */
public final class ProblemaHttp {

    /** Prefijo de {@code type}: una URI estable por código; no necesita resolver a una página. */
    private static final String PREFIJO_TIPO = "https://siglim.mx/errores/";

    private ProblemaHttp() {
    }

    /**
     * Crea un {@link ProblemDetail} con la extensión {@code codigo}.
     *
     * @param estado    código HTTP
     * @param codigo    código del ERS ({@code VAL-004}) o técnico ({@code NO_AUTENTICADO})
     * @param titulo    resumen corto del tipo de error
     * @param detalle   mensaje en español para la persona; nunca SQL, trazas ni datos de terceros
     * @param instancia ruta de la petición que falló
     */
    public static ProblemDetail crear(HttpStatus estado, String codigo, String titulo, String detalle,
            String instancia) {
        ProblemDetail problema = ProblemDetail.forStatusAndDetail(estado, detalle);
        problema.setType(URI.create(PREFIJO_TIPO + codigo.toLowerCase(Locale.ROOT).replace('_', '-')));
        problema.setTitle(titulo);
        problema.setInstance(URI.create(instancia));
        problema.setProperty("codigo", codigo);
        return problema;
    }

    /**
     * Convierte el problema en un mapa con las extensiones al mismo nivel que los campos estándar,
     * como lo exige RFC 9457, para escribirlo con Jackson fuera de Spring MVC (donde no se aplica
     * el mixin que Spring usa para {@link ProblemDetail}).
     */
    public static Map<String, Object> comoMapa(ProblemDetail problema) {
        Map<String, Object> cuerpo = new LinkedHashMap<>();
        cuerpo.put("type", problema.getType().toString());
        cuerpo.put("title", problema.getTitle());
        cuerpo.put("status", problema.getStatus());
        cuerpo.put("detail", problema.getDetail());
        if (problema.getInstance() != null) {
            cuerpo.put("instance", problema.getInstance().toString());
        }
        if (problema.getProperties() != null) {
            cuerpo.putAll(problema.getProperties());
        }
        return cuerpo;
    }
}
