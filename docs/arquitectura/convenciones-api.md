# Convenciones de la API REST

> **Estado:** [PROPUESTA] del equipo. El ERS deja abiertos los protocolos y formatos de las
> interfaces internas (ERS 3.1.4) y los códigos de error (PEN-016). Este documento fija un
> contrato común para que frontend y backend no improvisen. Cambios → PR con revisión de ambos lados.

## 1. Reglas generales

| Tema | Convención |
| --- | --- |
| Protocolo | HTTPS + JSON (`application/json; charset=utf-8`) |
| Prefijo | `/api/v1` para la aplicación interna · `/api/v1/publico` para el portal |
| Recursos | Sustantivos en **plural, español, kebab-case**: `/temporadas`, `/registros-jugador` |
| Campos JSON | **camelCase** (`equipoLocalId`). La BD usa snake_case; el repositorio hace el mapeo |
| Identificadores | UUID en texto (`"3f2c…"`). Los catálogos `roles` y `permisos` usan `bigint` |
| Fechas | ISO-8601 con zona: `2026-10-18T10:00:00-06:00` (`timestamptz`). Fechas puras: `2026-10-18` |
| Zona horaria de negocio | `America/Mexico_City` para mostrar y para calcular "semana" en el portal |
| Enums | Igual que en la BD, en MAYÚSCULAS: `PROGRAMADO`, `EN_JUEGO`, `BORRADOR`… |
| Nulos | Se omiten campos opcionales vacíos en respuestas; nunca se usa `""` como nulo |

## 2. Verbos y códigos de estado

| Operación | Verbo | Éxito | Ejemplo |
| --- | --- | --- | --- |
| Listar | `GET` | `200` | `GET /api/v1/equipos?grupoId=…` |
| Obtener | `GET` | `200` | `GET /api/v1/partidos/{id}` |
| Crear | `POST` | `201` + `Location` | `POST /api/v1/clubes` |
| Actualizar completo | `PUT` | `200` | `PUT /api/v1/canchas/{id}` |
| Actualizar parcial | `PATCH` | `200` | `PATCH /api/v1/equipos/{id}` |
| Acción de negocio | `POST` sobre sub-recurso | `200` / `201` | `POST /api/v1/partidos/{id}/transiciones` |

**No hay `DELETE` sobre entidades con historial** (temporadas, equipos, partidos, resultados,
registros de jugador): RF-003, RF-044, RN-005, RN-020. Las bajas son cambios de estado.

### Acciones de negocio (máquinas de estado)

Los cambios de estado son **acciones explícitas con motivo**, no un `PATCH` del campo `estado`:

| Acción | Endpoint | Cuerpo | Trazabilidad |
| --- | --- | --- | --- |
| Transición de partido | `POST /partidos/{id}/transiciones` | `{ "estadoNuevo": "SUSPENDIDO", "motivo": "…" }` | RF-043–RF-046, P-04 |
| Capturar marcador | `PUT /partidos/{id}/resultado` | `{ "golesLocal": 2, "golesVisitante": 1 }` | RF-047 |
| Validar resultado | `POST /resultados/{id}/validacion` | `{ "observaciones": "…" }` | RF-048 |
| Corregir resultado oficial | `POST /resultados/{id}/correcciones` | `{ "golesLocal": 1, "golesVisitante": 1, "motivo": "…" }` | RF-052, RN-024 |
| Baja de jugador | `POST /registros-jugador/{id}/baja` | `{ "fechaBaja": "…", "motivo": "…" }` | RF-014 |
| Enviar jornada a revisión | `POST /jornadas/{id}/revision` | `{ "motivo": "…" }` | RF-040, RF-090 |
| Publicar jornada | `POST /jornadas/{id}/publicacion` | `{}` | RF-090, CU-007 |

## 3. Formato de errores (RFC 9457 · Problem Details)

