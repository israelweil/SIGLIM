package mx.tecnm.morelia.siglim.compartido.contexto;

import java.util.Optional;
import java.util.UUID;

/**
 * Encuentra el perfil de SIGLIM de un usuario de Supabase Auth.
 *
 * <p>Interfaz definida por quien la necesita ({@code compartido}, nivel 0) e implementada por el
 * módulo {@code seguridad} (nivel 1), dueño de la tabla {@code perfiles}: así {@code compartido}
 * no depende de un módulo superior (ADR-0006, inversión de dependencias).
 */
public interface ResolutorPerfil {

    /** Datos mínimos del perfil para abrir la sesión. */
    record PerfilSesion(UUID id, boolean activo) {
    }

    /**
     * @param usuarioAuthId {@code auth.users.id}, el {@code sub} del token
     * @return el perfil enlazado, activo o no; vacío si la cuenta no tiene perfil en SIGLIM
     */
    Optional<PerfilSesion> buscarPorUsuarioAuth(UUID usuarioAuthId);
}
