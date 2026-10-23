#!/usr/bin/env bash
# Guarda (o sustituye) líneas CLAVE=valor leídas por la entrada estándar en
# /root/synaptixfit/app-secrets.env (root, 600). Nunca recibe secretos por argumentos, así que no
# aparecen en la lista de procesos ni en el historial.
#
#   grep '^DEEPSEEK_API_KEY=' backend/.env | ssh infra-ovh 'sudo bash /tmp/guardar-secreto.sh'
set -euo pipefail
umask 077
FILE=/root/synaptixfit/app-secrets.env
mkdir -p "$(dirname "$FILE")"
touch "$FILE"
NEW="$(mktemp)"
trap 'rm -f "$NEW"' EXIT
tr -d '\r' > "$NEW"
grep -qE '^[A-Z0-9_]+=.+' "$NEW" || { echo "No llegó ninguna línea CLAVE=valor" >&2; exit 1; }
cut -d= -f1 "$NEW" | while read -r key; do
    sed -i "/^${key}=/d" "$FILE"
done
cat "$NEW" >> "$FILE"
chmod 600 "$FILE"
echo "Guardadas: $(cut -d= -f1 "$NEW" | tr '\n' ' ')"
