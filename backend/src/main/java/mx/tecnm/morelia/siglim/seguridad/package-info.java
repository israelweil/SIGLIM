/**
 * M-01 Administración y seguridad.
 *
 * <p>Perfiles, roles, permisos con ámbito, control dual, consentimiento y derechos ARCO
 * (ADR-0007).
 *
 * <p>Nivel 1 de dependencias (ADR-0006): solo puede usar {@code compartido} y {@code auditoria}.
 * Si necesita información de un módulo de nivel superior, lo hace con una interfaz definida en
 * este paquete o con un evento de dominio en {@code eventos}.
 */
package mx.tecnm.morelia.siglim.seguridad;
