package mx.tecnm.morelia.siglim.compartido.contexto;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.util.StringUtils;

/**
 * Fija el motivo de la operación en curso ({@code siglim.motivo}) para que los triggers lo guarden
 * en el historial y exijan motivo en las transiciones de estado (RN-021, RF-045).
 *
 * <p>Uso, dentro de un método {@code @Transactional} del servicio y antes del cambio de estado:
 * <pre>{@code
 * motivoOperacion.fijar(peticion.motivo());
 * repositorio.cambiarEstado(partidoId, EstadoPartido.SUSPENDIDO);
 * }</pre>
 *
 * <p>Refs: T-02.3, RN-021, ADR-0014
 */
@Component
public class MotivoOperacion {

    private final JdbcClient jdbc;

    public MotivoOperacion(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * @param motivo texto que escribió la persona; se valida su longitud en el DTO de la petición
     * @throws IllegalStateException si no hay una transacción activa (el motivo se perdería)
     */
    public void fijar(String motivo) {
        if (!TransactionSynchronizationManager.isActualTransactionActive()) {
            throw new IllegalStateException("El motivo se fija dentro de la transacción del servicio.");
        }
        if (!StringUtils.hasText(motivo)) {
            throw new IllegalArgumentException("El motivo no puede estar vacío.");
        }
        jdbc.sql("SELECT set_config('siglim.motivo', :motivo, true)")
                .param("motivo", motivo.strip())
                .query(String.class)
                .single();
    }
}
