package mx.tecnm.morelia.siglim.canchas;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

/** Cuerpo de {@code POST /api/v1/canchas/{id}/disponibilidad} (RF-029, RF-030). */
public record RegistrarDisponibilidadRequest(
        @NotNull(message = "El tipo es obligatorio")
        TipoDisponibilidad tipo,
        @NotNull(message = "El periodo es obligatorio")
        @Valid
        Intervalo periodo,
        String motivo,
        Boolean confirmarPartidosAfectados) {
}
