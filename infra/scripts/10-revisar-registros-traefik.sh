#!/usr/bin/env bash
# Comprueba (solo lectura) si Traefik (coolify-proxy) guarda registros de acceso y si en ellos aparece la ruta
# del calendario suscrito, cuyo token es una credencial (ADR 0020). Nunca imprime líneas de registro: solo cuenta.
#
#   sudo bash 10-revisar-registros-traefik.sh
set -euo pipefail

PROXY_CONTAINER="${PROXY_CONTAINER:-coolify-proxy}"
PROXY_DIR="${PROXY_DIR:-/data/coolify/proxy}"
FEED='/api/v1/planner/calendar-feed/'

if ! docker inspect "$PROXY_CONTAINER" >/dev/null 2>&1; then
  echo "No existe el contenedor $PROXY_CONTAINER" >&2
  exit 1
fi

# Argumentos con los que arranca Traefik (Coolify los define en $PROXY_DIR/docker-compose.yml).
args=$(docker inspect -f '{{join .Config.Cmd " "}} {{join .Args " "}}' "$PROXY_CONTAINER")
if grep -qiE -- '--accesslog(=true)?( |$)|--accesslog\.' <<<"$args"; then
  echo "Registros de acceso: ACTIVADOS en los argumentos de Traefik"
  grep -oiE -- '--accesslog[^ ]*' <<<"$args" | sed 's/^/  /'
  enabled=1
else
  echo "Registros de acceso: no aparecen en los argumentos de Traefik"
  enabled=0
fi
if [ -d "$PROXY_DIR" ] && grep -rqiE 'accesslog|accessLog' "$PROXY_DIR" --include='*.yml' --include='*.yaml' --include='*.toml' 2>/dev/null; then
  echo "Configuración con accessLog en estos ficheros:"
  grep -rliE 'accesslog|accessLog' "$PROXY_DIR" --include='*.yml' --include='*.yaml' --include='*.toml' | sed 's/^/  /'
  enabled=1
fi

# ¿Aparece la ruta en lo que ya se ha registrado? (salida del contenedor y ficheros access*.log del proxy)
in_stdout=$(docker logs --since 720h "$PROXY_CONTAINER" 2>&1 | grep -c -- "$FEED" || true)
echo "Líneas con la ruta del calendario en la salida de Traefik (30 días): $in_stdout"
files=$(find "$PROXY_DIR" -maxdepth 3 -type f -iname '*access*.log*' 2>/dev/null || true)
if [ -n "$files" ]; then
  for f in $files; do
    n=$( (zgrep -c -- "$FEED" "$f" 2>/dev/null || grep -c -- "$FEED" "$f" 2>/dev/null) | head -1 || true)
    echo "  $f: ${n:-0} líneas con la ruta"
  done
fi

echo
if [ "$enabled" = 0 ] && [ "${in_stdout:-0}" = 0 ]; then
  echo "RESULTADO: Traefik no guarda la ruta del calendario. No hay nada que cambiar."
else
  echo "RESULTADO: revisar. Opciones (en Coolify › Servers › Proxy › Configuration):"
  echo "  a) quitar las líneas --accesslog* (Traefik deja de registrar accesos), o"
  echo "  b) dejarlas y añadir --accesslog.format=json y --accesslog.fields.names.RequestPath=drop"
  echo "     (y RequestLine si aparece), para que no se guarde la ruta."
  echo "  Después, «Restart Proxy» y volver a ejecutar este script."
fi
