package mx.tecnm.morelia.siglim.compartido.salud;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code GET /api/v1/salud}: confirma que la API está en ejecución.
 *
 * <p>Es la única ruta fuera de {@code /api/v1/publico/**} que no exige token (convenciones de API
 * §5); T-02.2 debe dejarla abierta al configurar la seguridad. Solo responde que el proceso vive:
 * no consulta la base de datos ni revela versiones o configuración. El estado detallado de la base
 * de datos está en {@code /actuator/health} (RNF-001, RNF-011).
 *
 * <p>Refs: T-02, RNF-001
 */
@RestController
@RequestMapping("/api/v1/salud")
class SaludController {

    /** Cuerpo de la respuesta: {@code {"estado":"OK"}}. */
    record SaludDto(String estado) {
    }

    private static final SaludDto EN_EJECUCION = new SaludDto("OK");

    @GetMapping
    SaludDto consultar() {
        return EN_EJECUCION;
    }
}
