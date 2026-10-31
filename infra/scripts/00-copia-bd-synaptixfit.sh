#!/usr/bin/env bash
# Copia de la BD de SynaptixFit antes de aplicar migraciones (solo root puede leerla).
#   sudo bash 00-copia-bd-synaptixfit.sh <prefijo>
set -euo pipefail
PREFIX="${1:-pre-deploy}"
F="/var/backups/synaptixfit-${PREFIX}-$(date +%Y%m%d-%H%M%S).sql.gz"
docker exec rnqvtuszzmxtfcb5ptvunlsp sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$F"
chmod 600 "$F"
ls -la "$F"
# pg_dump termina con «PostgreSQL database dump complete»: si falta, la copia está cortada.
if [ "$(gunzip -c "$F" | tail -c 300 | grep -c complete)" -lt 1 ]; then
  echo "Copia incompleta: $F" >&2
  exit 1
fi
echo "Copia correcta: $F"
