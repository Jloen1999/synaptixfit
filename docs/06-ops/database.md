# Base de datos de producción

> **Qué es:** cómo se montó y se comprobó la base de datos de SynaptixFit en la infraestructura personal (VPS OVH + Coolify), y cómo repetirlo.
> **Montada el:** 2026-10-18 · **Recurso:** `synaptixfit-db` · **uuid (hostname interno):** `rnqvtuszzmxtfcb5ptvunlsp`

## Decisiones

| Decisión | Motivo |
|---|---|
| **PostgreSQL 17** (`postgres:17-alpine`) | El esquema usa `jsonb`, arrays, `gen_random_uuid()`, columnas generadas e índices parciales; es la misma versión que el desarrollo local (`docker-compose.yml`) y los tests de integración. Las reglas de negocio no dependen del motor (ADR 0012): cambiar a MySQL solo toca infraestructura y migraciones ([`database_portability.md`](database_portability.md)). |
| Recurso de Coolify en el destination **`infra-app-db`** | Red dedicada a bases de datos. `coolify-proxy` ya está conectado a ella, así que el backend se desplegará en el mismo destination: Traefik lo alcanza y él alcanza la BD por su uuid. |
| **Sin puerto público** ni puertos mapeados | Regla de la infraestructura. Comprobado: `PortBindings {}`, nada escucha en `:5432` del host, `5432` cerrado desde Internet. |
| Límite de memoria **768 MB** | El VPS tiene 3,7 GiB compartidos con Coolify, Infra Manager y la monitorización. |
| Superusuario `postgres` solo para administración; la app usa **`synaptixfit_app`** | Sin `SUPERUSER`/`CREATEDB`/`CREATEROLE`/`REPLICATION`; dueño de la base `synaptixfit` y de su esquema; nadie más puede conectarse a esa base y la app no puede entrar en la base `postgres`. |
| Esquema con **Flyway** (`backend/src/main/resources/db/migration/postgresql`) | Es la única fuente del esquema: versionada, con sumas de control y aplicada por la propia app al arrancar. No se mantiene una copia `migrations/` con `CREATE TABLE IF NOT EXISTS`: dos fuentes divergirían y Flyway ya garantiza la idempotencia (solo aplica lo pendiente y detecta cambios en lo aplicado). |

## Cómo se montó

Scripts en [`infra/scripts/`](../../infra/scripts/) (sin secretos). Se suben al VPS y se ejecutan con `sudo`; ningún secreto sale del servidor ni aparece en logs o en la lista de procesos.

| Paso | Script | Qué hace |
|---|---|---|
| 1 | `01-crear-recurso-postgres.sh` | Emite un token temporal de la API de Coolify (2 h, `read`/`write`/`deploy`), genera la contraseña del superusuario con `openssl rand -base64 24` y crea el recurso por la API (`POST /api/v1/databases/postgresql`, `is_public: false`). Guarda el uuid en `/root/synaptixfit/db-uuid`. |
| 2 | `02-crear-rol-app.sh` | Crea `synaptixfit_app` con otra contraseña generada, le da la base y el esquema, y cierra el acceso al resto. Credenciales en `/root/synaptixfit/db-app.env` (root, 600). |
| 3 | `03-aplicar-migraciones.sh` | Copia las migraciones a `/opt/synaptixfit/migrations` y ejecuta `flyway/flyway:12.4.0-alpine` (la versión del backend) en la red `infra-app-db` como `synaptixfit_app`. |
| 4 | `04-verificar.sh` | Comprobaciones de solo lectura (abajo). |
| 5 | `05-ampliar-backup.sh` + `bloque-*.sh` | Añade el volcado y la verificación de restauración de todos los PostgreSQL standalone de Coolify a la copia diaria. |

El token temporal se revocó al terminar (`personal_access_tokens` sin entradas `synaptixfit%`).

