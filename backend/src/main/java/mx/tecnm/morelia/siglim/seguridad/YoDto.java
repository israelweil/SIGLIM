package mx.tecnm.morelia.siglim.seguridad;

import java.util.List;
import java.util.UUID;

/**
 * Respuesta de {@code GET /api/v1/yo}: el perfil del usuario actual, sus asignaciones de rol
 * activas con su ámbito y los permisos efectivos que resultan de ellas.
 *
 * <p>La interfaz la usa para ocultar lo que no aplica; no es barrera: cada operación vuelve a
 * autorizarse en el backend (VAL-015).
 *
 * <p>Refs: H-01.1, RF-094, ADR-0007
 */
public record YoDto(PerfilDto perfil, List<AsignacionDto> asignaciones, List<PermisoDto> permisos) {

    public YoDto {
        asignaciones = List.copyOf(asignaciones);
        permisos = List.copyOf(permisos);
    }

    /** Datos del perfil de SIGLIM; {@code correo} puede ser {@code null}. */
    public record PerfilDto(UUID id, String nombreMostrado, String correo) {
    }

    /** Asignación de rol activa; {@code club} solo con ámbito {@code CLUB}. */
    public record AsignacionDto(UUID id, RolDto rol, String ambito, ClubDto club) {
    }

    public record RolDto(String codigo, String nombre) {
    }

    public record ClubDto(UUID id, String nombre) {
    }

    /**
     * Permiso efectivo con el ámbito de la asignación que lo otorga; {@code clubId} solo con ámbito
     * {@code CLUB}.
     */
    public record PermisoDto(String codigo, String modulo, String ambito, UUID clubId) {
    }
}
