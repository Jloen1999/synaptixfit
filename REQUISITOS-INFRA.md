# Requisitos de infraestructura de SynaptixFit

Contrato con la infraestructura personal (VPS OVH + Coolify). Detalle operativo de la base de datos: [`docs/06-ops/database.md`](docs/06-ops/database.md).

## Base de datos

- **Motor:** PostgreSQL 17 (`postgres:17-alpine`). Motivo: el esquema usa `jsonb`, arrays, `gen_random_uuid()`, columnas generadas e índices parciales; es la misma versión que el desarrollo y los tests.
- **Recurso de Coolify:** `synaptixfit-db` (uuid `rnqvtuszzmxtfcb5ptvunlsp`), destination `infra-app-db`, **sin puerto público**. Ya creado y migrado.
- **Esquema:** Flyway (`backend/src/main/resources/db/migration/postgresql`); lo aplica la propia app al arrancar. Las reglas de negocio no dependen del motor (ADR 0012).
- **Usuario de la app:** `synaptixfit_app`, no superusuario, dueño solo de la base `synaptixfit`.
- **Copias:** incluidas en la copia diaria cifrada (volcado `app-pg-<uuid>`).

## Aplicación (Service de Coolify)

Despliegue detallado: [`docs/06-ops/deploy.md`](docs/06-ops/deploy.md).

| Campo | Valor |
|---|---|
| Recurso | Service «synaptixfit» (Docker Compose, [`docker-compose.prod.yml`](docker-compose.prod.yml)) con dos contenedores: `backend` (Spring Boot) y `web` (nginx con Flutter compilado, reenvía `/api` al backend) |
| Imágenes | `ghcr.io/jloen1999/synaptixfit-{backend,web}:<commit>`, compiladas por CI (el VPS no compila) |
| Destination | **`infra-app-db`** (misma red que la BD; `coolify-proxy` ya está en ella) |
| Puertos | Ninguno publicado: Traefik llega a `web:80`; `backend:8080` solo en la red interna |
| Salud | web `GET /healthz`; backend `GET /actuator/health` (healthchecks del compose) |
| Dominio | `https://synaptixfit.jloenit.dev` (web y API en el mismo origen), Cloudflare proxied + certificado de origen `*.jloenit.dev` en Traefik |

### Variables de entorno

| Variable | Ejemplo | Secreta | Descripción |
|---|---|---|---|
| `DB_VENDOR` | `postgresql` | no | motor (opcional; por defecto `postgresql`): elige la carpeta de migraciones `db/migration/<DB_VENDOR>` ([`docs/06-ops/database_portability.md`](docs/06-ops/database_portability.md)) |
| `DB_HOST` | `rnqvtuszzmxtfcb5ptvunlsp` | no | uuid del recurso (hostname interno) |
| `DB_PORT` | `5432` | no | |
| `DB_DATABASE` | `synaptixfit` | no | |
| `DB_USERNAME` | `synaptixfit_app` | no | usuario de la app (no superusuario) |
| `DB_PASSWORD` | `***` | **sí** | en `/root/synaptixfit/db-app.env` del VPS |
| `JWT_SECRET` | `***` | **sí** | ≥ 32 bytes (`openssl rand -base64 48`) |
| `JWT_ACCESS_TTL` / `JWT_REFRESH_TTL` | `15m` / `30d` | no | |
| `CORS_ALLOWED_ORIGINS` | `https://synaptixfit.jloenit.dev` | no | orígenes del cliente web (mismo origen en producción; necesario solo para clientes en otros dominios) |
| `GOOGLE_CLIENT_IDS` | `xxx.apps.googleusercontent.com` | no | IDs OAuth aceptados |
| `DEEPSEEK_API_KEY` | `***` | **sí** | IA generativa (DeepSeek) |
| `DEEPSEEK_MODEL` | `deepseek-chat` | no | modelo de DeepSeek |
| `R2_ENDPOINT` | `https://<cuenta>.r2.cloudflarestorage.com` | no | |
| `R2_BUCKET` | `synaptixfit` | no | |
| `R2_ACCESS_KEY` / `R2_SECRET_KEY` | `***` | **sí** | credenciales S3 de R2 |
| `R2_PUBLIC_BASE_URL` | `https://media.jloenit.dev` | no | vacío si el bucket es privado |

Plantilla completa: [`backend/.env.example`](backend/.env.example).

## Cliente (Flutter web)

Imagen `frontend/Dockerfile`: compila con `--dart-define=API_BASE_URL=https://synaptixfit.jloenit.dev` y `GOOGLE_CLIENT_ID` (variable `GOOGLE_WEB_CLIENT_ID` del repositorio en GitHub) y sirve con nginx. Sin secretos: el cliente nunca habla con la BD, la IA ni R2 directamente.
