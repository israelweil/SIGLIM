# AGENTS.md — Backend (Spring Boot)

Complementa al [`AGENTS.md` raíz](../AGENTS.md). Léelo primero.

## Stack

Java 21 · Spring Boot 4.1 (Spring Framework 7, Spring Security 7, Jackson 3) · Spring JDBC
(`JdbcClient`) · PostgreSQL en Supabase · OAuth2 Resource Server (JWT de Supabase Auth) · JUnit 5,
Mockito y AssertJ.

> Spring Boot 4 cambió nombres de starters (`spring-boot-starter-webmvc`,
> `spring-boot-starter-security-oauth2-resource-server`) y movió Jackson a `tools.jackson`.
> No copies ejemplos de Spring Boot 2/3 sin adaptarlos.

## Comandos

```bash
./mvnw verify              # compila y ejecuta pruebas (obligatorio antes de terminar)
./mvnw spring-boot:run     # levanta en :8080 leyendo backend/.env
./mvnw test -Dtest=PortalServiceTest
```

## Estructura: paquete por módulo (ADR-0002, ADR-0006)

```text
mx.tecnm.morelia.siglim
├── compartido/      config (seguridad, CORS, tareas), error (RFC 9457), contexto de usuario (ADR-0005),
│                    almacenamiento (ADR-0008), reloj
├── auditoria/       M-01  auditoría inalterable
├── seguridad/       M-01  perfiles, roles, permisos con ámbito, control dual, consentimiento (ADR-0007)
├── temporadas/      M-02
├── organizacion/    M-03
├── registros/       M-04
├── canchas/         M-06
├── programacion/    M-07
├── arbitraje/       M-05
├── tesoreria/       M-13  (pasarela simulada, ADR-0012)
├── partidos/        M-08  (cédula, resultado oficial y tabla)
├── disciplina/      M-09
├── competencias/    M-10
├── publicacion/     M-11  comunicados y flujo de publicación
├── portal/          M-11  endpoints públicos de solo lectura
├── reportes/        M-12
└── notificaciones/  M-14  avisos y correo con bandeja de salida (ADR-0010)
```

El orden refleja los **niveles de dependencia** de ADR-0006: un paquete solo usa a los de arriba
en esta lista. Para ir «hacia abajo» usa un evento de dominio (`<modulo>/eventos/`) o una interfaz
definida por el módulo que la necesita. La prueba ArchUnit falla si aparece un ciclo.

Cada módulo contiene sus clases en el mismo paquete:

| Clase | Responsabilidad | Visibilidad |
| --- | --- | --- |
| `XxxController` | HTTP ↔ DTO, `@Valid`, códigos de estado. **Sin reglas de negocio.** | package-private |
| `XxxService` | Reglas de negocio, `@Transactional`, autorización por permiso, auditoría | `public` (lo que otros módulos pueden usar) |
| `XxxRepository` | SQL con `JdbcClient` y parámetros con nombre | package-private |
| `XxxDto` / `CrearXxxRequest` | `record` inmutables; validación con Jakarta Validation | según uso |

Cuando exista el primer módulo implementado, úsalo como plantilla (controlador → servicio →
repositorio + prueba del servicio).

## Reglas

- **Un módulo no usa el repositorio de otro**; llama a su `Service` público.
- **Transacciones en el servicio**, nunca en el controlador. `readOnly = true` para consultas.
- **Errores de negocio:** lanza `ReglaNegocioException.conflicto("VAL-004", "mensaje para el usuario")`;
  el `ManejadorGlobalErrores` la convierte a `application/problem+json`. No devuelvas
  `ResponseEntity` con mapas de error hechos a mano.
- **Recurso inexistente:** `RecursoNoEncontradoException`.
- **SQL:** solo nombres del diccionario de datos; columnas `snake_case` se mapean a campos
  `camelCase` del `record` automáticamente (`query(MiDto.class)`). Fechas con `OffsetDateTime`
  (`timestamptz`) o `LocalDate` (`date`).
- **Funciones del esquema:** úsalas en lugar de reimplementarlas: `calcular_tabla(grupo)`,
  `consultar_programacion_publica`, `consultar_resultados_publicos`, `consultar_tabla_publica`.
- **Autorización:** cada método público de servicio empieza con
  `autorizacion.exigir("modulo.recurso:ACCION", objetivo)` (ADR-0007). Nunca compares nombres de rol.
- **Estados:** las transiciones se validan en el servicio con una máquina de estados explícita
  (DP-003) según el ERS §4.3 (partido, cédula, registro, expediente, cobro, publicación).
- **Eventos:** efectos que forman parte de la operación crítica → oyente síncrono en la misma
  transacción; correo → bandeja de salida (ADR-0006, ADR-0010).
- **Tareas programadas:** `@Scheduled` con actualización condicional idempotente y usuario Sistema
  (ADR-0009). Usa el `Clock` inyectable, nunca `now()` directo en Java.
- **Usuario actual:** `UsuarioActual.idRequerido()` (UUID = `perfiles.id`). Llena `created_by`,
  `updated_by`, `validado_por`, etc. explícitamente. Lee [ADR-0005](../docs/arquitectura/adr/0005-contexto-usuario-rls-jdbc.md)
  antes de implementar el primer endpoint de escritura.
- **Configuración:** variables nuevas en `application.yml` con `${VARIABLE}` y documentadas en
  `.env.example`. Propiedades propias bajo el prefijo `siglim.`.
- **Sin** JPA, Lombok, `ddl-auto`, Flyway ni dependencias nuevas sin justificar.

## Pruebas

- **Unitarias** (obligatorias): reglas del servicio con Mockito, sin Spring ni BD. Nombre del
  método en español; `@DisplayName` con el ID del requisito.
- **De controlador** (`@WebMvcTest` + `@MockitoBean`): códigos HTTP, validación y formato de error.
- **De integración con BD:** pendientes de decidir (Testcontainers o un proyecto Supabase de
  pruebas); no las agregues sin acordarlo.
