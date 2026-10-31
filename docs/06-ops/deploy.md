# Despliegue en producción (VPS OVH + Coolify)

> **Qué es:** cómo está desplegado SynaptixFit, cómo publicar una versión nueva y cómo cambiar secretos.
> **URL:** `https://synaptixfit.jloenit.dev` (web y API en el mismo subdominio).

## Arquitectura

```text
Navegador ──HTTPS──▶ Cloudflare (proxy, Full strict) ──▶ VPS :443 Traefik (certificado de origen *.jloenit.dev)
                                                              │
                                                    web (nginx, Flutter compilado)
                                                      ├── /        → la aplicación
                                                      └── /api/*   → backend:8080 (red interna)
                                                                        │
                                                              synaptixfit-db (PostgreSQL, sin puerto público)
```

| Pieza | Dónde |
|---|---|
| Recurso de Coolify | Service «synaptixfit» (Docker Compose), proyecto *Infraestructura personal*, destination **`infra-app-db`** (la misma red que la BD). Uuid en `/root/synaptixfit/service-uuid` |
| Compose | [`docker-compose.prod.yml`](../../docker-compose.prod.yml) |
| Imágenes | `ghcr.io/jloen1999/synaptixfit-backend` y `ghcr.io/jloen1999/synaptixfit-web`, etiquetadas con el commit |
| Por qué un solo subdominio | nginx reenvía `/api` al backend: mismo origen (sin CORS), un único registro DNS y un único certificado. Un subdominio de segundo nivel (`api.synaptixfit.jloenit.dev`) no lo cubrirían ni el certificado de origen ni el de Cloudflare (`*.jloenit.dev` solo cubre un nivel) |
| Por qué no compila el VPS | Compilar Flutter necesita varios GB de RAM; el VPS (2 núcleos, 3,7 GB) lo comparte con la BD, Coolify y la monitorización. Las imágenes se compilan en GitHub Actions |
| Memoria | backend 700 MB (JVM al 75 %), web 64 MB |
| Alias de red | El backend se publica en `infra-app-db` como **`synaptixfit-backend`** y nginx usa ese nombre (`BACKEND_UPSTREAM`). La red la comparten otras apps y varias tienen un servicio `backend`: con el alias genérico, nginx repartía las peticiones entre backends ajenos (401 y 404 al azar) |

## Publicar una versión nueva

1. Push a `master`. CI pasa los tests y, si están en verde, el job `images` publica las dos imágenes con la etiqueta del commit (`git rev-parse HEAD`).
2. La primera vez: en GitHub → *Packages* → cada imagen → *Package settings* → **Change visibility → Public** (el repositorio es público; así el VPS descarga sin credenciales).
3. Desplegar esa etiqueta (desde Windows):
   ```powershell
   scp docker-compose.prod.yml infra\scripts\07-desplegar-synaptixfit.sh infra\scripts\08-verificar-synaptixfit.sh infra-ovh:/tmp/
   ssh infra-ovh 'sed -i "s/\r$//" /tmp/0*.sh && sudo bash /tmp/07-desplegar-synaptixfit.sh <commit> <GOOGLE_CLIENT_IDS> /tmp/docker-compose.prod.yml'
   ssh infra-ovh 'sudo bash /tmp/08-verificar-synaptixfit.sh'
   ```
   También vale el panel de Coolify: Service *synaptixfit* → *Environment Variables* → `IMAGE_TAG` = commit → *Restart*.

Flyway aplica las migraciones pendientes al arrancar el backend. **Volver atrás:** desplegar la etiqueta anterior (las migraciones son aditivas; si una no lo fuera, se indica en su ADR).

### Sin GitHub Actions (imágenes compiladas en local)

```powershell
docker build -t ghcr.io/jloen1999/synaptixfit-backend:<tag> backend
docker build -t ghcr.io/jloen1999/synaptixfit-web:<tag> --build-arg API_BASE_URL=https://synaptixfit.jloenit.dev --build-arg GOOGLE_CLIENT_ID=<id web> frontend
docker save ghcr.io/jloen1999/synaptixfit-backend:<tag> ghcr.io/jloen1999/synaptixfit-web:<tag> | ssh infra-ovh 'sudo docker load'
```

