package mx.tecnm.morelia.siglim;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Punto de entrada del backend de SIGLIM.
 *
 * <p>Monolito modular: un paquete por módulo del ERS bajo {@code mx.tecnm.morelia.siglim}, con
 * las dependencias en un solo sentido según los niveles de ADR-0006 (ADR-0002, ADR-0006).
 * {@link ConfigurationPropertiesScan} registra los {@code record} de configuración con prefijo
 * {@code siglim}, que se validan al arrancar.
 *
 * <p>Refs: T-02.1, RNF-019
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class SiglimApplication {

    public static void main(String[] args) {
        SpringApplication.run(SiglimApplication.class, args);
    }
}
