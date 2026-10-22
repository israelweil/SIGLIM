package mx.tecnm.morelia.siglim.compartido.config;

import javax.sql.DataSource;
import mx.tecnm.morelia.siglim.compartido.contexto.GestorTransaccionesSiglim;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

/**
 * Reemplaza el administrador de transacciones de Spring Boot por {@link GestorTransaccionesSiglim},
 * que fija el contexto de usuario y el rol de base de datos en cada {@code @Transactional}
 * (ADR-0005, ADR-0014). Spring Boot deja de crear el suyo al existir este bean.
 *
 * <p>Refs: T-02.3
 */
@Configuration(proxyBeanMethods = false)
public class TransaccionesConfig {

    @Bean
    PlatformTransactionManager transactionManager(DataSource fuenteDatos) {
        return new GestorTransaccionesSiglim(fuenteDatos);
    }
}
