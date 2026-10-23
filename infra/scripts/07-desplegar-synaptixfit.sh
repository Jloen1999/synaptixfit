#!/usr/bin/env bash
# Crea o actualiza SynaptixFit en Coolify como «Service» de Docker Compose (sin repositorio git: el
# VPS no compila, usa las imágenes de GHCR o las cargadas con `docker load`) y lo arranca.
#
# Se ejecuta EN el VPS con sudo. Ningún secreto se imprime ni pasa por la línea de comandos:
#   - /root/synaptixfit/db-app.env      credenciales de la BD (paso 02)
#   - /root/synaptixfit/app-secrets.env JWT_SECRET (se genera aquí si falta), DEEPSEEK_API_KEY
#     y, si existen, R2_ACCESS_KEY / R2_SECRET_KEY / R2_ENDPOINT / R2_PUBLIC_BASE_URL
#
#   sudo bash 07-desplegar-synaptixfit.sh <IMAGE_TAG> <GOOGLE_CLIENT_IDS> [/ruta/docker-compose.prod.yml]
#
# Resultado: /root/synaptixfit/service-uuid con el uuid del recurso de Coolify.
set -euo pipefail
umask 077

IMAGE_TAG="${1:?Uso: $0 <IMAGE_TAG> <GOOGLE_CLIENT_IDS> [compose]}"
GOOGLE_CLIENT_IDS="${2:-}"
COMPOSE="${3:-/tmp/docker-compose.prod.yml}"
DOMAIN=https://synaptixfit.jloenit.dev

DIR=/root/synaptixfit
TOKEN_FILE="$DIR/coolify-api-token"
API=http://127.0.0.1:8000/api/v1

# Identificadores de Coolify (no son secretos; los mismos que el paso 01).
SERVER_UUID=sn1cqhrng4mfpfp1ch2vevy3        # ovh-main
PROJECT_UUID=8qgzcg2rx6ld5qboxwttdbze       # Infraestructura personal
ENVIRONMENT_UUID=mfubcsqxxsugk0uutjz86ryi   # production
DESTINATION_UUID=masrbaubzcsmuhwnaqprhxiw   # infra-app-db: la misma red que la BD

[[ -s "$COMPOSE" ]] || { echo "No encuentro el compose en $COMPOSE" >&2; exit 1; }
[[ -s "$DIR/db-app.env" ]] || { echo "Falta $DIR/db-app.env (paso 02)" >&2; exit 1; }
touch "$DIR/app-secrets.env"
chmod 600 "$DIR/app-secrets.env"
if ! grep -q '^JWT_SECRET=' "$DIR/app-secrets.env"; then
    echo "JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')" >> "$DIR/app-secrets.env"
fi
grep -q '^DEEPSEEK_API_KEY=' "$DIR/app-secrets.env" || echo "Aviso: sin DEEPSEEK_API_KEY, la IA no funcionará." >&2

# Token temporal de la API (1 h), igual que en el paso 01; se revoca al terminar.
docker exec coolify php artisan tinker --execute='
$u = App\Models\User::find(0);
session(["currentTeam" => $u->teams()->first()]);
$t = $u->createToken("synaptixfit-deploy (temporal)", ["read", "write", "deploy"], now()->addHour());
echo "TOKEN=" . $t->plainTextToken . PHP_EOL;
' | sed -n 's/^TOKEN=//p' > "$TOKEN_FILE"
[[ -s "$TOKEN_FILE" ]] || { echo "No se pudo crear el token temporal" >&2; exit 1; }
revoke() {
    rm -f "$TOKEN_FILE" "${BODY:-}"
    docker exec coolify php artisan tinker --execute='
    Laravel\Sanctum\PersonalAccessToken::where("name", "synaptixfit-deploy (temporal)")->delete();' >/dev/null 2>&1 || true
}
trap revoke EXIT

call() {  # call METHOD PATH [FICHERO_JSON] → cuerpo de la respuesta; falla si no es 2xx
    local method=$1 path=$2 body=${3:-}
    local args=(-sS -o /tmp/coolify-resp.json -w '%{http_code}' -X "$method"
        -H "Authorization: Bearer $(cat "$TOKEN_FILE")" -H 'Accept: application/json')
    [[ -n "$body" ]] && args+=(-H 'Content-Type: application/json' --data-binary "@$body")
    local code
    code=$(curl "${args[@]}" "$API$path")
    if [[ "$code" != 2* ]]; then
        echo "Coolify respondió $code en $method $path:" >&2
        cat /tmp/coolify-resp.json >&2; echo >&2
        return 1
    fi
    cat /tmp/coolify-resp.json
}