```powershell
# Desde Windows (OpenSSH con la clave del propietario):
scp infra\scripts\0*.sh infra-ovh:/tmp/
ssh infra-ovh 'sed -i "s/\r$//" /tmp/0*.sh && sudo bash /tmp/04-verificar.sh'
```

## Comprobaciones realizadas (2026-10-18)

| Comprobación | Resultado |
|---|---|
| Estado y redes | `postgres:17-alpine` healthy, solo red `infra-app-db`, `PortBindings {}`, memoria 805306368 B |
| Exposición | nada en `:5432` del host; `Test-NetConnection 135.125.1.223 -Port 5432` → `False` |
| Versión | PostgreSQL 17.11 |
| Roles | `postgres` super; `synaptixfit_app` super=false, createdb=false, createrole=false |
| Permisos | base `synaptixfit` dueño `synaptixfit_app`, ACL `{synaptixfit_app=CTc}`; base `postgres` sin `CONNECT` para PUBLIC |
| Esquema | 65 tablas, todas de `synaptixfit_app`; Flyway 9 migraciones (V1…V450), 0 fallidas |
| Datos de catálogo | ejercicios 909 · asignaturas_catalogo 395 · universidades 7 · insignias 16 · configuracion_global 1 · usuarios 0 |
| Conectividad | desde un contenedor en `infra-app-db` con `synaptixfit_app` → OK; desde la red `bridge` → inaccesible; `synaptixfit_app` → base `postgres` → denegado |
| Idempotencia | segunda ejecución de Flyway: sin cambios |
| Copia diaria | `infra-backup.sh --dry-run` incluye `app-pg-rnqvtuszzmxtfcb5ptvunlsp` (252 KB) y supera la validación |
| Restauración | volcado restaurado en un PostgreSQL 17 desechable: conteos `9|0|909|0|0` idénticos a producción |

## Credenciales

- **Superusuario `postgres`:** contraseña generada en el servidor y guardada por Coolify (Recursos → `synaptixfit-db` → General). Solo para administración.
- **App (`synaptixfit_app`):** `/root/synaptixfit/db-app.env` en el VPS (root, 600). Contiene `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` y `DB_PASSWORD`, los nombres que lee el backend (`backend/.env.example`). Al desplegar el backend en Coolify se cargan como variables **secretas** de la aplicación.
- Nunca en el repositorio, en la documentación, en los logs ni en el chat. Para verlas, el propietario lo hace en su propia terminal:
  ```powershell
  ssh infra-ovh 'sudo cat /root/synaptixfit/db-app.env'
  ```

### Rotar la contraseña de la app

```bash
sudo sed -i '/^DB_PASSWORD=/d' /root/synaptixfit/db-app.env   # fuerza una nueva
sudo bash 02-crear-rol-app.sh                                 # genera y aplica (ALTER ROLE)
```

Después, actualizar la variable secreta `DB_PASSWORD` de la app en Coolify y redesplegar.

## Conectar el backend (siguiente fase)

1. Aplicación de Coolify desde el repo `Jloen1999/synaptixfit` (`backend/Dockerfile`), destination **`infra-app-db`**.
2. Variables secretas: las cinco de `db-app.env` + `JWT_SECRET` y el resto de `backend/.env.example`.
3. Al arrancar, Flyway valida el historial existente (no reaplica nada) y Hibernate valida el esquema (`ddl-auto=validate`).

## Copias de seguridad

La copia diaria (`/usr/local/sbin/infra-backup.sh`, 03:30 UTC, cifrada con age a R2) vuelca automáticamente **todos** los recursos PostgreSQL standalone de Coolify (filtro por etiquetas `coolify.type=database` + `coolify.database.subType=standalone-postgresql`) como `volcados/app-pg-<uuid>-<fecha>.sql.gz`. `infra-restore-check.sh` los restaura en contenedores desechables y compara conteos. Las copias anteriores de ambos scripts quedaron como `*.bak-20261018-022232`.
