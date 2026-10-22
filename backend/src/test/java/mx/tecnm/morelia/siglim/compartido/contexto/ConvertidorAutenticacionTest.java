package mx.tecnm.morelia.siglim.compartido.contexto;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.oauth2.jwt.Jwt;

/** Resolución del perfil de SIGLIM a partir del token (ADR-0003 punto 6). Sin Spring ni BD. */
class ConvertidorAutenticacionTest {

    private static final UUID USUARIO_AUTH = UUID.fromString("6f1d2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b");
    private static final UUID PERFIL = UUID.fromString("0b7c3e1a-2d4f-4a6b-9c8d-7e6f5a4b3c2d");

    private static Jwt token(UUID sub) {
        return Jwt.withTokenValue("token-de-prueba")
                .header("alg", "ES256")
                .subject(sub.toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
    }

    private static ConvertidorAutenticacion convertidor(Optional<ResolutorPerfil.PerfilSesion> perfil) {
        return new ConvertidorAutenticacion(usuarioAuthId -> {
            assertThat(usuarioAuthId).as("busca por el sub del token").isEqualTo(USUARIO_AUTH);
            return perfil;
        });
    }

    @Test
    @DisplayName("ADR-0014: un perfil activo abre la sesión con su perfiles.id y su auth.users.id")
    void perfilActivoAbreSesion() {
        var sesion = (AutenticacionSiglim) convertidor(Optional.of(new ResolutorPerfil.PerfilSesion(PERFIL, true)))
                .convert(token(USUARIO_AUTH));

        assertThat(sesion.perfilId()).isEqualTo(PERFIL);
        assertThat(sesion.usuarioAuthId()).isEqualTo(USUARIO_AUTH);
        assertThat(sesion.isAuthenticated()).isTrue();
        assertThat(sesion.getAuthorities()).as("los permisos se consultan en la BD (ADR-0007)").isEmpty();
    }

    @Test
    @DisplayName("ADR-0003: una cuenta sin perfil en SIGLIM se rechaza")
    void sinPerfilSeRechaza() {
        assertThatThrownBy(() -> convertidor(Optional.empty()).convert(token(USUARIO_AUTH)))
                .isInstanceOf(DisabledException.class);
    }

    @Test
    @DisplayName("ADR-0003: un perfil desactivado se rechaza aunque el token siga vigente")
    void perfilDesactivadoSeRechaza() {
        var desactivado = Optional.of(new ResolutorPerfil.PerfilSesion(PERFIL, false));

        assertThatThrownBy(() -> convertidor(desactivado).convert(token(USUARIO_AUTH)))
                .isInstanceOf(DisabledException.class);
    }

    @Test
    @DisplayName("ADR-0014: los claims llevan sub y perfil_id, que lee siglim.usuario_actual()")
    void claimsDelContexto() {
        var sesion = new AutenticacionSiglim(token(USUARIO_AUTH), PERFIL);

        assertThat(GestorTransaccionesSiglim.claims(sesion)).isEqualTo(
                "{\"sub\":\"" + USUARIO_AUTH + "\",\"perfil_id\":\"" + PERFIL + "\"}");
    }
}
