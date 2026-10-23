#!/usr/bin/env bash
# Aplica las migraciones Flyway del backend a la BD de SynaptixFit.
#
#   sudo bash 03-aplicar-migraciones.sh /tmp/sfx-migrations
#
# Usa las MISMAS migraciones que el backend (backend/src/main/resources/db/migration/postgresql)
# y la MISMA versión de Flyway (12.4.0), desde un contenedor efímero en la red
# infra-app-db, conectándose como el rol de la app (no superusuario). Así la tabla
# flyway_schema_history queda igual que si la creara la app al arrancar.
# Idempotente: Flyway solo aplica lo pendiente y verifica las sumas de control.
set -euo pipefail
umask 077

SRC="${1:?ruta a las migraciones subidas}"
DIR=/root/synaptixfit
DEST=/opt/synaptixfit/migrations
FLYWAY_IMAGE=flyway/flyway:12.4.0-alpine
NETWORK=infra-app-db

# shellcheck source=/dev/null
source "$DIR/db-app.env"

install -d -m 755 "$DEST"
rm -f "$DEST"/*.sql
install -m 644 "$SRC"/*.sql "$DEST"/

ENV_TMP="$(mktemp)"
trap 'rm -f "$ENV_TMP"' EXIT
cat > "$ENV_TMP" <<ENV
FLYWAY_URL=jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_DATABASE
FLYWAY_USER=$DB_USERNAME
FLYWAY_PASSWORD=$DB_PASSWORD
FLYWAY_LOCATIONS=filesystem:/flyway/sql
ENV

run_flyway() {
    docker run --rm --network "$NETWORK" --env-file "$ENV_TMP" \
        -v "$DEST":/flyway/sql:ro "$FLYWAY_IMAGE" "$@"
}

run_flyway -q migrate
run_flyway info | grep -E '^\|' || true
