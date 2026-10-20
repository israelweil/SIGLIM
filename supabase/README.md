# Base de datos (Supabase / PostgreSQL)

Esquema versionado del sistema. Documentación de cada tabla:
[`docs/base-de-datos/diccionario-de-datos.md`](../docs/base-de-datos/diccionario-de-datos.md).
Reglas del flujo: [ADR-0004](../docs/arquitectura/adr/0004-migraciones-supabase.md). Esquema propio y
roles: [ADR-0014](../docs/arquitectura/adr/0014-esquema-propio-y-roles-de-base-de-datos.md).

## Contenido

| Archivo | Qué contiene |
| --- | --- |
| `migrations/20261020090000_esquema_inicial.sql` | Migración inicial de la Rev. 0.4.1 (DEC-42): esquema `siglim`, roles `siglim_app` y `siglim_publico`, enums, 72 tablas, índices, triggers de reglas e historial, `calcular_tabla`, vistas `v_publica_*`, RLS por ámbito, comentarios de columnas y semilla (liga, perfil Sistema, 13 roles, permisos del Apéndice E, catálogos `[DEMO]`). Se ejecuta en una sola transacción. |
| `pruebas/` | Pruebas SQL de los flujos (P-01 a P-11) y de los desempates, con un simulador mínimo de Supabase para PostgreSQL local. Ver [`pruebas/README.md`](pruebas/README.md). |

La migración de la Rev. 0.3 quedó en
[`docs/base-de-datos/historico/`](../docs/base-de-datos/historico/) y no se aplica.

## Aplicar el esquema en un proyecto nuevo

**Opción A — SQL Editor (sin instalar nada):**
1. Abre tu proyecto en Supabase → *SQL Editor* → *New query*.
2. Pega el contenido completo de `migrations/20261020090000_esquema_inicial.sql` y pulsa *Run*.
   Si algo falla, nada queda aplicado (todo va en una transacción).
3. En *Authentication → Users* invita o crea al usuario administrador con su correo.
4. En el *SQL Editor* ejecuta:
   ```sql
   SELECT siglim.registrar_administrador_inicial('correo@ejemplo.com');
   ```
   Crea su perfil y le asigna el rol `ADMINISTRADOR_GENERAL` con ámbito de liga.

El esquema `siglim` **no** se agrega a *Settings → API → Exposed schemas*: los datos solo se leen a
través del backend (AGENTS.md §9).

**Opción B — Supabase CLI:**
```bash
supabase login
supabase link --project-ref <ref-del-proyecto>
supabase db push          # aplica las migraciones pendientes al proyecto remoto
```

## Reglas

- **Nunca edites una migración ya aplicada.** Crea una nueva:
  `supabase migration new descripcion_corta` o a mano con el formato `AAAAMMDDHHMMSS_descripcion.sql`.
- No cambies tablas desde el panel web de Supabase sin escribir la migración equivalente.
- Toda migración nueva actualiza el diccionario de datos en el mismo PR y conserva verdes las
  pruebas de `pruebas/`.
- Los datos de prueba (clubes, equipos ficticios) van en `seed.sql`, nunca en una migración.
