#!/usr/bin/env bash
# Instala en Traefik (coolify-proxy) el certificado de origen de Cloudflare *.jloenit.dev como
# certificado por defecto. Cloudflare está en modo Full (strict): sin un certificado válido en el
# origen, cualquier app de Coolify bajo jloenit.dev daría 526. Let's Encrypt no sirve aquí (el 80
# está cerrado y solo entran los rangos de Cloudflare al 443).
#
# Se ejecuta EN el VPS con sudo. Reutiliza el certificado que ya usa Infra Manager (no genera nada).
#
#   sudo bash 06-certificado-origen-traefik.sh
set -euo pipefail
umask 077

SRC=/etc/ssl/private/infra-manager
PROXY=/data/coolify/proxy
CERTS="$PROXY/certs"
DYNAMIC="$PROXY/dynamic/cloudflare-origin.yaml"

[[ -s "$SRC/origin.pem" && -s "$SRC/origin.key" ]] || { echo "Falta el certificado de origen en $SRC" >&2; exit 1; }

mkdir -p "$CERTS"
chmod 700 "$CERTS"
install -m 600 "$SRC/origin.pem" "$CERTS/jloenit-origin.pem"
install -m 600 "$SRC/origin.key" "$CERTS/jloenit-origin.key"

# Traefik monta $PROXY en /traefik y vigila /traefik/dynamic: no hace falta reiniciarlo.
cat > "$DYNAMIC" <<'YAML'
# Certificado de origen de Cloudflare (*.jloenit.dev, 15 años) para las apps de Coolify.
# Lo instala infra/scripts/06-certificado-origen-traefik.sh del repo de SynaptixFit.
tls:
  certificates:
    - certFile: /traefik/certs/jloenit-origin.pem
      keyFile: /traefik/certs/jloenit-origin.key
  stores:
    default:
      defaultCertificate:
        certFile: /traefik/certs/jloenit-origin.pem
        keyFile: /traefik/certs/jloenit-origin.key
YAML
chmod 644 "$DYNAMIC"

sleep 3
SUBJECT="$(echo | openssl s_client -connect 127.0.0.1:443 -servername comprobacion.jloenit.dev 2>/dev/null \
    | openssl x509 -noout -subject -enddate 2>/dev/null || true)"
echo "Certificado que sirve Traefik ahora:"
echo "${SUBJECT:-  (no se pudo leer)}"