BODY="$(mktemp)"
COMPOSE_B64="$(base64 -w0 "$COMPOSE")"

if [[ -s "$DIR/service-uuid" ]]; then
    UUID="$(cat "$DIR/service-uuid")"
    cat > "$BODY" <<JSON
{"docker_compose_raw": "$COMPOSE_B64", "urls": [{"name": "web", "url": "$DOMAIN"}], "connect_to_docker_network": true}
JSON
    call PATCH "/services/$UUID" "$BODY" >/dev/null
    echo "Servicio actualizado: $UUID"
else
    cat > "$BODY" <<JSON
{
  "name": "synaptixfit",
  "description": "SynaptixFit: backend Spring Boot + web Flutter (nginx). Imágenes de GHCR; ver docs/06-ops/deploy.md del repo.",
  "server_uuid": "$SERVER_UUID",
  "project_uuid": "$PROJECT_UUID",
  "environment_uuid": "$ENVIRONMENT_UUID",
  "destination_uuid": "$DESTINATION_UUID",
  "docker_compose_raw": "$COMPOSE_B64",
  "urls": [{"name": "web", "url": "$DOMAIN"}],
  "instant_deploy": false
}
JSON
    UUID="$(call POST /services "$BODY" | sed -n 's/.*"uuid":"\([^"]*\)".*/\1/p')"
    [[ -n "$UUID" ]] || { echo "No se obtuvo el uuid del servicio" >&2; exit 1; }
    echo "$UUID" > "$DIR/service-uuid"
    echo "Servicio creado: $UUID"
    # El POST no admite este campo: sin él, Coolify deja el servicio solo en su red propia y no
    # alcanza la BD (ni Traefik) de la red infra-app-db.
    echo '{"connect_to_docker_network": true}' > "$BODY"
    call PATCH "/services/$UUID" "$BODY" >/dev/null
fi

# Variables: las secretas se marcan «is_shown_once» (Coolify no vuelve a mostrarlas en la UI ni la API).
python3 - "$DIR/db-app.env" "$DIR/app-secrets.env" "$IMAGE_TAG" "$GOOGLE_CLIENT_IDS" > "$BODY" <<'PY'
import json, sys
def read(path):
    out = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out
secret_keys = {"DB_PASSWORD", "JWT_SECRET", "DEEPSEEK_API_KEY", "R2_ACCESS_KEY", "R2_SECRET_KEY"}
values = {**read(sys.argv[1]), **read(sys.argv[2])}
# Coolify crea las variables del compose vacías y una vacía anula el valor por defecto: sin token de
# R2 se manda un endpoint de relleno para que la app arranque (solo fallará la subida de archivos).
values.setdefault("R2_ENDPOINT", "https://r2-no-configurado.invalid")
values.update({"IMAGE_TAG": sys.argv[3], "GOOGLE_CLIENT_IDS": sys.argv[4],
               "CORS_ALLOWED_ORIGINS": "https://synaptixfit.jloenit.dev", "DEEPSEEK_MODEL": "deepseek-chat"})
data = [{"key": k, "value": v, "is_preview": False, "is_literal": True, "is_shown_once": k in secret_keys}
        for k, v in values.items() if v != ""]
json.dump({"data": data}, sys.stdout)
PY
call PATCH "/services/$UUID/envs/bulk" "$BODY" >/dev/null
echo "Variables de entorno aplicadas ($(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["data"]))' "$BODY"))."

# Parar y arrancar (no «restart»): solo el arranque reescribe el compose en disco con los cambios.
call POST "/services/$UUID/stop" >/dev/null 2>&1 || true
for _ in $(seq 1 60); do
    [[ -z "$(docker ps -q --filter "name=-$UUID")" ]] && break
    sleep 2
done
# Coolify tarda unos segundos en registrar la parada: si aún la cree en marcha, se reintenta.
for intento in 1 2 3 4 5; do
    call POST "/services/$UUID/start" >/dev/null 2>&1 && break
    [[ $intento -eq 5 ]] && call POST "/services/$UUID/start" >/dev/null
    sleep 10
done
echo "Despliegue lanzado con IMAGE_TAG=$IMAGE_TAG. Comprobar: sudo bash 08-verificar-synaptixfit.sh"
