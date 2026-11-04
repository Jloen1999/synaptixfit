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
| OCR | La imagen del backend incluye Tesseract (≈ 60 MB) para leer fotos de apuntes (ADR 0040). Cada lectura es un proceso aparte de 100-200 MB **fuera** de la JVM: como mucho 2 a la vez (`SYNAPTIXFIT_OCR_MAX_CONCURRENT`), un hilo cada una (`OMP_THREAD_LIMIT=1`) y con tope de 768 MB por lectura (`SYNAPTIXFIT_OCR_MEMORY_LIMIT_MB`, con `prlimit`), así que el límite de memoria del contenedor debe dejar ≈ 400 MB libres además del de Java (`MaxRAMPercentage=75`) |
| Dominio | `https://synaptixfit.jloenit.dev` (web y API en el mismo origen), Cloudflare proxied + certificado de origen `*.jloenit.dev` en Traefik |

### Rutas con credenciales y salida a Internet

* **Calendario suscrito** (`/api/v1/planner/calendar-feed/<token>.ics`, ADR 0020): el token de la ruta es una
  credencial. El nginx del cliente no lo registra y limita a 30 peticiones por minuto e IP. Además:
  - **Traefik** no debe guardar registros de acceso con la ruta (desactivados o con la ruta quitada).
    `infra/scripts/10-revisar-registros-traefik.sh` lo comprueba sin imprimir ninguna línea de registro.
  - En **Cloudflare**, *Bot Fight Mode* o los desafíos no deben bloquear esa ruta, porque los lectores de Google,
    Apple y Outlook no resuelven desafíos. Regla personalizada de WAF «Skip» con la expresión
    `starts_with(http.request.uri.path, "/api/v1/planner/calendar-feed/")` (2026-10-31: sin bloqueo; probado
    con los agentes de Google Calendar, Apple y Outlook).
* **Descarga de calendarios ICS** (importación por URL): el backend descarga direcciones que da el usuario. La app
  rechaza IP privadas y puertos que no sean 80/443 en cada redirección. Queda un riesgo residual, porque el nombre
  se vuelve a resolver al conectar (DNS rebinding). Lo cierra `infra/scripts/11-filtrar-salida-backend.sh
  --aplicar`: reglas dentro del espacio de red del contenedor `backend` (no en el cortafuegos del servidor) que
  solo dejan salir a Internet y a PostgreSQL de `infra-app-db`. Se pierden al recrear el contenedor:
  `infra/desplegar.ps1` las vuelve a aplicar en cada despliegue.

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
| `R2_PUBLIC_BASE_URL` | *(vacío)* | no | vacío: los archivos de los usuarios no se publican (se descargan con URL firmada) |
| `R2_PROXY_BASE_URL` | `https://synaptixfit.jloenit.dev/storage` | no | subidas y descargas firmadas a través del nginx de la app (ADR 0024); vacío: directas a R2 |
| `R2_MEDIA_UPSTREAM` | `https://pub-….r2.dev` | no | contenedor `web`: dirección pública del bucket a la que nginx reenvía `/media/ejercicios/` (ADR 0024); por defecto, la del bucket actual |
| `MEDIA_PUBLIC_BASE_URL` | `https://synaptixfit.jloenit.dev/media` | no | vídeos e imágenes de los ejercicios a través del nginx de la app (ADR 0024); vacío: desde `pub-….r2.dev` |
| `RESEND_API_KEY` | `***` | **sí** | **obligatoria en producción**: correo transaccional (Resend); sin ella no sale ningún correo aunque la API responda 202 (ADR 0021) |
| `MAIL_FROM` | `SynaptixFit <no-reply@notifications.jloenit.dev>` | no | remitente; dominio verificado en Resend (`notifications.jloenit.dev`, región eu-west-1) |
| `WEEKLY_EMAIL_CRON` | `0 0 19-23 * * SUN` | no | opcional: cuándo sale el resumen semanal por correo (zona del planificador). Cada hora de 19 a 23 reintenta solo a quien no lo recibió; `-` lo desactiva |
| `CLASS_AUTO_ATTEND_CRON` | `0 */10 * * * *` | no | opcional: cada cuánto se dan por asistidas las clases que acaban de terminar (ADR 0029); `-` lo desactiva |
| `APP_PUBLIC_URL` | `https://synaptixfit.jloenit.dev` | no | **obligatoria en producción**: base de los enlaces de los correos; sin ella apuntan a `http://localhost:5173` |

Plantilla completa: [`backend/.env.example`](backend/.env.example).

## Cliente (Flutter web)

Imagen `frontend/Dockerfile`: compila con `--dart-define=API_BASE_URL=https://synaptixfit.jloenit.dev` y `GOOGLE_CLIENT_ID` (variable `GOOGLE_WEB_CLIENT_ID` del repositorio en GitHub) y sirve con nginx. Sin secretos: el cliente nunca habla con la BD, la IA ni R2 directamente.
