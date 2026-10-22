package mx.tecnm.morelia.siglim.compartido.error;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

/**
 * Convierte en prueba la regla de convenciones de API §3.2: «un código nuevo en la base exige
 * agregarlo a esta tabla en el mismo PR». Compara {@link TablaCodigosHttp} con las migraciones y
 * con el documento, así que no pueden divergir sin que {@code mvnw verify} falle.
 *
 * <p>Maven ejecuta las pruebas con {@code backend/} como directorio de trabajo.
 */
class TablaCodigosHttpTest {

    private static final Pattern CODIGO = Pattern.compile("(?:VAL|RF|RNF|RN)-\\d{3}");
    private static final Pattern ERROR_NEGOCIO = Pattern.compile("error_negocio\\(\\s*'((?:VAL|RF|RNF|RN)-\\d{3})'");
    /** Fila de la tabla «Mapeo inicial» de §3.2: | `409` | `VAL-003`, … | Qué significan |. */
    private static final Pattern FILA_TABLA = Pattern.compile("^\\| `(\\d{3})` \\| ([^|]+) \\|");

    @Test
    @DisplayName("Convenciones §3.2: todo código que lanza una migración tiene estado HTTP")
    void todoCodigoDeLasMigracionesEstaMapeado() throws IOException {
        Set<String> lanzados = new TreeSet<>();
        try (Stream<Path> migraciones = Files.list(Path.of("..", "supabase", "migrations"))) {
            for (Path migracion : migraciones.filter(p -> p.toString().endsWith(".sql")).toList()) {
                Matcher m = ERROR_NEGOCIO.matcher(Files.readString(migracion, StandardCharsets.UTF_8));
                while (m.find()) {
                    lanzados.add(m.group(1));
                }
            }
        }

        assertThat(lanzados).as("códigos en error_negocio(...) de las migraciones").isNotEmpty();
        assertThat(TablaCodigosHttp.todos().keySet())
                .as("TablaCodigosHttp: agrega los códigos nuevos de la migración")
                .containsAll(lanzados);
    }

    @Test
    @DisplayName("Convenciones §3.2: TablaCodigosHttp es idéntica a la tabla del documento")
    void tablaIgualAlDocumento() throws IOException {
        List<String> lineas = Files.readAllLines(
                Path.of("..", "docs", "arquitectura", "convenciones-api.md"), StandardCharsets.UTF_8);
        int inicio = indiceDe(lineas, "Mapeo inicial");

        Map<String, HttpStatus> documento = new HashMap<>();
        for (String linea : lineas.subList(inicio, lineas.size())) {
            Matcher fila = FILA_TABLA.matcher(linea);
            if (!fila.find()) {
                if (!documento.isEmpty() && !linea.startsWith("|")) {
                    break; // terminó la tabla
                }
                continue;
            }
            HttpStatus estado = HttpStatus.valueOf(Integer.parseInt(fila.group(1)));
            Matcher codigos = CODIGO.matcher(fila.group(2));
            while (codigos.find()) {
                documento.put(codigos.group(), estado);
            }
        }

        assertThat(documento).as("tabla de convenciones §3.2").isNotEmpty();
        assertThat(TablaCodigosHttp.todos()).isEqualTo(documento);
    }

    private static int indiceDe(List<String> lineas, String texto) {
        for (int i = 0; i < lineas.size(); i++) {
            if (lineas.get(i).contains(texto)) {
                return i;
            }
        }
        throw new AssertionError("No se encontró «" + texto + "» en convenciones-api.md");
    }
}
