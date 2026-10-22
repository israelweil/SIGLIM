package mx.tecnm.morelia.siglim.compartido.config;

import java.util.List;
import java.util.UUID;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtAudienceValidator;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Valida el {@code access_token} de Supabase Auth con las llaves públicas del proyecto (JWKS).
 *
 * <p>El backend nunca ve contraseñas ni guarda la llave de firma: descarga las llaves públicas de
 * {@code <SUPABASE_URL>/auth/v1/.well-known/jwks.json} en la primera petición, las conserva en
 * caché y verifica en local, sin llamar a Supabase en cada solicitud (ADR-0003).
 *
 * <p>Un token se acepta solo si cumple todo lo siguiente:
 * <ul>
 *   <li>firma válida con una llave del JWKS, con algoritmo asimétrico {@code ES256} (el del
 *       proyecto) o {@code RS256}; los tokens HS256 de la llave secreta heredada se rechazan;</li>
 *   <li>vigente: {@code exp} y {@code nbf}, con 60 s de tolerancia de reloj;</li>
 *   <li>emisor {@code <SUPABASE_URL>/auth/v1}: descarta tokens de otros proyectos y la llave
 *       pública {@code anon}, cuyo emisor es {@code supabase};</li>
 *   <li>audiencia {@code authenticated}: solo sesiones de usuario iniciadas;</li>
 *   <li>{@code sub} es un UUID: el identificador de {@code auth.users} que usa el backend.</li>
 * </ul>
 *
 * <p>Los roles y permisos no se leen del token sino de la base de datos (ADR-0003, ADR-0007).
 *
 * <p>Refs: T-02.2, RNF-003, RNF-013, ADR-0003
 */
@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(SiglimPropiedades.class)
public class DecodificadorJwtConfig {

    /** Audiencia que Supabase Auth pone en los tokens de sesión de usuario. */
    static final String AUDIENCIA = "authenticated";

    /** El emisor de los tokens del proyecto: {@code https://<ref>.supabase.co/auth/v1}. */
    static String emisor(String urlSupabase) {
        return urlSupabase + "/auth/v1";
    }

    /** Reglas de validación del token, compartidas por el decodificador real y las pruebas. */
    static OAuth2TokenValidator<Jwt> validador(String emisor) {
        return JwtValidators.createDefaultWithValidators(List.of(
                new JwtIssuerValidator(emisor),
                new JwtAudienceValidator(AUDIENCIA),
                new JwtClaimValidator<String>(JwtClaimNames.SUB, DecodificadorJwtConfig::esUuid)));
    }

    private static boolean esUuid(String valor) {
        if (valor == null) {
            return false;
        }
        try {
            UUID.fromString(valor);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    @Bean
    JwtDecoder decodificadorJwt(SiglimPropiedades propiedades) {
        String emisor = emisor(propiedades.supabase().url());
        NimbusJwtDecoder decodificador = NimbusJwtDecoder
                .withJwkSetUri(emisor + "/.well-known/jwks.json")
                .jwsAlgorithm(SignatureAlgorithm.ES256)
                .jwsAlgorithm(SignatureAlgorithm.RS256)
                .build();
        decodificador.setJwtValidator(validador(emisor));
        return decodificador;
    }
}
