/**
 * M-11 Portal público y publicación: portal.
 *
 * <p>Endpoints públicos de solo lectura ({@code /api/v1/publico}) sobre las vistas {@code
 * v_publica_*} con el rol {@code siglim_publico} (DP-006, ADR-0014).
 *
 * <p>Nivel 10 de dependencias (ADR-0006): puede usar los paquetes de todos los niveles
 * anteriores. Ningún otro módulo depende de este paquete.
 */
package mx.tecnm.morelia.siglim.portal;
