package mx.tecnm.morelia.siglim.compartido.salud;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

/** Prueba de controlador de {@code GET /api/v1/salud} (convenciones de API §5). */
@WebMvcTest(controllers = SaludController.class, properties = {
        "SUPABASE_URL=https://proyecto-prueba.supabase.co",
        "SIGLIM_CORS_ORIGEN=http://localhost:5173"
})
class SaludControllerTest {

    @Autowired
    private MockMvcTester mvc;

    @Test
    @DisplayName("T-02: GET /api/v1/salud responde 200 con estado OK")
    void respondeQueLaApiEstaEnEjecucion() {
        assertThat(mvc.get().uri("/api/v1/salud"))
                .hasStatusOk()
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_JSON)
                .bodyJson()
                .extractingPath("$.estado").isEqualTo("OK");
    }
}
