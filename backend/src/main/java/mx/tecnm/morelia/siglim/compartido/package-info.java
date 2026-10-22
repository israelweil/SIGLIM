/**
 * Componentes transversales, sin módulo M-xx.
 *
 * <p>Configuración (seguridad, CORS, tareas), errores RFC 9457, contexto de usuario por
 * transacción (ADR-0005, ADR-0014), almacenamiento de documentos (ADR-0008, ADR-0013) y reloj
 * inyectable.
 *
 * <p>Nivel 0 de dependencias (ADR-0006): no usa ningún otro paquete de la aplicación; todos los
 * módulos pueden usarlo.
 */
package mx.tecnm.morelia.siglim.compartido;
