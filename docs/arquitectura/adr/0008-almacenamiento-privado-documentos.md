# ADR-0008: Resguardar documentos en Supabase Storage privado, siempre a través del backend

- **Estado:** Reemplazada por [ADR-0013](0013-documentos-en-aws-s3.md) (AWS S3)
- **Fecha:** 2026-10-19
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RNF-012, RNF-018, RNF-019, RF-059, RF-097, RF-108, RF-109, RF-139, DEC-10, DEC-40, PEN-023, PEN-040

## Contexto
El registro de jugadores exige documentos de identidad y fotos por tipo de categoría, y el INE del
tutor para los menores (RF-108, DEC-10). La disciplina admite evidencias (RF-059) y la tesorería
comprobantes de pago (RF-139). Son datos personales de acceso restringido: deben estar en un
repositorio privado y leerse solo con URL firmadas de vigencia corta por usuarios con permiso y
ámbito (RNF-018). El ERS acepta un servicio externo de almacenamiento (§3.1.3).

## Decisión
1. **Supabase Storage** con un bucket **privado** `documentos` (sin acceso público ni políticas
   para `anon` o `authenticated`: solo la clave secreta del backend lo usa).
2. **Ruta del objeto:** `liga/{ligaId}/{tipo}/{entidadId}/{documentoId}.{ext}`, donde `tipo` es
   `registros`, `tutores`, `evidencias` o `comprobantes`. La ruta no contiene nombres ni CURP.
3. **Carga a través del backend:** el frontend envía el archivo al backend (`multipart/form-data`);
   el servicio autoriza por permiso y ámbito (ADR-0007), valida el tipo por su firma binaria (JPEG,
   PNG, WebP o PDF) y el tamaño (5 MB **[PROPUESTA]**), sube el objeto con la API REST de Storage y
   registra la fila `documento` (tipo, ruta, tamaño, *hash* SHA-256, estado de validación) en la
   misma operación auditada. El bucket aplica también la lista de tipos y el tamaño máximo.
4. **Descarga con URL firmada:** el backend autoriza y devuelve una URL firmada con vigencia de
   **60 segundos [PROPUESTA]**. La URL no se guarda ni se registra en bitácoras (RNF-011).
5. **Sin borrado físico al reemplazar:** un documento nuevo sustituye al anterior lógicamente y el
   anterior se conserva para el historial del registro. La eliminación definitiva sigue la política
   de retención que defina la Liga (PEN-040) y las solicitudes de cancelación ARCO (RF-098).
6. **Cliente HTTP:** `RestClient` de Spring contra `https://<proyecto>.supabase.co/storage/v1`,
   encapsulado en `compartido.almacenamiento.AlmacenamientoDocumentos` para poder cambiar de
   proveedor sin tocar los módulos.

## Alternativas consideradas
- **Carga directa del navegador a Storage con URL de carga firmada:** descarga al backend de
  tráfico, pero obliga a validar el archivo después de subido y a exponer Storage al cliente,
  contra la regla de AGENTS.md de usar Supabase en el frontend solo para iniciar sesión.
- **Guardar los archivos en PostgreSQL (`bytea`):** respaldo único, pero infla la base y los
  respaldos, y degrada las consultas.
- **Otro proveedor (S3, Cloudinary):** agrega una cuenta y credenciales más sin beneficio para el
  volumen del proyecto.

## Consecuencias
- Cada archivo pasa por el backend: el límite de tamaño de las peticiones se configura en Spring
  (`spring.servlet.multipart.max-file-size`).
- **Capacidad:** el plan gratuito de Supabase incluye 1 GB de archivos. Con el volumen de RNF-017
  (15,000 personas) y unos 3 documentos de ~300 KB por persona se necesitan cerca de 13 GB por
  temporada: la operación real requiere el plan Pro (100 GB incluidos) o comprimir las fotos en el
  navegador antes de enviarlas. Para la demostración académica basta el plan gratuito.
- No se analizan archivos con antivirus; el riesgo se reduce con la lista blanca de tipos, la
  verificación de la firma binaria y la descarga solo por usuarios autorizados.
