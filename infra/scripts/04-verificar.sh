#!/usr/bin/env bash
# Comprobaciones de solo lectura de la BD de SynaptixFit. No imprime secretos.
#
#   sudo bash 04-verificar.sh
set -euo pipefail
umask 077

DIR=/root/synaptixfit
# shellcheck source=/dev/null
source "$DIR/db-app.env"
UUID="$DB_HOST"

echo "== Contenedor: estado, puertos publicados y redes"
docker ps --format '{{.Names}} | {{.Image}} | {{.Status}} | puertos=[{{.Ports}}]' | grep "$UUID"
docker inspect "$UUID" --format 'redes: {{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}| port_bindings: {{json .HostConfig.PortBindings}} | memoria: {{.HostConfig.Memory}}'
echo "Escucha en el host (debe estar vacío):"
ss -ltnH | grep -E ':5432\b' || echo "  (nada en :5432)"

echo "== Superusuario (variables del propio contenedor)"
docker exec -i "$UUID" sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At' <<'SQL'
SELECT 'version: ' || version();
SELECT 'rol ' || rolname || ': super=' || rolsuper || ' createdb=' || rolcreatedb || ' createrole=' || rolcreaterole
  FROM pg_roles WHERE rolname IN ('postgres', 'synaptixfit_app');
SELECT 'base ' || datname || ': dueño=' || pg_get_userbyid(datdba) || ' acl=' || coalesce(datacl::text, '-')
  FROM pg_database WHERE datname IN ('postgres', 'synaptixfit');
SELECT 'tablas en public: ' || count(*) || ', de synaptixfit_app: ' || count(*) FILTER (WHERE tableowner = 'synaptixfit_app')
  FROM pg_tables WHERE schemaname = 'public';
SQL

ENV_TMP="$(mktemp)"
trap 'rm -f "$ENV_TMP"' EXIT
printf 'PGHOST=%s\nPGPORT=%s\nPGDATABASE=%s\nPGUSER=%s\nPGPASSWORD=%s\n' \
    "$DB_HOST" "$DB_PORT" "$DB_DATABASE" "$DB_USERNAME" "$DB_PASSWORD" > "$ENV_TMP"

echo "== Conectividad desde la red de la app (infra-app-db) con el rol de la app"
docker run -i --rm --network infra-app-db --env-file "$ENV_TMP" postgres:17-alpine psql -At <<'SQL'
SELECT 'conectado como ' || current_user || ' a ' || current_database() || ' (super=' || usesuper || ')' FROM pg_user WHERE usename = current_user;
SELECT 'flyway: ' || count(*) || ' migraciones, última V' || max(version::int) || ', fallidas=' || count(*) FILTER (WHERE NOT success) FROM flyway_schema_history;
SELECT 'ejercicios=' || (SELECT count(*) FROM ejercicios)
    || ' asignaturas_catalogo=' || (SELECT count(*) FROM asignaturas_catalogo)
    || ' universidades=' || (SELECT count(*) FROM universidades)
    || ' insignias=' || (SELECT count(*) FROM insignias)
    || ' configuracion_global=' || (SELECT count(*) FROM configuracion_global)
    || ' usuarios=' || (SELECT count(*) FROM usuarios);
SQL

echo "== El rol de la app NO puede entrar en la base postgres (debe fallar)"
if docker run --rm --network infra-app-db --env-file "$ENV_TMP" -e PGDATABASE=postgres postgres:17-alpine \
        psql -At -c 'SELECT 1' >/dev/null 2>&1; then
    echo "  FALLO: synaptixfit_app puede conectarse a postgres"
else
    echo "  OK: acceso denegado"
fi

echo "== Desde la red por defecto de Docker (bridge) no se resuelve ni alcanza (debe fallar)"
if docker run --rm --env-file "$ENV_TMP" postgres:17-alpine psql -At -c 'SELECT 1' >/dev/null 2>&1; then
    echo "  FALLO: accesible fuera de infra-app-db"
else
    echo "  OK: inaccesible fuera de infra-app-db"
fi
