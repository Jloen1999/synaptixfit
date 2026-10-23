#!/usr/bin/env bash
# Crea el rol de la aplicación (no superusuario) con privilegios SOLO sobre su base.
#
#   sudo bash 02-crear-rol-app.sh
#
# - Rol synaptixfit_app: LOGIN, sin SUPERUSER/CREATEDB/CREATEROLE/REPLICATION.
# - Es dueño de la base synaptixfit y de su esquema public (Flyway crea las tablas).
# - Nadie más puede conectarse a synaptixfit (REVOKE CONNECT FROM PUBLIC).
# - La contraseña se genera aquí y se guarda en /root/synaptixfit/db-app.env (600, root):
#   es la que irá como variable secreta de la app en Coolify. Nunca se imprime.
# Idempotente: si db-app.env ya existe, reutiliza su contraseña.
set -euo pipefail
umask 077

DIR=/root/synaptixfit
UUID="$(cat "$DIR/db-uuid")"
ENV_FILE="$DIR/db-app.env"
APP_USER=synaptixfit_app
APP_DB=synaptixfit

if [[ -s "$ENV_FILE" ]]; then
    APP_PASS="$(sed -n 's/^DB_PASSWORD=//p' "$ENV_FILE")"
else
    APP_PASS="$(openssl rand -base64 24)"
    cat > "$ENV_FILE" <<ENV
# Credenciales de la app SynaptixFit para la BD (Coolify -> variables secretas de la app).
DB_HOST=$UUID
DB_PORT=5432
DB_DATABASE=$APP_DB
DB_USERNAME=$APP_USER
DB_PASSWORD=$APP_PASS
ENV
    chmod 600 "$ENV_FILE"
fi

# El SQL viaja por stdin (no aparece en la lista de procesos). Se conecta como el
# superusuario del contenedor usando sus propias variables de entorno.
docker exec -i "$UUID" sh -c 'psql -v ON_ERROR_STOP=1 -q -U "$POSTGRES_USER" -d postgres' <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$APP_USER') THEN
    CREATE ROLE $APP_USER LOGIN;
  END IF;
END
\$\$;
ALTER ROLE $APP_USER WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
  PASSWORD '$APP_PASS' CONNECTION LIMIT 40;
ALTER DATABASE $APP_DB OWNER TO $APP_USER;
REVOKE ALL ON DATABASE $APP_DB FROM PUBLIC;
GRANT CONNECT, TEMPORARY ON DATABASE $APP_DB TO $APP_USER;
REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;
\c $APP_DB
ALTER SCHEMA public OWNER TO $APP_USER;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO $APP_USER;
SQL
unset APP_PASS
echo "Rol $APP_USER listo; credenciales en $ENV_FILE (solo root)."
