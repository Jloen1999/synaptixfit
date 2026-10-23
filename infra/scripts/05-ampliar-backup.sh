#!/usr/bin/env bash
# Amplía la copia diaria (infra-backup.sh) y la verificación de restauración
# (infra-restore-check.sh) para incluir TODOS los recursos PostgreSQL standalone de
# Coolify (hoy: synaptixfit-db). Idempotente; guarda copia fechada de cada script.
#
#   sudo bash 05-ampliar-backup.sh /tmp/bloque-backup.sh /tmp/bloque-restore.sh
#
# Los dos bloques se insertan:
#   - en infra-backup.sh, justo antes de la validación de volcados (MINIMO_VOLCADO=);
#   - en infra-restore-check.sh, justo antes del mensaje final de verificación.
set -euo pipefail

BLOQUE_BK="${1:?bloque para infra-backup.sh}"
BLOQUE_RC="${2:?bloque para infra-restore-check.sh}"
BK=/usr/local/sbin/infra-backup.sh
RC=/usr/local/sbin/infra-restore-check.sh
STAMP="$(date +%Y%m%d-%H%M%S)"
MARCA='# >>> volcados PostgreSQL de apps (Coolify standalone-postgresql)'

insertar() {
    local destino="$1" bloque="$2" patron="$3"
    if grep -qF "$MARCA" "$destino"; then
        echo "$destino ya incluía los volcados PostgreSQL de apps"
        return 0
    fi
    cp -p "$destino" "$destino.bak-$STAMP"
    awk -v bloque="$bloque" -v patron="$patron" '
        index($0, patron) == 1 && !hecho { while ((getline l < bloque) > 0) print l; print ""; hecho = 1 }
        { print }' "$destino" > "$destino.nuevo"
    grep -qF "$MARCA" "$destino.nuevo" \
        || { echo "No se encontró el punto de inserción en $destino" >&2; rm -f "$destino.nuevo"; exit 1; }
    bash -n "$destino.nuevo"
    install -m "$(stat -c %a "$destino")" -o root -g root "$destino.nuevo" "$destino"
    rm -f "$destino.nuevo"
    echo "$destino ampliado (copia: $destino.bak-$STAMP)"
}

insertar "$BK" "$BLOQUE_BK" 'MINIMO_VOLCADO='
insertar "$RC" "$BLOQUE_RC" 'echo "=== Verificacion completada ==="'
