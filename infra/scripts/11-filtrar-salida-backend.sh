#!/usr/bin/env bash
# Filtra la salida del contenedor backend de SynaptixFit (ADR 0020, riesgo residual de DNS rebinding al
# descargar calendarios ICS): desde el backend solo se llega a Internet y a PostgreSQL de la red infra-app-db;
# el resto de redes privadas, el host y la IP de metadatos quedan rechazados.
#
# Las reglas van DENTRO del espacio de red del contenedor (nsenter), no en el cortafuegos del servidor: no
# afectan a otras apps y desaparecen al recrear el contenedor, así que hay que repetirlo tras cada despliegue.
#
#   sudo bash 11-filtrar-salida-backend.sh            # muestra lo que haría (no cambia nada)
#   sudo bash 11-filtrar-salida-backend.sh --aplicar  # aplica y comprueba
#   sudo bash 11-filtrar-salida-backend.sh --quitar   # vuelve a dejarlo sin filtro
set -euo pipefail

SERVICE="${SERVICE:-pexvidvkfdcvi2epndsd1zb9}"
DB_NETWORK="${DB_NETWORK:-infra-app-db}"
DB_CONTAINER="${DB_CONTAINER:-rnqvtuszzmxtfcb5ptvunlsp}"
CHAIN=SFX_EGRESS
MODE="${1:-}"
PRIVATE="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16 100.64.0.0/10 0.0.0.0/8 192.0.0.0/24 198.18.0.0/15 240.0.0.0/4"

backend=$(docker ps -q --filter "name=backend-${SERVICE}" | head -1)
[ -n "$backend" ] || { echo "No hay contenedor backend-${SERVICE} en marcha" >&2; exit 1; }
pid=$(docker inspect -f '{{.State.Pid}}' "$backend")
subnet=$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' "$DB_NETWORK" | awk '{print $1}')
db_ip=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$DB_NETWORK\").IPAddress}}" "$DB_CONTAINER")
[ -n "$subnet" ] && [ -n "$db_ip" ] || { echo "No se encontró la red $DB_NETWORK o la IP de la BD" >&2; exit 1; }
in_ns() { nsenter -t "$pid" -n "$@"; }

echo "Contenedor: $backend (pid $pid) · red de la BD: $subnet · BD: $db_ip"

remove() {
  while in_ns iptables -C OUTPUT -j "$CHAIN" 2>/dev/null; do in_ns iptables -D OUTPUT -j "$CHAIN"; done
  in_ns iptables -F "$CHAIN" 2>/dev/null || true
  in_ns iptables -X "$CHAIN" 2>/dev/null || true
}

rules() {
  echo "-A $CHAIN -o lo -j RETURN"
  echo "-A $CHAIN -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN"
  echo "-A $CHAIN -d $subnet -p tcp --dport 5432 -j RETURN"
  for net in $PRIVATE; do echo "-A $CHAIN -d $net -j REJECT"; done
}

case "$MODE" in
  --quitar)
    remove
    echo "Filtro quitado."
    ;;
  --aplicar)
    remove
    in_ns iptables -N "$CHAIN"
    rules | while read -r line; do in_ns iptables $line; done
    in_ns iptables -I OUTPUT 1 -j "$CHAIN"
    echo "Reglas aplicadas:"
    in_ns iptables -S "$CHAIN" | sed 's/^/  /'
    probe() { in_ns timeout 5 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null && echo abierto || echo cerrado; }
    db=$(probe "$db_ip" 5432); meta=$(probe 169.254.169.254 80); out=$(probe 1.1.1.1 443)
    echo "Comprobación: BD $db (debe estar abierto) · metadatos $meta (cerrado) · Internet $out (abierto)"
    if [ "$db" != abierto ] || [ "$out" != abierto ]; then
      echo "Algo necesario quedó cortado: se quita el filtro." >&2
      remove
      exit 1
    fi
    ;;
  *)
    echo "Modo de prueba: no se cambia nada. Se aplicarían estas reglas (con --aplicar):"
    rules | sed 's/^/  /'
    ;;
esac
