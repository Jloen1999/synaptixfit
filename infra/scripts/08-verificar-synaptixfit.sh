#!/usr/bin/env bash
# Comprobaciones de solo lectura del despliegue de SynaptixFit en el VPS.
#
#   sudo bash 08-verificar-synaptixfit.sh
set -uo pipefail

HOST=synaptixfit.jloenit.dev
UUID="$(cat /root/synaptixfit/service-uuid 2>/dev/null || true)"
ok=0; ko=0
check() { if eval "$2" >/dev/null 2>&1; then echo "  OK    $1"; ok=$((ok+1)); else echo "  FALLA $1"; ko=$((ko+1)); fi; }

echo "Contenedores del servicio ${UUID:-?}:"
docker ps --filter "name=${UUID:-synaptixfit}" --format '  {{.Names}}\t{{.Image}}\t{{.Status}}'

check "backend sano" "docker ps --filter name=backend-$UUID --format '{{.Status}}' | grep -q healthy"
check "web sana" "docker ps --filter name=web-$UUID --format '{{.Status}}' | grep -q healthy"
# A través de Traefik, como llegaría Cloudflare (certificado de origen + Host correcto).
check "HTTPS por Traefik responde la web" \
    "curl -fsSk --resolve $HOST:443:127.0.0.1 https://$HOST/ | grep -qi '<html'"
check "certificado de origen de Cloudflare en Traefik" \
    "echo | openssl s_client -connect 127.0.0.1:443 -servername $HOST 2>/dev/null | openssl x509 -noout -issuer | grep -qi cloudflare"
check "/api llega al backend (login con datos falsos → 401)" \
    "[ \"\$(curl -sk -o /dev/null -w '%{http_code}' --resolve $HOST:443:127.0.0.1 -H 'Content-Type: application/json' \
        -d '{\"email\":\"nadie@example.com\",\"password\":\"x1234567\"}' https://$HOST/api/v1/auth/login)\" = 401 ]"
check "el backend no publica puertos en el host" \
    "[ -z \"\$(docker port backend-$UUID 2>/dev/null)\" ]"
check "la BD sigue sin puerto público" "! ss -ltn | grep -q ':5432 '"

echo "Resultado: $ok correctas, $ko fallos"
[[ $ko -eq 0 ]]
