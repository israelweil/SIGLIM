package mx.tecnm.morelia.siglim.compartido.config;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Validación de la configuración propia: una variable faltante o mal escrita debe impedir que la
 * aplicación arranque, con un mensaje que nombre la variable (RNF-019).
 *
 * <p>Prueba unitaria sin Spring: usa el validador de Jakarta directamente.
 */
class SiglimPropiedadesTest {

    private static ValidatorFactory fabrica;
    private static Validator validador;

    @BeforeAll
    static void crearValidador() {
        fabrica = Validation.buildDefaultValidatorFactory();
        validador = fabrica.getValidator();
    }

    @AfterAll
    static void cerrarValidador() {
        fabrica.close();
    }

    private static SiglimPropiedades propiedades(String urlSupabase, List<String> origenes) {
        return new SiglimPropiedades(
                new SiglimPropiedades.Supabase(urlSupabase),
                new SiglimPropiedades.Cors(origenes));
    }

    private static Set<String> mensajes(SiglimPropiedades propiedades) {
        return validador.validate(propiedades).stream()
                .map(ConstraintViolation::getMessage)
                .collect(Collectors.toSet());
    }

    @Test
    @DisplayName("RNF-019: acepta una configuración completa")
    void aceptaConfiguracionCompleta() {
        var valida = propiedades("https://abcd.supabase.co", List.of("http://localhost:5173"));

        assertThat(mensajes(valida)).isEmpty();
    }

    @Test
    @DisplayName("RNF-019: rechaza SUPABASE_URL vacía y lo dice")
    void rechazaUrlSupabaseVacia() {
        var sinUrl = propiedades("", List.of("http://localhost:5173"));

        assertThat(mensajes(sinUrl)).contains("Define SUPABASE_URL en backend/.env");
    }

    @Test
    @DisplayName("ADR-0003: rechaza SUPABASE_URL con diagonal final (rompería la ruta del JWKS)")
    void rechazaUrlSupabaseConDiagonalFinal() {
        var conDiagonal = propiedades("https://abcd.supabase.co/", List.of("http://localhost:5173"));

        assertThat(mensajes(conDiagonal))
                .contains("SUPABASE_URL debe ser https://<ref>.supabase.co, sin diagonal final");
    }

    @Test
    @DisplayName("Convenciones de API §5: rechaza SIGLIM_CORS_ORIGEN vacío")
    void rechazaCorsSinOrigenes() {
        var sinOrigenes = propiedades("https://abcd.supabase.co", List.of());

        assertThat(mensajes(sinOrigenes)).contains("Define SIGLIM_CORS_ORIGEN en backend/.env");
    }

    @Test
    @DisplayName("Convenciones de API §5: CORS no admite comodín ni orígenes con ruta")
    void rechazaOrigenComodinOConRuta() {
        var comodin = propiedades("https://abcd.supabase.co", List.of("*"));
        var conRuta = propiedades("https://abcd.supabase.co", List.of("http://localhost:5173/app"));

        assertThat(mensajes(comodin)).hasSize(1);
        assertThat(mensajes(conRuta)).hasSize(1);
    }
}
