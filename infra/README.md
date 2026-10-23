# infra

Scripts de operación de SynaptixFit sobre la infraestructura personal (VPS OVH + Coolify). No contienen secretos: las contraseñas se generan y se usan dentro del servidor.

| Script | Uso |
|---|---|
| `scripts/01-crear-recurso-postgres.sh` | Crea el recurso PostgreSQL en Coolify (API, sin puerto público) |
| `scripts/02-crear-rol-app.sh` | Rol `synaptixfit_app` con privilegios solo sobre su base (también rota su contraseña) |
| `scripts/03-aplicar-migraciones.sh` | Aplica las migraciones Flyway del backend desde la red `infra-app-db` |
| `scripts/04-verificar.sh` | Comprobaciones de solo lectura |
| `scripts/05-ampliar-backup.sh` + `bloque-*.sh` | Incluye los PostgreSQL de apps en la copia diaria y en la verificación de restauración |

Procedimiento, decisiones y resultados: [`docs/06-ops/database.md`](../docs/06-ops/database.md).