Todas las respuestas de error usan `application/problem+json` (soporte nativo de Spring con
`ProblemDetail`):

```json
{
  "type": "https://siglim.local/errores/conflicto-programacion",
  "title": "Conflicto de programación",
  "status": 409,
  "detail": "La cancha «Unidad Deportiva 1» ya está ocupada de 10:00 a 12:00.",
  "instance": "/api/v1/partidos",
  "codigo": "VAL-004",
  "errores": [
    { "campo": "canchaId", "mensaje": "Cancha ocupada en ese intervalo" }
  ]
}
```

| Situación | HTTP | `codigo` |
| --- | --- | --- |
| Cuerpo inválido / campos faltantes | `400` | `VALIDACION` |
| Sin token o token inválido | `401` | `NO_AUTENTICADO` |
| Rol sin permiso (denegación por defecto) | `403` | `VAL-015` |
| Recurso inexistente | `404` | `NO_ENCONTRADO` |
| Equipo duplicado en el intervalo | `409` | `VAL-003` |
| Cancha ocupada | `409` | `VAL-004` |
| Cancha no disponible / bloqueada | `409` | `VAL-005` |
| Acción no permitida por el estado del partido | `409` | `VAL-008` |
| Corrección no autorizada | `403` | `VAL-010` |
| Error inesperado | `500` | `ERROR_INTERNO` (sin detalles técnicos ni SQL) |

`detail` es un mensaje **para el usuario final**, en español y explicando la causa (ERS 3.1.1:
"mostrar los conflictos de programación y su motivo"). Los textos definitivos siguen pendientes
(PEN-016).

> El trigger `validar_conflictos_partido` es la **última garantía**. El servicio debe detectar el
> conflicto **antes** y responder con el mensaje explicativo; si aun así el trigger lanza la
> excepción, el manejador global la traduce al `409` correspondiente.

## 4. Listas, filtros y paginación

```http
GET /api/v1/partidos?jornadaId=…&estado=PROGRAMADO&page=0&size=20&sort=inicioProgramado,asc
```

```json
{
  "contenido": [ { "id": "…" } ],
  "pagina": 0,
  "tamano": 20,
  "totalElementos": 57,
  "totalPaginas": 3
}
```

- `size` máximo: 100. Por defecto: 20.
- Filtros con el nombre del campo en camelCase. Rangos de fecha: `desde` (inclusivo) y `hasta`
  (exclusivo), como las funciones `consultar_*_publica(p_desde, p_hasta)`.

## 5. Seguridad

- Cabecera `Authorization: Bearer <access_token de Supabase>` en todo `/api/v1/**` excepto
  `/api/v1/publico/**` (ADR-0003).
- Autorización por **permiso** `modulo:ACCION`, alineado con la tabla `permisos`
  (`programacion:GESTIONAR`, `resultados:VALIDAR`, …). Nunca se decide por el nombre del rol en
  el controlador.
- Toda operación crítica registra auditoría (RF-093): usuario, fecha, módulo, acción, motivo.
- CORS: solo el origen del frontend configurado por variable de entorno.

## 6. Portal público (`/api/v1/publico`)

Solo `GET`, sin autenticación, y únicamente información con estado `PUBLICADO` (RF-056, VAL-014).
Consume las funciones del esquema:

| Endpoint | Función SQL | RF |
| --- | --- | --- |
| `GET /publico/programacion?desde=&hasta=` | `consultar_programacion_publica` | RF-082, RF-089 |
| `GET /publico/resultados?desde=&hasta=` | `consultar_resultados_publicos` | RF-083, RF-089 |
| `GET /publico/grupos/{grupoId}/tabla` | `consultar_tabla_publica` | RF-084 |

No exponer datos personales de jugadores (RNF-012).

## 7. Documentación del contrato

Cada controlador se documenta con OpenAPI (springdoc) cuando se agregue la dependencia; mientras
tanto, este archivo y los DTO son el contrato.
