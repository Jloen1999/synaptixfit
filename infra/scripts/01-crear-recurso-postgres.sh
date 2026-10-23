#!/usr/bin/env bash
# Crea el recurso PostgreSQL de SynaptixFit en Coolify (API), sin puerto público.
#
# Se ejecuta EN el VPS con sudo. Ningún secreto se imprime: el token temporal de la
# API y las contraseñas se generan y se usan dentro del servidor.
#
#   sudo bash 01-crear-recurso-postgres.sh
#
# Resultado: /root/synaptixfit/db-uuid con el uuid del recurso (hostname interno).
set -euo pipefail
umask 077

DIR=/root/synaptixfit
TOKEN_FILE="$DIR/coolify-api-token"
API=http://127.0.0.1:8000/api/v1

# Identificadores de Coolify (no son secretos; leídos de la BD de Coolify).
SERVER_UUID=sn1cqhrng4mfpfp1ch2vevy3        # ovh-main
PROJECT_UUID=8qgzcg2rx6ld5qboxwttdbze       # Infraestructura personal
ENVIRONMENT_UUID=mfubcsqxxsugk0uutjz86ryi   # production
DESTINATION_UUID=masrbaubzcsmuhwnaqprhxiw   # infra-app-db (red dedicada a BDs)

mkdir -p "$DIR"
chmod 700 "$DIR"

if [[ -s "$DIR/db-uuid" ]]; then
    echo "Ya existe un recurso registrado ($(cat "$DIR/db-uuid")); no se crea otro."
    exit 0
fi

# 1) Token temporal de la API (2 h, read+write+deploy), emitido para el equipo raíz.
#    Mismo mecanismo que la UI (User::createToken); solo se guarda en este servidor.
docker exec coolify php artisan tinker --execute='
$u = App\Models\User::find(0);
session(["currentTeam" => $u->teams()->first()]);
$t = $u->createToken("synaptixfit-db-setup (temporal)", ["read", "write", "deploy"], now()->addHours(2));
echo "TOKEN=" . $t->plainTextToken . PHP_EOL;
' | sed -n 's/^TOKEN=//p' > "$TOKEN_FILE"
[[ -s "$TOKEN_FILE" ]] || { echo "No se pudo crear el token temporal" >&2; exit 1; }

# 2) Contraseña del superusuario (administración); la de la app se crea en el paso 02.
SUPER_PASS="$(openssl rand -base64 24)"

BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT
cat > "$BODY" <<JSON
{
  "server_uuid": "$SERVER_UUID",
  "project_uuid": "$PROJECT_UUID",
  "environment_uuid": "$ENVIRONMENT_UUID",
  "destination_uuid": "$DESTINATION_UUID",
  "name": "synaptixfit-db",
  "description": "PostgreSQL de SynaptixFit (backend Spring Boot). Sin puerto público; solo red infra-app-db.",
  "image": "postgres:17-alpine",
  "postgres_user": "postgres",
  "postgres_password": "$SUPER_PASS",
  "postgres_db": "synaptixfit",
  "is_public": false,
  "limits_memory": "768m",
  "instant_deploy": true
}
JSON
unset SUPER_PASS

RESP="$(curl -sS -X POST "$API/databases/postgresql" \
    -H "Authorization: Bearer $(cat "$TOKEN_FILE")" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    --data @"$BODY")"

# La respuesta puede incluir la cadena de conexión con la contraseña: solo se extrae el uuid.
UUID="$(printf '%s' "$RESP" | grep -o '"uuid":"[a-z0-9]*"' | head -1 | cut -d'"' -f4)"
if [[ -z "$UUID" ]]; then
    echo "La API no devolvió un uuid. Mensaje (sin secretos):" >&2
    printf '%s' "$RESP" | grep -o '"message":"[^"]*"' >&2 || true
    exit 1
fi
echo "$UUID" > "$DIR/db-uuid"
echo "Recurso creado: $UUID"
