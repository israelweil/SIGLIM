# Registros de decisiones de arquitectura (ADR)

Cada ADR documenta **una** decisión técnica: el contexto, lo que se decidió, las alternativas y
sus consecuencias. Formato basado en Michael Nygard (*Documenting Architecture Decisions*).

| ADR | Decisión | Estado |
| --- | --- | --- |
| [0001](0001-monorepo.md) | Monorepo con `frontend/`, `backend/`, `supabase/` y `docs/` | Aceptada |
| [0002](0002-monolito-modular-spring-jdbc.md) | Backend como monolito modular por paquetes M-xx con Spring JDBC | Aceptada |
| [0003](0003-autenticacion-supabase-jwt.md) | Supabase Auth en el cliente y validación del JWT con JWKS en el backend | Propuesta (PEN-030) |
| [0004](0004-migraciones-supabase.md) | El esquema solo cambia mediante migraciones en `supabase/migrations/` | Aceptada |
| [0005](0005-contexto-usuario-rls-jdbc.md) | Propagar el usuario autenticado a PostgreSQL para que RLS y `auth.uid()` funcionen | Propuesta |

## Estados

`Propuesta` → `Aceptada` → (`Reemplazada por ADR-xxxx` | `Obsoleta`). Un ADR aceptado **no se
edita**: si la decisión cambia, se crea uno nuevo que lo reemplaza.

## Plantilla

```markdown
# ADR-XXXX: Título en imperativo

- **Estado:** Propuesta | Aceptada | Reemplazada por ADR-YYYY
- **Fecha:** AAAA-MM-DD
- **Responsables:** nombres
- **Trazabilidad:** RNF-xxx, DD-xxx, PEN-xxx

## Contexto
¿Qué problema o fuerza obliga a decidir?

## Decisión
Lo que se hará, en una o dos frases claras.

## Alternativas consideradas
- Opción A: pros / contras.

## Consecuencias
Positivas, negativas y lo que queda pendiente.
```
