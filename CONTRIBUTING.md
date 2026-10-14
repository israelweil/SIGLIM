# Cómo contribuir a SIGLIM

Guía de trabajo del equipo. Aplica igual a personas y a agentes de IA.

## 1. Flujo de ramas (GitHub Flow)

- `main` siempre compila y es la versión que se demuestra. **Nadie hace push directo a `main`.**
- Cada historia o tarea se trabaja en una rama corta que sale de `main` y vuelve por Pull Request.

| Tipo | Formato | Ejemplo |
| --- | --- | --- |
| Funcionalidad | `feat/<modulo>-<descripcion>` | `feat/m07-validar-conflictos` |
| Corrección | `fix/<modulo>-<descripcion>` | `fix/m08-recalculo-tabla` |
| Documentación | `docs/<descripcion>` | `docs/adr-0006-despliegue` |
| Base de datos | `db/<descripcion>` | `db/indices-partidos` |
| Mantenimiento | `chore/<descripcion>` | `chore/actualizar-dependencias` |

## 2. Commits (Conventional Commits)

```text
<tipo>(<ámbito>): <resumen en imperativo y minúsculas>

<cuerpo opcional: qué y por qué>

Refs: RF-039, VAL-004
```

- **Tipos:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `db`, `style`.
- **Ámbitos:** `front`, `back`, `db`, `docs` o el módulo (`m07`).
- Ejemplo: `feat(back): rechazar partido con cancha ocupada` + `Refs: RF-039, VAL-004`.

## 3. Pull Requests

- Un PR = una historia o tarea. Pequeño (idealmente < 400 líneas cambiadas sin contar generados).
- Llena la plantilla, incluida la **trazabilidad** (RF/CU/VAL que cubre).
- Al menos **1 aprobación** de otro integrante antes de fusionar. Se fusiona con *squash*.
- Si el PR toca la BD: incluye la migración nueva **y** la actualización del diccionario.

## 4. Definición de Terminado (DoD)

Una historia está terminada cuando:

- [ ] Cumple los criterios de aceptación de la historia y del ERS (§3.4.3).
- [ ] Compila sin errores: `./mvnw verify` (backend) y `npm run build && npm run lint` (frontend).
- [ ] Tiene pruebas de la regla de negocio principal y del caso de error.
- [ ] Respeta las convenciones de API y el sistema de diseño.
- [ ] Las operaciones críticas registran auditoría (RF-093).
- [ ] La documentación afectada está actualizada.
- [ ] Fue revisada y aprobada en PR.

## 5. Historias de usuario

Se registran como *Issues* con la plantilla **Historia de usuario** y se enlazan al tablero del
sprint. Formato:

> **Como** <perfil>, **quiero** <acción>, **para** <beneficio>.
> Criterios de aceptación en Gherkin (Dado / Cuando / Entonces) y trazabilidad a RF/CU.

## 6. Uso de agentes de IA

- El agente debe leer [`AGENTS.md`](AGENTS.md) antes de trabajar.
- Todo código generado por IA se revisa como si lo hubiera escrito otro integrante: se entiende,
  se prueba y se defiende en la revisión.
- No pegues secretos (`.env`, claves de Supabase) en conversaciones con una IA.
