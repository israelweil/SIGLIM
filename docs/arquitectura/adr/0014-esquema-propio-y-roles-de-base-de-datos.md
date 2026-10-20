# ADR-0014: Usar un esquema propio no expuesto y roles de base de datos de la aplicación

- **Estado:** Aceptada · reemplaza el punto 1 de [ADR-0005](0005-contexto-usuario-rls-jdbc.md) y el punto 4 de [ADR-0007](0007-autorizacion-permiso-y-ambito.md)
- **Fecha:** 2026-10-20
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RNF-003, RNF-012, RNF-015, RN-021, RN-054, VAL-024, DD-012, DP-006, DEC-42, ADR-0005, ADR-0007

## Contexto
Al escribir la nueva migración inicial (DEC-42) apareció un problema de seguridad en lo decidido:

- Supabase publica automáticamente las tablas del esquema `public` en su API REST y GraphQL, y la
  llave pública (`anon`) que usa el frontend para iniciar sesión basta para llamarla.
- ADR-0005 hacía que el backend adoptara el rol `authenticated` para que RLS aplicara. Ese rol es
  el mismo que obtiene cualquier usuario con su JWT en la API de Supabase: si tiene permiso de
  escritura para el backend, también lo tiene cualquier usuario que llame directo a esa API,
  saltándose las reglas del backend.
- `auth.uid()` devuelve el usuario de Supabase Auth, pero el sistema necesita el **perfil** de
  SIGLIM, que también existe para el usuario técnico «Sistema» sin cuenta en Auth (ADR-0009).

## Decisión
1. **Esquema `siglim`** para todas las tablas, vistas y funciones. No se agrega a los esquemas
   expuestos de la API de Supabase y no se concede ningún privilegio a `anon` ni a `authenticated`:
   la base de datos solo es accesible a través del backend.
2. **Dos roles propios sin inicio de sesión:**
   - `siglim_app`: el backend lo adopta en cada transacción autenticada. Tiene `SELECT`, `INSERT` y
     `UPDATE`, sin `DELETE` en tablas con historial; auditoría, historiales, parámetros y
     resoluciones solo admiten `INSERT`. Está sujeto a RLS.
   - `siglim_publico`: el portal lo adopta en las consultas públicas. Solo lee las vistas
     `v_publica_*` y ejecuta `calcular_tabla()`.
3. **Contexto por transacción** (sustituye a `SET LOCAL ROLE authenticated` de ADR-0005):

   ```sql
   SELECT set_config('request.jwt.claims', '{"sub":"<auth uuid>","perfil_id":"<uuid>"}', true);
   SELECT set_config('siglim.motivo', :motivo, true);   -- en cambios de estado (RN-021)
   SET LOCAL ROLE siglim_app;
   ```

   La función `siglim.usuario_actual()` lee `perfil_id`; los triggers registran con ella quién hizo
   cada cambio y exigen `siglim.motivo` en las transiciones. Las tareas programadas usan el perfil
   Sistema (UUID fijo de la semilla).
4. **RLS por ámbito** (precisa el punto 4 de ADR-0007): todas las tablas tienen RLS. Las de datos
   personales o de ámbito de club acotan lecturas y cambios con `es_usuario_liga()`,
   `club_visible()`, `persona_visible()`, `es_titular()` y funciones equivalentes; los **permisos
   finos** (`modulo.recurso:ACCION`) los sigue evaluando el backend. Las inserciones se permiten a
   `siglim_app` porque las autoriza el servicio, y los triggers de validación son
   `SECURITY DEFINER` para revisar reglas que cruzan ámbitos (por ejemplo, la CURP registrada en
   otro club) sin exponer esos datos.
5. **Usuario de conexión:** el backend se conecta con el usuario `postgres` del *pooler* de Supabase
   en modo transacción; la migración le concede los dos roles. La cadena de conexión vive solo en
   `backend/.env`.

## Alternativas consideradas
- **Mantener `public` y revocar privilegios a `anon` y `authenticated`:** funciona, pero Supabase
  vuelve a conceder privilegios en `public` a las tablas nuevas; una migración futura podría
  exponer datos sin que nadie lo note.
- **Desactivar la API de datos de Supabase:** también protege, pero depende de una configuración
  del panel que no queda en el repositorio.
- **Usuario de conexión distinto de `postgres`:** más aislado, pero su contraseña tendría que crearse
  fuera de la migración; se puede adoptar después sin cambiar el esquema.

## Consecuencias
- El backend agrega `currentSchema=siglim` a la URL de JDBC (o califica las tablas).
- Las consultas `INSERT … RETURNING` sobre tablas con RLS deben cumplir también la política de
  lectura; el backend genera los UUID en Java cuando el registro recién creado aún no es visible.
- Los nombres de rol `anon` y `authenticated` dejan de aparecer en las políticas; ADR-0005 conserva
  la idea de propagar el usuario y ADR-0007 la de RLS como defensa en profundidad.
- `supabase/pruebas/` verifica que `siglim_publico` no puede leer tablas y que RLS separa clubes.
