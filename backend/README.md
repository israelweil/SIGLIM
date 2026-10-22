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
| `DB_URL` | Cadena JDBC de Supabase (Connect → JDBC → *Transaction pooler*, puerto 6543) terminada en `?currentSchema=siglim&prepareThreshold=0` (ADR-0014) |
| `DB_USERNAME` / `DB_PASSWORD` | Usuario del pooler (`postgres.<ref>`) y contraseña de la base de datos |
| `SUPABASE_URL` | `https://<ref>.supabase.co`, sin diagonal final; de aquí se derivan el JWKS y el emisor del JWT |
| `SIGLIM_CORS_ORIGEN` | Orígenes del frontend permitidos, separados por coma (convenciones de API §5) |

El detalle y los valores de ejemplo están en [`.env.example`](.env.example). Si falta una variable o
tiene un formato incorrecto, la aplicación no arranca y el error dice cuál es. Una prueba
(`VariablesEntornoDocumentadasTest`) falla si `application.yml` usa una variable que no esté en
`.env.example`: al agregar una, documéntala ahí en el mismo PR.

## Ejecutar

```bash
./mvnw spring-boot:run      # Windows: mvnw.cmd spring-boot:run
```

- Salud: <http://localhost:8080/actuator/health>
- API en ejecución: <http://localhost:8080/api/v1/salud> → `{"estado":"OK"}`

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
