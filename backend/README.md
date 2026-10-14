# SIGLIM · Backend

API REST de SIGLIM: Spring Boot 4.1, Java 21, Spring JDBC y PostgreSQL en Supabase.
Reglas para agentes de IA: [`AGENTS.md`](AGENTS.md) · Contrato REST:
[`convenciones-api.md`](../docs/arquitectura/convenciones-api.md).

## Requisitos

- JDK 21 (`java -version`). Maven **no** es necesario: el proyecto trae Maven Wrapper (`mvnw`).
- Un proyecto de Supabase con el esquema de `supabase/migrations/` aplicado y **JWT Signing Keys**
  asimétricas activadas (Authentication → JWT Keys).

## Configuración

```bash
cp .env.example .env    # Windows: copy .env.example .env
```

| Variable | Descripción |
| --- | --- |
| `DB_URL` | Cadena JDBC de Supabase (Database → Connect → JDBC; *Session pooler* si no tienes IPv6) |
| `DB_USERNAME` / `DB_PASSWORD` | Credenciales de la base de datos |
| `SUPABASE_URL` | `https://<ref>.supabase.co`; de aquí se derivan el JWKS y el emisor del JWT |
| `CORS_ORIGENES` | Orígenes del frontend permitidos, separados por coma |

## Ejecutar

```bash
./mvnw spring-boot:run      # Windows: mvnw.cmd spring-boot:run
```

- Salud: <http://localhost:8080/actuator/health>
- Ejemplo público: <http://localhost:8080/api/v1/publico/programacion?desde=2026-10-12T00:00:00-06:00&hasta=2026-10-19T00:00:00-06:00>

## Probar

```bash
./mvnw verify
```

## Abrir en el IDE

IntelliJ IDEA: *File → Open* → selecciona `backend/pom.xml` → *Open as Project*.
VS Code: extensión *Extension Pack for Java* y abre la carpeta `backend/`.

## Nota para Windows y Git

Si `./mvnw` no es ejecutable después de clonar en Linux/macOS, ejecuta una vez desde la raíz del
repositorio: `git update-index --chmod=+x backend/mvnw` y haz commit.
