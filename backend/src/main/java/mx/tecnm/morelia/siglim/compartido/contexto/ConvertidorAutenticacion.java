package mx.tecnm.morelia.siglim.compartido.contexto;

import java.util.UUID;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

/**
 * Convierte un JWT ya validado en la sesión de SIGLIM, resolviendo su perfil.
 *
 * <p>Una cuenta de Supabase Auth sin perfil en SIGLIM, o con el perfil desactivado, se rechaza
 * aunque su token siga vigente (ADR-0003 punto 6): {@link DisabledException} termina en
 * {@code 401 NO_AUTENTICADO} (decisión del equipo del 22 de octubre de 2026), para que el
 * frontend cierre la sesión.
 *
 * <p>Se consulta en cada petición, sin caché, para que desactivar una cuenta surta efecto de
 * inmediato y no al vencer el token. La consulta usa el índice único de
 * {@code perfiles.usuario_auth_id}.
 *
 * <p>Refs: T-02.3, ADR-0003, ADR-0014
 */
@Component
public class ConvertidorAutenticacion implements Converter<Jwt, AbstractAuthenticationToken> {

    private final ResolutorPerfil resolutor;

    public ConvertidorAutenticacion(ResolutorPerfil resolutor) {
        this.resolutor = resolutor;
    }

    @Override
    public AbstractAuthenticationToken convert(Jwt token) {
        // El validador del token ya garantizó que sub es un UUID (DecodificadorJwtConfig).
        UUID usuarioAuthId = UUID.fromString(token.getSubject());
        ResolutorPerfil.PerfilSesion perfil = resolutor.buscarPorUsuarioAuth(usuarioAuthId)
                .filter(ResolutorPerfil.PerfilSesion::activo)
                .orElseThrow(() -> new DisabledException("La cuenta no tiene un perfil activo en SIGLIM"));
        return new AutenticacionSiglim(token, perfil.id());
    }
}
