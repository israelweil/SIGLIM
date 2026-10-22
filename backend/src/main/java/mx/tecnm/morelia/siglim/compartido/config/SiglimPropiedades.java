package mx.tecnm.morelia.siglim.compartido.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Configuración propia de SIGLIM (prefijo {@code siglim} en {@code application.yml}).
 *
 * <p>Cada valor viene de una variable de entorno documentada en {@code backend/.env.example}.
 * Se valida al arrancar: si falta una variable o tiene un formato incorrecto, la aplicación no
 * inicia y el mensaje dice cuál es, en lugar de fallar después con la primera petición.
 *
 * <p>Refs: T-02.1, RNF-019, ADR-0003 (Supabase Auth), convenciones de API §5 (CORS)
 *
 * @param supabase proyecto de Supabase del que se derivan el JWKS y el emisor del JWT
 * @param cors     orígenes del frontend a los que se permite llamar a la API
 */
@Validated
@ConfigurationProperties("siglim")
public record SiglimPropiedades(@Valid @NotNull Supabase supabase, @Valid @NotNull Cors cors) {

    /**
     * Datos del proyecto de Supabase.
     *
     * @param url {@code https://<ref>.supabase.co}, sin diagonal final porque a partir de ella se
     *            arman {@code /auth/v1} y {@code /auth/v1/.well-known/jwks.json} (T-02.2)
     */
    public record Supabase(
            @NotBlank(message = "Define SUPABASE_URL en backend/.env")
            @Pattern(regexp = "^https?://\\S*[^/\\s]$",
                    message = "SUPABASE_URL debe ser https://<ref>.supabase.co, sin diagonal final")
            String url) {
    }

    /**
     * Política CORS de la API (convenciones de API §5).
     *
     * @param origenes orígenes exactos del frontend, por ejemplo {@code http://localhost:5173};
     *                 en la variable de entorno se separan con comas
     */
    public record Cors(
            @NotEmpty(message = "Define SIGLIM_CORS_ORIGEN en backend/.env")
            List<@NotBlank @Pattern(regexp = "^https?://[^/\\s*]+$",
                    message = "Cada origen de SIGLIM_CORS_ORIGEN es esquema://host[:puerto], sin ruta ni comodín")
                    String> origenes) {
    }
}