Después, el paso 3 con esa `<tag>`. `pull_policy: missing` hace que use la imagen cargada sin intentar descargarla.

## Secretos

Viven solo en el VPS y en Coolify (marcados como *shown once*): nunca en el repositorio, la documentación ni el chat.

| Variable | Origen |
|---|---|
| `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` | `/root/synaptixfit/db-app.env` ([`database.md`](database.md)) |
| `JWT_SECRET` | `/root/synaptixfit/app-secrets.env` (lo genera el paso 07 la primera vez) |
| `DEEPSEEK_API_KEY` | `/root/synaptixfit/app-secrets.env` |
| `R2_ENDPOINT`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_PUBLIC_BASE_URL` | `/root/synaptixfit/app-secrets.env` (pendiente: crear el token de R2) |
| `GOOGLE_CLIENT_IDS`, `IMAGE_TAG`, `CORS_ALLOWED_ORIGINS`, `DEEPSEEK_MODEL` | No secretas: argumentos del paso 07 |

### Rotar la clave de DeepSeek (o cualquier secreto de la app)

1. Crea la clave nueva en <https://platform.deepseek.com/api_keys> y borra la antigua.
2. **Desarrollo:** cambia `DEEPSEEK_API_KEY` en `backend/.env` (no se sube a git) y reinicia el backend.
3. **Producción**, desde Windows, sin que la clave pase por la línea de comandos:
   ```powershell
   (Get-Content backend\.env | Where-Object { $_ -match '^DEEPSEEK_API_KEY=' }) | ssh infra-ovh 'sudo bash /tmp/guardar-secreto.sh'
   ssh infra-ovh 'sudo bash /tmp/07-desplegar-synaptixfit.sh <commit actual> <GOOGLE_CLIENT_IDS> /tmp/docker-compose.prod.yml'
   ```
   (`infra/scripts/guardar-secreto.sh` sustituye la línea en `app-secrets.env`; el paso 07 la sube a Coolify y reinicia.) Alternativa: Coolify → Service *synaptixfit* → *Environment Variables* → `DEEPSEEK_API_KEY` → *Restart*.

## Pasos que solo puede hacer el propietario

1. **Cloudflare → DNS** de `jloenit.dev`: registro `A` `synaptixfit` → `135.125.1.223`, **Proxied** (nube naranja). No hace falta Origin Rule: Traefik ya escucha en el 443.
2. **Google Cloud Console** → Credenciales → cliente OAuth web → *Orígenes de JavaScript autorizados*: `https://synaptixfit.jloenit.dev`.
3. **R2** (subida de archivos): Cloudflare → R2 → *Manage API tokens* → token con *Object Read & Write* solo para el bucket `synaptixfit`; guardar `R2_ENDPOINT`, `R2_ACCESS_KEY` y `R2_SECRET_KEY` con `guardar-secreto.sh` y redesplegar.
4. Hacer públicas las imágenes de GHCR tras el primer push (arriba).

## Infraestructura aplicada

| Paso | Script | Qué hace |
|---|---|---|
| 06 | `06-certificado-origen-traefik.sh` | Certificado de origen de Cloudflare `*.jloenit.dev` como certificado por defecto de Traefik (sin él, Full strict daría 526 en cualquier app de Coolify) |
| 07 | `07-desplegar-synaptixfit.sh` | Crea o actualiza el Service de Coolify, sube las variables (secretas como *shown once*) y reinicia. Token temporal de 1 h, revocado al terminar |
| 08 | `08-verificar-synaptixfit.sh` | Contenedores sanos, HTTPS por Traefik, `/api` llega al backend, sin puertos publicados |
| 09 | `09-prueba-funcional-synaptixfit.sh` | Registro → perfil → Pomodoro → inicio → borrado RGPD de la cuenta de prueba (no deja datos) |
| — | `guardar-secreto.sh` | Guarda `CLAVE=valor` leídos de la entrada estándar en `app-secrets.env` |

### Detalles de Coolify que conviene saber

