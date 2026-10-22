package mx.tecnm.morelia.siglim.compartido.error;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

import java.util.UUID;
import mx.tecnm.morelia.siglim.BaseDatosPrueba;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Traducción de errores <b>reales</b> de PostgreSQL, producidos por los triggers y restricciones
 * del esquema del repositorio (convenciones de API §3.2). Complementa a
 * {@code TraductorErroresBdTest}: aquí el formato del error, el HINT, el nombre de la restricción y
 * su comentario vienen del servidor y del catálogo, no de un mensaje construido a mano.
 */
class TraduccionErroresBdIT extends BaseDatosPrueba {

    private static boolean tablaDePruebaCreada;

    @Autowired
    private PlatformTransactionManager transacciones;

    @Autowired
    private TraductorErroresBd traductor;

    /**
     * Tabla solo de prueba con un índice único sin comentario, otro con el código documentado en su
     * comentario y una restricción de exclusión, para producir 23505 y 23P01 sin armar una temporada.
     */
    @BeforeEach
    void crearTablaDePrueba() {
        if (!tablaDePruebaCreada) {
            psql("-c", """
                    CREATE TABLE siglim.prueba_errores (sin_codigo text, con_codigo text, rango int4range);
                    CREATE UNIQUE INDEX ux_prueba_sin_comentario ON siglim.prueba_errores (sin_codigo);
                    CREATE UNIQUE INDEX ux_prueba_con_codigo ON siglim.prueba_errores (con_codigo);
                    COMMENT ON INDEX siglim.ux_prueba_con_codigo
                      IS 'VAL-006: la CURP ya tiene un registro activo en la temporada.';
                    ALTER TABLE siglim.prueba_errores
                      ADD CONSTRAINT ex_prueba_rango EXCLUDE USING gist (rango WITH &&);
                    """);
            tablaDePruebaCreada = true;
        }
    }

    /** Ejecuta la operación en una transacción con el contexto real y devuelve el error traducido. */
    private ErrorTraducido traducirTransaccion(boolean lectura, Runnable operacion) {
        Throwable error = catchThrowable(() ->
                new TransactionTemplate(transacciones).executeWithoutResult(estado -> operacion.run()));
        assertThat(error).as("la base de datos debía rechazar la operación").isNotNull();
        return traductor.traducir(error, lectura);
    }

    /** La tabla de prueba es del dueño del esquema: se escribe sin transacción de la aplicación. */
    private ErrorTraducido traducirComoDueno(String sql) {
        Throwable error = catchThrowable(() -> jdbc.sql(sql).update());
        assertThat(error).as("la base de datos debía rechazar la operación").isNotNull();
        return traductor.traducir(error, false);
    }

    @Test
    @DisplayName("P0001 real: el código sale de HINT y el detail es el mensaje del trigger sin prefijo")
    void errorDeNegocioDeUnTrigger() {
        UUID perfil = iniciarSesionComoAdministrador();

        ErrorTraducido traducido = traducirTransaccion(false, () -> {
            UUID comunicado = crearComunicado(perfil);
            enviarARevision(comunicado);
            devolverABorrador(comunicado); // sin motivo: el trigger lanza RF-121
        });

        assertThat(traducido).isEqualTo(new ErrorTraducido(
                HttpStatus.CONFLICT, "RF-121", "La devolución requiere observaciones."));
    }

    @Test
    @DisplayName("VAL-024: 42501 real en una lectura responde 404")
    void privilegioEnLectura() {
        // Sin sesión la transacción es siglim_publico, que no puede leer tablas.
        ErrorTraducido traducido = traducirTransaccion(true, () ->
                jdbc.sql("SELECT count(*) FROM perfiles").query(Long.class).single());

        assertThat(traducido.estado()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(traducido.codigo()).isEqualTo("NO_ENCONTRADO");
    }

    @Test
    @DisplayName("VAL-015: 42501 real en una escritura responde 403")
    void privilegioEnEscritura() {
        ErrorTraducido traducido = traducirTransaccion(false, () -> crearComunicado(UUID.randomUUID()));

        assertThat(traducido.estado()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(traducido.codigo()).isEqualTo("VAL-015");
    }

    @Test
    @DisplayName("23505 real sin comentario en el índice: 409 DUPLICADO")
    void unicidadSinComentario() {
        jdbc.sql("INSERT INTO siglim.prueba_errores (sin_codigo) VALUES ('repetido-a')").update();

        ErrorTraducido traducido = traducirComoDueno(
                "INSERT INTO siglim.prueba_errores (sin_codigo) VALUES ('repetido-a')");

        assertThat(traducido.estado()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(traducido.codigo()).isEqualTo("DUPLICADO");
    }

    @Test
    @DisplayName("23505 real: el código y el mensaje salen del comentario del índice en el catálogo")
    void unicidadDocumentada() {
        jdbc.sql("INSERT INTO siglim.prueba_errores (con_codigo) VALUES ('repetido-b')").update();

        ErrorTraducido traducido = traducirComoDueno(
                "INSERT INTO siglim.prueba_errores (con_codigo) VALUES ('repetido-b')");

        assertThat(traducido).isEqualTo(new ErrorTraducido(
                HttpStatus.CONFLICT, "VAL-006", "La CURP ya tiene un registro activo en la temporada."));
    }

    @Test
    @DisplayName("VAL-004: 23P01 real (exclusión) responde 409 VAL-004")
    void exclusion() {
        jdbc.sql("INSERT INTO siglim.prueba_errores (rango) VALUES ('[1,10)')").update();

        ErrorTraducido traducido = traducirComoDueno(
                "INSERT INTO siglim.prueba_errores (rango) VALUES ('[5,15)')");

        assertThat(traducido.estado()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(traducido.codigo()).isEqualTo("VAL-004");
    }

    @Test
    @DisplayName("23503 real (llave foránea): 422 REFERENCIA_INVALIDA")
    void llaveForanea() {
        iniciarSesionComoAdministrador();

        ErrorTraducido traducido = traducirTransaccion(false, () -> crearComunicado(UUID.randomUUID()));

        assertThat(traducido.estado()).isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT);
        assertThat(traducido.codigo()).isEqualTo("REFERENCIA_INVALIDA");
    }

    @Test
    @DisplayName("23514 real (CHECK ck_comunicados_dual): 400 VALIDACION")
    void check() {
        UUID perfil = iniciarSesionComoAdministrador();

        ErrorTraducido traducido = traducirTransaccion(false, () -> jdbc.sql("""
                        INSERT INTO comunicados (liga_id, titulo, cuerpo, redactado_por, aprobado_por)
                        SELECT id, 'Prueba', 'Cuerpo', :perfil, :perfil FROM ligas LIMIT 1
                        """).param("perfil", perfil).update());

        assertThat(traducido.estado()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(traducido.codigo()).isEqualTo("VALIDACION");
    }
}
