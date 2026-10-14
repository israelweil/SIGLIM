# ADR-0005: Propagar el usuario autenticado a PostgreSQL en cada transacción

- **Estado:** Propuesta — decidir antes de implementar el primer endpoint de escritura
- **Fecha:** 2026-10-13
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RF-045, RF-093, RN-018, RN-021, RNF-003, DD-006

## Contexto
El esquema usa `auth.uid()` en las políticas RLS (`usuario_tiene_rol`) y en los triggers de
historial (`registrar_transicion_partido`, `historial_resultado`). En Supabase, `auth.uid()` lee
el claim `sub` de la configuración de sesión `request.jwt.claims`, que solo existe cuando la
petición entra por la API de Supabase.

El backend se conecta por **JDBC** con un usuario de base de datos. En esa conexión:
- `auth.uid()` devuelve `NULL` → `resultados_historial.reemplazado_por` queda vacío y el
  historial pierde el *quién* que exige RN-021.
- Si el usuario es `postgres` (dueño de las tablas), **RLS no se aplica**, así que la "defensa
  adicional" descrita en la arquitectura no existe en la práctica.

## Decisión propuesta
Al inicio de cada transacción de escritura, el backend ejecuta:

```sql
SELECT set_config('request.jwt.claims', :claimsJson, true);  -- true = solo esta transacción
SET LOCAL ROLE authenticated;
```

`claimsJson` contiene al menos `{"sub": "<uuid del usuario>", "role": "authenticated"}`. Con
esto `auth.uid()` funciona en triggers y RLS se evalúa con los permisos del usuario real. Se
implementa una sola vez en `compartido` (aspecto o *wrapper* del `DataSource`).

Las consultas del portal público siguen usando las funciones `consultar_*_publica()`.

## Alternativas consideradas
- **No propagar y llenar `updated_by`/`usuario_id` desde Java:** más simple, pero
  `historial_resultado` seguiría guardando `NULL` en `reemplazado_por` y RLS quedaría inactivo.
- **Conectar con un usuario sin `BYPASSRLS` sin propagar claims:** RLS bloquearía todo, porque
  `auth.uid()` sería `NULL`.

## Consecuencias
- Requiere que el usuario JDBC tenga permiso para `SET ROLE authenticated`.
- Las pruebas de integración deben verificar que el historial registra el usuario.
