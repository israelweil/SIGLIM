package mx.tecnm.morelia.siglim.compartido.config;

import java.util.UUID;
import mx.tecnm.morelia.siglim.compartido.contexto.UsuarioActual;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Rutas que existen solo en las pruebas para ejercitar la cadena de seguridad: una protegida y una
 * del portal público. No forman parte de la API.
 */
@RestController
class RecursosPruebaController {

    record Sujeto(String sub, UUID perfilId) {
    }

    record Mensaje(String mensaje) {
    }

    @GetMapping("/api/v1/prueba/protegido")
    Sujeto protegido(@AuthenticationPrincipal Jwt token) {
        return new Sujeto(token.getSubject(), UsuarioActual.idRequerido());
    }

    @GetMapping("/api/v1/publico/prueba")
    Mensaje publicoLectura() {
        return new Mensaje("público");
    }

    @PostMapping("/api/v1/publico/prueba")
    Mensaje publicoEscritura() {
        return new Mensaje("no debería llegar aquí sin sesión");
    }
}
