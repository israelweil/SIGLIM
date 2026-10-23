package mx.tecnm.morelia.siglim.seguridad;

import java.util.List;
import java.util.UUID;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PerfilDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PermisoDto;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Consultas de {@code GET /api/v1/yo}. Corren dentro de la transacción del servicio, con
 * {@code siglim_app} y el {@code search_path} que fija {@code GestorTransaccionesSiglim}.
 *
 * <p>Refs: H-01.1, RF-094, ADR-0007
 */
@Repository
class YoRepository {

    /** Asignación activa tal como sale de la base de datos; el servicio la convierte al DTO. */
    record FilaAsignacion(UUID id, String rolCodigo, String rolNombre, String ambito, UUID clubId,
                          String clubNombre) {
    }

    private final JdbcClient jdbc;

    YoRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    PerfilDto buscarPerfil(UUID perfilId) {
        return jdbc.sql("""
                        SELECT id, nombre_mostrado, correo
                          FROM perfiles
                         WHERE id = :perfilId
                        """)
                .param("perfilId", perfilId)
                .query(PerfilDto.class)
                .single();
    }

    /** Asignaciones activas ordenadas por ámbito (orden del enum) y nombre del rol. */
    List<FilaAsignacion> listarAsignacionesActivas(UUID perfilId) {
        return jdbc.sql("""
                        SELECT a.id, r.codigo AS rol_codigo, r.nombre AS rol_nombre, a.ambito,
                               c.id AS club_id, c.nombre AS club_nombre
                          FROM asignaciones_rol a
                          JOIN roles r ON r.id = a.rol_id
                          LEFT JOIN clubes c ON c.id = a.club_id
                         WHERE a.perfil_id = :perfilId
                           AND a.activa
                         ORDER BY a.ambito, r.nombre, a.id
                        """)
                .param("perfilId", perfilId)
                .query(FilaAsignacion.class)
                .list();
    }

    /**
     * Permisos de los roles de las asignaciones activas, sin duplicados por código, ámbito y club
     * (un permiso que dan dos roles con el mismo ámbito aparece una vez).
     */
    List<PermisoDto> listarPermisosEfectivos(UUID perfilId) {
        return jdbc.sql("""
                        SELECT DISTINCT p.codigo, p.modulo, a.ambito, a.club_id
                          FROM asignaciones_rol a
                          JOIN rol_permisos rp ON rp.rol_id = a.rol_id
                          JOIN permisos p ON p.id = rp.permiso_id
                         WHERE a.perfil_id = :perfilId
                           AND a.activa
                         ORDER BY p.codigo, a.ambito, a.club_id
                        """)
                .param("perfilId", perfilId)
                .query(PermisoDto.class)
                .list();
    }
}
