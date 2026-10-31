# infra

Scripts de operación de SynaptixFit sobre la infraestructura personal (VPS OVH + Coolify). No contienen secretos: las contraseñas se generan y se usan dentro del servidor.

| Script | Uso |
|---|---|
| `scripts/01-crear-recurso-postgres.sh` | Crea el recurso PostgreSQL en Coolify (API, sin puerto público) |
| `scripts/02-crear-rol-app.sh` | Rol `synaptixfit_app` con privilegios solo sobre su base (también rota su contraseña) |
| `scripts/03-aplicar-migraciones.sh` | Aplica las migraciones Flyway del backend desde la red `infra-app-db` |
| `scripts/04-verificar.sh` | Comprobaciones de solo lectura |
| `scripts/05-ampliar-backup.sh` + `bloque-*.sh` | Incluye los PostgreSQL de apps en la copia diaria y en la verificación de restauración |
| `scripts/00-copia-bd-synaptixfit.sh` | Copia puntual de la BD antes de desplegar migraciones (`/var/backups`, solo root) |
| `scripts/07-desplegar-synaptixfit.sh` · `08-verificar-synaptixfit.sh` | Despliegue de una etiqueta y comprobaciones |
| `scripts/10-revisar-registros-traefik.sh` | Comprueba, sin imprimir registros, que Traefik no guarda la ruta del calendario suscrito |
| `scripts/11-filtrar-salida-backend.sh` | Filtro de salida del contenedor backend (solo Internet y PostgreSQL); repetir tras cada despliegue |
| `desplegar.ps1` | Desde Windows: copia de la BD, despliegue, filtro de salida y verificación (`-Tag <commit>`) |

Procedimiento, decisiones y resultados: [`docs/06-ops/database.md`](../docs/06-ops/database.md).
