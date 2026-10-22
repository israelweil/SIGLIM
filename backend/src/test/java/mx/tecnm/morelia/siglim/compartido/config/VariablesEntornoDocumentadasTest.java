package mx.tecnm.morelia.siglim.compartido.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Criterio de terminado de T-02.1: {@code backend/.env.example} documenta cada variable que usa
 * {@code application.yml}, y no documenta variables que ya nadie usa.
 *
 * <p>Maven ejecuta las pruebas con {@code backend/} como directorio de trabajo.
 */
class VariablesEntornoDocumentadasTest {

    /** {@code ${NOMBRE}} o {@code ${NOMBRE:valor}}: solo nombres en MAYÚSCULAS (variables de entorno). */
    private static final Pattern MARCADOR = Pattern.compile("\\$\\{([A-Z][A-Z0-9_]*)(?::[^}]*)?}");

    /** {@code NOMBRE=valor} al inicio de una línea que no es comentario. */
    private static final Pattern DECLARACION = Pattern.compile("(?m)^([A-Z][A-Z0-9_]*)=");

    private static Set<String> coincidencias(Pattern patron, String texto) {
        Set<String> nombres = new TreeSet<>();
        Matcher m = patron.matcher(texto);
        while (m.find()) {
            nombres.add(m.group(1));
        }
        return nombres;
    }

    private static String applicationYml() throws IOException {
        try (InputStream entrada = VariablesEntornoDocumentadasTest.class.getResourceAsStream("/application.yml")) {
            assertThat(entrada).as("application.yml en el classpath").isNotNull();
            return new String(entrada.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @Test
    @DisplayName("T-02.1: .env.example documenta exactamente las variables que usa application.yml")
    void envExampleDocumentaLasVariablesDeApplicationYml() throws IOException {
        Set<String> usadas = coincidencias(MARCADOR, applicationYml());
        Set<String> documentadas = coincidencias(DECLARACION,
                Files.readString(Path.of(".env.example"), StandardCharsets.UTF_8));

        assertThat(usadas).as("variables usadas en application.yml").isNotEmpty();
        assertThat(documentadas)
                .as("variables de .env.example (agrega las nuevas y quita las que ya no se usan)")
                .isEqualTo(usadas);
    }
}
