package mx.tecnm.morelia.siglim.compartido.contexto;

import java.util.Optional;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Acceso al usuario de la petición en curso.
 *
 * <p>Los servicios lo usan para llenar columnas como {@code creado_por} o {@code validado_por};
 * nunca reciben el perfil en el cuerpo de la petición (convenciones de API §5). Los historiales y
 * la función {@code siglim.usuario_actual()} lo obtienen solos del contexto de la transacción.
 *
 * <p>Refs: T-02.3, ADR-0005
 */
public final class UsuarioActual {

    private UsuarioActual() {
    }

    /** La sesión autenticada de la petición, si existe. */
    public static Optional<AutenticacionSiglim> autenticacion() {
        Authentication actual = SecurityContextHolder.getContext().getAuthentication();
        return actual instanceof AutenticacionSiglim sesion && sesion.isAuthenticated()
                ? Optional.of(sesion)
                : Optional.empty();
    }

    /** {@code perfiles.id} del usuario, si la petición está autenticada. */
    public static Optional<UUID> perfilId() {
        return autenticacion().map(AutenticacionSiglim::perfilId);
    }

    /**
     * {@code perfiles.id} del usuario de una petición que exige sesión.
     *
     * @throws IllegalStateException si se llama desde una ruta pública o fuera de una petición:
     *                               es un error de programación, no del usuario
     */
    public static UUID idRequerido() {
        return perfilId().orElseThrow(() -> new IllegalStateException(
                "No hay un usuario autenticado en esta petición; la ruta debe exigir token."));
    }
}
