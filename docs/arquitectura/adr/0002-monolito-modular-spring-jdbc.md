# ADR-0002: Backend como monolito modular por paquetes con Spring JDBC

- **Estado:** Aceptada
- **Fecha:** 2026-10-13
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** DD-002, DP-001, DP-003, RNF-004, RNF-009; Tabla 2 de la arquitectura

## Contexto
La arquitectura define un monolito modular en capas (controlador → servicio → repositorio) y
acceso a datos por JDBC aprovechando restricciones, triggers y funciones del esquema
(`calcular_tabla()`, `consultar_*_publica()`, `validar_conflictos_partido`).

## Decisión
1. **Un paquete por módulo funcional** bajo `mx.tecnm.morelia.siglim`, con las capas dentro del
   módulo (*package by feature*), más un paquete `compartido` para lo transversal:

   | Paquete | Módulo |
   | --- | --- |
   | `seguridad` | M-01 Administración y seguridad (perfiles, roles, permisos) |
   | `auditoria` | M-01.3 Auditoría (servicio transversal) |
   | `temporadas` | M-02 Temporadas y normativa |
   | `organizacion` | M-03 Organización deportiva |
   | `registros` | M-04 Registros y elegibilidad |
   | `canchas` | M-06 Canchas y recursos |
   | `programacion` | M-07 Programación manual |
   | `partidos` | M-08 Partidos y resultados (incluye tabla) |
   | `publicacion` | M-11 Flujo de publicación |
   | `portal` | M-11 Endpoints públicos de solo lectura |
   | `compartido` | Configuración, errores, seguridad web, utilidades |

2. **Spring JDBC (`JdbcClient`)** con SQL explícito. **No se usa JPA/Hibernate** ni
   `ddl-auto`: el esquema lo controla la base de datos (ADR-0004) y la lógica que ya vive en
   triggers y funciones se invoca, no se duplica.
3. Las transacciones se delimitan con `@Transactional` **en los servicios**.
4. Un módulo solo usa a otro a través de su **servicio público**, nunca de su repositorio.

## Alternativas consideradas
- **Spring Data JPA:** menos SQL manual, pero choca con enums PostgreSQL, `tstzrange`, `jsonb` y
  funciones del esquema; tienta a usar `ddl-auto`, que rompería RLS y triggers.
- **Microservicios:** descartado por el ERS (DD-002 simplificado) y por el tamaño del equipo.
- **Package by layer** (`controllers/`, `services/`…): dispersa cada módulo en todo el proyecto y
  dificulta la trazabilidad M-xx → código.

## Consecuencias
- El SQL vive en los repositorios; los nombres de tabla y columna deben coincidir con el
  diccionario de datos.
- Opcional a futuro: Spring Modulith para verificar con una prueba que los módulos no se acoplen.
