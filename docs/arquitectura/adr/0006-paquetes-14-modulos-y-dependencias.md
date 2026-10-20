# ADR-0006: Organizar el backend en los 14 módulos del ERS y verificar que no haya ciclos

- **Estado:** Aceptada
- **Fecha:** 2026-10-19
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** DD-002, DP-001, DP-003, RNF-004, RNF-009, ERS §2.2 y §4.5; reemplaza la tabla de paquetes de ADR-0002

## Contexto
ADR-0002 definió un paquete por módulo para los 8 módulos de la Rev. 0.3. El ERS Rev. 0.4 tiene 14
módulos (M-01 a M-14) y procesos que cruzan varios de ellos: aprobar una cédula oficializa el
resultado (M-08), abre expedientes (M-09) y avisa a los involucrados (M-14); publicar una jornada
(M-07) genera cobros (M-13). Sin reglas de dependencia, estos flujos crean ciclos entre paquetes,
y RNF-009 exige que no existan y que se verifique con una prueba de arquitectura.

## Decisión

### 1. Paquetes
Bajo `mx.tecnm.morelia.siglim`, un paquete por módulo, con sus capas dentro (ADR-0002 sigue
vigente en lo demás: Spring JDBC, transacciones en servicios, un módulo no usa el repositorio de
otro):

| Paquete | Módulo | Contenido principal |
| --- | --- | --- |
| `compartido` | — | Configuración, errores RFC 9457, contexto de usuario (ADR-0005), utilidades |
| `auditoria` | M-01 | Registro y consulta de auditoría (RF-093, RF-134) |
| `seguridad` | M-01 | Perfiles, roles, permisos con ámbito, control dual, consentimiento y ARCO (ADR-0007) |
| `temporadas` | M-02 | Temporadas, categorías y jerarquía, grupos, parámetros versionados |
| `organizacion` | M-03 | Clubes, afiliación, directiva, equipos, propiedad y plaza, personas y tutela |
| `registros` | M-04 | Registro de jugador, documentos, unicidad por CURP, elegibilidad |
| `canchas` | M-06 | Canchas, sedes, disponibilidad, bloqueos, horarios de club, solicitudes (Formatos 1 y 2) |
| `programacion` | M-07 | Jornadas, partidos programados, conflictos, localía, aprobación de la jornada |
| `arbitraje` | M-05 | Árbitros, validación, disponibilidad y designaciones |
| `tesoreria` | M-13 | Tarifas, cobros, pago simulado, pagos y adeudos (ADR-0012) |
| `partidos` | M-08 | Estado del partido, cédula, resultado oficial, tabla y estadísticas |
| `disciplina` | M-09 | Catálogos, expedientes, resoluciones, sanciones y recursos |
| `competencias` | M-10 | Liguilla, llaves, ascensos y descensos |
| `publicacion` | M-11 | Comunicados y su flujo Borrador → Revisión → Publicado |
| `portal` | M-11 | Endpoints públicos de solo lectura sobre vistas publicadas (DP-006) |
| `reportes` | M-12 | Reportes y exportación (consultas de solo lectura) |
| `notificaciones` | M-14 | Avisos en la aplicación y por correo (ADR-0010) |

### 2. Dirección de las dependencias
Un paquete solo puede depender de los que están en un nivel **inferior**:

| Nivel | Paquetes | Pueden usar |
| --- | --- | --- |
| 0 | `compartido` | — |
| 1 | `auditoria`, `seguridad` | `compartido`; `seguridad` usa `auditoria` |
| 2 | `temporadas` | niveles 0–1 |
| 3 | `organizacion` | niveles 0–2 |
| 4 | `registros`, `canchas` | niveles 0–3 |
| 5 | `programacion` | niveles 0–4 |
| 6 | `arbitraje`, `tesoreria` | niveles 0–5 |
| 7 | `partidos` | niveles 0–6 |
| 8 | `disciplina` | niveles 0–7 |
| 9 | `competencias` | niveles 0–8 |
| 10 | `publicacion`, `portal`, `reportes`, `notificaciones` | todos los anteriores |

Cuando un módulo inferior necesita información de uno superior, se usa una de dos formas:

- **Interfaz definida por quien la necesita** (inversión de dependencias). Ejemplos:
  `programacion.RestriccionesDeEquipo` (baja o sanción que impide jugar, RF-039) y
  `partidos.ConsultaSanciones` (sanción vigente al capturar la alineación, RF-020) las implementa
  `disciplina`; `programacion.ConsultaDesignaciones` la implementa `arbitraje`.
- **Evento de dominio** publicado por el módulo inferior, como `record` en su subpaquete `eventos`,
  con `ApplicationEventPublisher`:
  - Si el efecto **forma parte de la misma operación crítica** (RNF-004), el oyente es síncrono
    (`@EventListener`) y corre en la misma transacción. Ejemplo: `partidos.eventos.CedulaAprobada`
    → `disciplina` abre los expedientes (RF-125, RN-046); si falla, se revierte la aprobación.
  - Si el efecto **sale del sistema** (correo), el oyente solo lo deja registrado en la misma
    transacción y una tarea programada lo ejecuta después (bandeja de salida, ADR-0010). Ejemplo:
    `notificaciones` escucha `CedulaAprobada`, `JornadaPublicada` o `CobroGenerado`, crea el aviso
    en la aplicación y encola el correo; el envío nunca bloquea ni revierte la operación.

Ningún módulo depende de `notificaciones`, `portal` ni `reportes`.

### 3. Verificación (RNF-009)
Una prueba con **ArchUnit** (`com.tngtech.archunit:archunit-junit5`, alcance `test`) comprueba en
`./mvnw verify`:
1. que los paquetes de módulo estén libres de ciclos (`slices().matching("..siglim.(*)..")
   .should().beFreeOfCycles()`);
2. que cada paquete respete la tabla de niveles;
3. que ningún `Repository` se use fuera de su paquete.

## Alternativas consideradas
- **Spring Modulith:** verifica módulos y ofrece un registro de eventos persistente. Es más
  completo, pero agrega convenciones y dependencias de ejecución que el equipo tendría que aprender
  en 8 semanas; puede adoptarse después sin cambiar los paquetes.
- **Un solo paquete `dominio` con todo:** elimina los ciclos por construcción, pero pierde la
  trazabilidad M-xx → código y el aislamiento entre integrantes del equipo.
- **Llamadas directas en ambas direcciones:** más rápido de escribir, pero crea ciclos
  (`partidos` ↔ `disciplina`, `programacion` ↔ `disciplina`) que RNF-009 prohíbe.

## Consecuencias
- ArchUnit es una dependencia nueva **solo de pruebas**; no llega al artefacto de producción.
- Un evento síncrono es parte del contrato del módulo que lo publica: cambiar su contenido exige
  revisar a sus oyentes.
- Si un flujo nuevo necesita una dependencia hacia arriba, se resuelve con interfaz o evento, y se
  documenta en esta tabla mediante una ADR nueva.
- `backend/AGENTS.md` muestra esta estructura.
