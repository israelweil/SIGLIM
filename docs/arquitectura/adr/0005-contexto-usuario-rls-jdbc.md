# ADR-0005: Propagar el usuario autenticado a PostgreSQL en cada transacción

- **Estado:** Aceptada · el punto 1 (rol `authenticated` y `auth.uid()`) lo reemplaza [ADR-0014](0014-esquema-propio-y-roles-de-base-de-datos.md)
- **Fecha:** 2026-10-13 (propuesta) · 2026-10-19 (aceptada)
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RF-045, RF-093, RN-021, RN-054, RNF-003, RNF-015, DD-006, ADR-0007

## Contexto
El esquema usa `auth.uid()` en las políticas RLS y en los triggers de historial y auditoría. En
Supabase, `auth.uid()` lee el claim `sub` de la configuración de sesión `request.jwt.claims`, que
solo existe cuando la petición entra por la API de Supabase.

El backend se conecta por **JDBC** con un usuario de base de datos. En esa conexión:
- `auth.uid()` devuelve `NULL`, y los historiales pierden el *quién* que exige RN-021.
- Si el usuario es `postgres` (dueño de las tablas), **RLS no se aplica**, así que la defensa en
  profundidad de ADR-0007 no existiría en la práctica.

## Decisión
1. Toda transacción de una petición autenticada (lectura o escritura) empieza con:

   ```sql
   SELECT set_config('request.jwt.claims', :claimsJson, true);  -- true = solo esta transacción
   SET LOCAL ROLE authenticated;
   ```

   `claimsJson` contiene al menos `{"sub": "<uuid del usuario>", "role": "authenticated"}`. Con
   esto `auth.uid()` funciona en triggers y RLS se evalúa con los permisos del usuario real.
2. Se implementa **una sola vez** en `compartido` (un aspecto sobre los servicios
   `@Transactional` o un *wrapper* del `DataSource`). Ningún repositorio lo repite.
3. Las tareas programadas (ADR-0009) usan un **usuario de sistema** (`perfil` con nombre «Sistema»
   y UUID fijo de la semilla) para que sus cambios también queden atribuidos.
4. Las consultas del portal público no propagan usuario: usan el rol `anon` y solo las vistas o
   funciones públicas (DP-006).
5. `SET LOCAL` y `set_config(..., true)` duran solo la transacción, por lo que el mecanismo es
   compatible con el *pooler* de Supabase en modo transacción.

## Alternativas consideradas
- **No propagar y llenar `updated_by`/`usuario_id` desde Java:** más simple, pero los triggers de
  historial guardarían `NULL` y RLS quedaría inactivo.
- **Conectar con un usuario sin `BYPASSRLS` sin propagar claims:** RLS bloquearía todo, porque
  `auth.uid()` sería `NULL`.
- **Una conexión por usuario con su propio JWT (API REST de Supabase):** contradice ADR-0002
  (JDBC) y AGENTS.md (el frontend no consulta Supabase).

## Consecuencias
- El usuario JDBC necesita permiso para `SET ROLE authenticated` (el usuario `postgres` de
  Supabase lo tiene).
- Las políticas RLS y los `GRANT` al rol `authenticated` forman parte de la migración inicial
  (DEC-42); sin ellos, toda consulta autenticada fallaría por falta de privilegios.
- Las pruebas de integración verifican que el historial registra al usuario y que RLS niega el
  acceso fuera de ámbito.