- El Service se conecta a la red `infra-app-db` porque el compose la declara como red externa. Con solo el destination, Coolify deja los contenedores en una red propia sin acceso a la BD.
- El script para y arranca el servicio en lugar de usar *restart*: solo el arranque reescribe el compose en disco.
- Coolify crea vacías las variables del compose y una variable vacía anula el valor por defecto `${VAR:-…}`. Por eso el script manda un `R2_ENDPOINT` de relleno mientras no haya token de R2 (y el adaptador de R2 tolera que falte).

### Estado (2026-10-24)

- En línea en `https://synaptixfit.jloenit.dev` con la etiqueta `r20261024e` (2026-10-24), con la BD en v940: V930 añade los nombres de ejercicios en inglés, francés y portugués, y V940 rellena el código de mensaje de las notificaciones antiguas. Las imágenes se compilan en local y se cargan con `docker load`; si solo cambia la web, la imagen del backend se reetiqueta en el servidor. Antes de V930 se hizo la copia `synaptixfit-pre-v930-20261024-192250.sql.gz`.
- **Migraciones grandes** (p. ej. V850, 5 MB): tardan unos segundos más en el primer arranque (V850: 3,7 s; V930 + V940: 1,5 s; arranque total ~40 s), dentro del margen del healthcheck. Antes de aplicarlas se hace una copia puntual: `docker exec <contenedor-pg> pg_dump … | gzip > /var/backups/synaptixfit-pre-v<N>-<fecha>.sql.gz` (permisos 600). El contenedor de PostgreSQL se llama solo con el uuid del recurso (sin el prefijo `app-pg-` que lleva el volcado diario).
- **La verificación justo después de desplegar** puede dar fallos que no son reales: la web no arranca hasta que el backend está sano, y Traefik no le manda tráfico hasta que pasa su healthcheck. Hay que esperar a que los dos contenedores salgan como `(healthy)` en `docker ps` y repetir `08-verificar-synaptixfit.sh`.
- **Desplegar desde Windows:** `ssh infra-ovh` tiene que ser el OpenSSH de Windows (`C:\WINDOWS\System32\OpenSSH\ssh.exe`), que usa el agente de claves de Windows. El `ssh` de Git Bash no ve ese agente y el servidor responde `Permission denied (publickey)`.
- **Con poca memoria en Windows**, la web no se compila dentro de Docker: `flutter build web --release --dart-define=API_BASE_URL=… --dart-define=GOOGLE_CLIENT_ID=…` en Windows y una imagen `nginx:1.27-alpine` que copia `build/web` y `nginx/default.conf.template` (la segunda etapa de `frontend/Dockerfile`). El resultado es el mismo.
- DNS: registro `A synaptixfit` → VPS, con proxy de Cloudflare (creado por la API con el token de despliegue).
- R2 configurado (credenciales del bucket `synaptixfit` en `app-secrets.env`; `R2_PUBLIC_BASE_URL` = URL pública `pub-…r2.dev` del mismo bucket). Prueba desde Internet: subida y descarga reales, 9/9.
- Monitorización: `https://synaptixfit.jloenit.dev/healthz` en el job `webs` de la sonda blackbox (al editar `scrape.yml` hay que reiniciar `mon-victoriametrics`: el montaje no ve un `sed -i`).
- Regla CORS del bucket aplicada (`infra/cloudflare/r2-cors.json`, con `python infra/cloudflare/aplicar-r2-cors.py`; el token necesita *Workers R2 Storage: Edit*). Comprobado en Chrome: subir un PDF desde la web (`PUT 200` a R2) y verlo en el visor (`GET 200`). La vista previa de PDF en web usa pdf.js 4.6.82 desde jsDelivr (`web/index.html`, instalado con `dart run pdfx:install_web`).
- Cloudflare bloquea el agente de usuario genérico de Python (`Python-urllib`, error 1010); los clientes reales (navegador, Dart, okhttp) pasan. Los scripts de prueba envían su propio `User-Agent`.

La copia diaria ya incluye la BD.

**Datos demo:** seis cuentas `@demo.synaptixfit.test` (cinco estudiantes y un admin) sembradas con `tools/demo/seed_demo.py --base-url https://synaptixfit.jloenit.dev --db prod`; se borran con `tools/demo/purge_demo.py`. Ver [`tools/demo/README.md`](../../tools/demo/README.md).
