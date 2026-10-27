package mx.tecnm.morelia.siglim.seguridad;

/**
 * Autoriza una operación por permiso y ámbito antes de ejecutarla, con denegación por defecto
 * (ADR-0007).
 *
 * <ul>
 *   <li><b>Regla.</b> Con ámbito {@code LIGA} se permite en toda la liga; con {@code CLUB}, si el
 *       club de la asignación está entre los clubes del objetivo; con {@code PROPIO}, si el usuario
 *       es titular (él mismo o el menor bajo su tutela) de alguna de las personas del objetivo.</li>
 *   <li><b>Denegación.</b> Si ninguna asignación activa del usuario otorga el permiso,
 *       {@code 403 VAL-015}. Si alguna lo otorga pero con un ámbito que no alcanza el objetivo,
 *       {@code 404} igual que un recurso inexistente, para no revelar si existe
 *       ({@link mx.tecnm.morelia.siglim.compartido.error.RecursoNoEncontradoException}, VAL-024).</li>
 *   <li><b>Permisos como datos.</b> Se leen de {@code asignaciones_rol}, {@code rol_permisos} y
 *       {@code permisos} en cada operación, sin caché ni claims del token, para que un cambio de
 *       permisos surta efecto de inmediato. El código <b>nunca</b> compara nombres de rol
 *       (DP-008).</li>
 *   <li><b>Barrera principal.</b> Las políticas RLS de PostgreSQL son defensa en profundidad
 *       (ADR-0014); el frontend solo oculta lo que no aplica y no es barrera.</li>
 * </ul>
 *
 * <p>Se llama al inicio de cada método público de servicio, dentro de su transacción, con el
 * objetivo que construye el módulo dueño del recurso ({@link ObjetivoAutorizacion}).
 *
 * <pre>{@code
 * autorizacion.exigir("programacion.jornada:APROBAR", ObjetivoAutorizacion.deLiga());
 * }</pre>
 *
 * <p>Refs: H-02.1, RF-094, RN-054, RNF-003, VAL-015, VAL-024, DD-009, DP-008, ADR-0007
 */
public interface Autorizacion {

    /**
     * Verifica que el usuario de la sesión pueda hacer esa operación sobre ese recurso.
     *
     * @param permiso  código {@code modulo.recurso:ACCION} del catálogo de la migración
     * @param objetivo a quién pertenece el recurso ({@link ObjetivoAutorizacion})
     * @throws mx.tecnm.morelia.siglim.compartido.error.ReglaNegocioException 403 {@code VAL-015} si
     *                         ninguna de sus asignaciones activas otorga el permiso
     * @throws mx.tecnm.morelia.siglim.compartido.error.RecursoNoEncontradoException 404 si tiene el
     *                         permiso pero fuera del objetivo (VAL-024)
     */
    void exigir(String permiso, ObjetivoAutorizacion objetivo);
}
