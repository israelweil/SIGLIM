# Base de datos (Supabase / PostgreSQL)

Esquema versionado del sistema. Documentación de cada tabla:
[`docs/base-de-datos/diccionario-de-datos.md`](../docs/base-de-datos/diccionario-de-datos.md).
Reglas del flujo: [ADR-0004](../docs/arquitectura/adr/0004-migraciones-supabase.md).

## Contenido

| Archivo | Qué contiene |
| --- | --- |
| `migrations/20261007000000_esquema_inicial.sql` | Extensiones, enums, 22 tablas, funciones, triggers, índices, funciones públicas, RLS, políticas y datos semilla de roles/permisos. Incluye al final consultas de ejemplo comentadas. |

## Aplicar el esquema

**Opción A — SQL Editor (sin instalar nada):**
1. Abre tu proyecto en Supabase → *SQL Editor*.
2. Ejecuta las migraciones **en orden por nombre**, una sola vez cada una.

**Opción B — Supabase CLI (recomendada para trabajar en local):**
```bash
supabase login
supabase link --project-ref <ref-del-proyecto>
supabase db push          # aplica las migraciones pendientes al proyecto remoto
# entorno local completo (requiere Docker):
supabase start
```

## Reglas

- **Nunca edites una migración ya aplicada.** Crea una nueva:
  `supabase migration new descripcion_corta` o a mano con el formato `AAAAMMDDHHMMSS_descripcion.sql`.
- No cambies tablas desde el panel web de Supabase sin escribir la migración equivalente.
- Toda migración nueva actualiza el diccionario de datos en el mismo PR.
- Los datos de prueba (clubes, equipos ficticios) van en `seed.sql`, nunca en una migración.
