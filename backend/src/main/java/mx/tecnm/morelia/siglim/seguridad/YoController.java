package mx.tecnm.morelia.siglim.seguridad;

import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code GET /api/v1/yo}: perfil, asignaciones con ámbito y permisos efectivos del usuario actual
 * (convenciones de API §5 y §6.1). Exige sesión; responde con {@code Cache-Control: no-store}
 * porque contiene datos personales.
 *
 * <p>Refs: H-01.1, RF-094, ADR-0007
 */
@RestController
@RequestMapping("/api/v1/yo")
class YoController {

    private final YoService servicio;

    YoController(YoService servicio) {
        this.servicio = servicio;
    }

    @GetMapping
    ResponseEntity<YoDto> consultar() {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(servicio.consultar());
    }
}
