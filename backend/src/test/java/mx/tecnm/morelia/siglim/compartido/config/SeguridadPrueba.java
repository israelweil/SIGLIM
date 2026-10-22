package mx.tecnm.morelia.siglim.compartido.config;

import com.nimbusds.jose.jwk.Curve;
import com.nimbusds.jose.jwk.ECKey;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.proc.SecurityContext;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.ECPrivateKey;
import java.security.interfaces.ECPublicKey;
import java.security.spec.ECGenParameterSpec;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.function.Consumer;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

/**
 * Configuración de seguridad para pruebas de controlador ({@code @WebMvcTest}).
 *
 * <p>Usa la misma cadena de seguridad y las mismas reglas de validación del token que producción
 * ({@link DecodificadorJwtConfig#validador}); solo cambia de dónde salen las llaves públicas: en
 * lugar del JWKS de Supabase, una llave EC P-256 (ES256, el algoritmo del proyecto) generada al
 * vuelo. Así las pruebas firman tokens reales sin red ni secretos.
 *
 * <p>Uso: {@code @Import(SeguridadPrueba.class)} y, en {@code @WebMvcTest(properties = …)},
 * {@code SUPABASE_URL=} {@link #URL_SUPABASE} y {@code SIGLIM_CORS_ORIGEN=} {@link #ORIGEN_FRONTEND}.
 */
@TestConfiguration(proxyBeanMethods = false)
@Import({SeguridadConfig.class, PuntoEntradaNoAutenticado.class})
public class SeguridadPrueba {

    public static final String URL_SUPABASE = "https://proyecto-prueba.supabase.co";
    public static final String ORIGEN_FRONTEND = "http://localhost:5173";

    /** Usuario de Supabase Auth de los tokens de prueba. */
    public static final String SUJETO = "6f1d2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b";

    /**
     * Identificador de llave ({@code kid}) común al JWKS y a los tokens de prueba. Debe coincidir:
     * el decodificador elige la llave del JWKS por el {@code kid} del encabezado, y si no coincide
     * rechaza todo token antes de revisar la firma o los reclamos, con lo que las pruebas de
     * rechazo pasarían por una razón equivocada.
     */
    static final String KID = "llave-prueba-es256";

    /** Llave con la que «firma Supabase» en las pruebas; su parte pública es el JWKS. */
    static final KeyPair LLAVE_PROYECTO = generarLlaveEc();

    /**
     * Llave de un atacante o de otro proyecto. Firma con el mismo {@link #KID} para que el rechazo
     * se deba a la firma y no a una llave inexistente.
     */
    static final KeyPair LLAVE_AJENA = generarLlaveEc();

    @Bean
    JwtDecoder decodificadorJwtPrueba() {
        ECKey publica = new ECKey.Builder(Curve.P_256, (ECPublicKey) LLAVE_PROYECTO.getPublic())
                .keyID(KID)
                .build();
        NimbusJwtDecoder decodificador = NimbusJwtDecoder
                .withJwkSource(new ImmutableJWKSet<SecurityContext>(new JWKSet(publica)))
                .jwsAlgorithm(SignatureAlgorithm.ES256)
                .jwsAlgorithm(SignatureAlgorithm.RS256)
                .build();
        decodificador.setJwtValidator(
                DecodificadorJwtConfig.validador(DecodificadorJwtConfig.emisor(URL_SUPABASE)));
        return decodificador;
    }

    /** Token de sesión válido, como el que emite Supabase Auth al iniciar sesión. */
    public static String tokenValido() {
        return token(LLAVE_PROYECTO, reclamos -> { });
    }

    /**
     * Firma un token ES256 con reclamos de sesión válidos y permite alterarlos para probar rechazos.
     *
     * @param llave   llave privada con la que se firma
     * @param ajustes cambios sobre los reclamos válidos (emisor, audiencia, vigencia…)
     */
    public static String token(KeyPair llave, Consumer<JwtClaimsSet.Builder> ajustes) {
        Instant ahora = Instant.now();
        JwtClaimsSet.Builder reclamos = JwtClaimsSet.builder()
                .issuer(DecodificadorJwtConfig.emisor(URL_SUPABASE))
                .audience(List.of(DecodificadorJwtConfig.AUDIENCIA))
                .subject(SUJETO)
                .claim("role", "authenticated")
                .issuedAt(ahora)
                .expiresAt(ahora.plus(Duration.ofHours(1)));
        ajustes.accept(reclamos);

        NimbusJwtEncoder codificador = NimbusJwtEncoder
                .withKeyPair((ECPublicKey) llave.getPublic(), (ECPrivateKey) llave.getPrivate())
                .jwkPostProcessor(jwk -> jwk.keyID(KID))
                .build();
        return codificador
                .encode(JwtEncoderParameters.from(JwsHeader.with(SignatureAlgorithm.ES256).build(), reclamos.build()))
                .getTokenValue();
    }

    private static KeyPair generarLlaveEc() {
        try {
            KeyPairGenerator generador = KeyPairGenerator.getInstance("EC");
            generador.initialize(new ECGenParameterSpec("secp256r1"));
            return generador.generateKeyPair();
        } catch (java.security.GeneralSecurityException e) {
            throw new IllegalStateException("No se pudo generar la llave EC de prueba", e);
        }
    }
}
