package mx.tecnm.morelia.siglim.canchas;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.OffsetDateTime;
import java.util.UUID;

/** Cancha del catálogo (RF-027). Los campos opcionales vacíos se omiten (convenciones de API §1). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CanchaDto(UUID id, String nombre, UbicacionCancha ubicacion, String direccion,
                        PropietarioCancha propietario, ClubDto club, String propietarioExterno,
                        String caracteristicas, boolean activa, OffsetDateTime creadoEn) {

    public record ClubDto(UUID id, String nombre) {
    }
}
