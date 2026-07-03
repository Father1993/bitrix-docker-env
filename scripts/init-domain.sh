#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

DOMAIN="${DOMAIN:-bitrix.local}"
CERT_DIR="docker/nginx/certs"
CERT_FILE="${CERT_DIR}/${DOMAIN}.pem"
KEY_FILE="${CERT_DIR}/${DOMAIN}-key.pem"

if ! command -v mkcert >/dev/null 2>&1; then
    echo "mkcert is required to generate local HTTPS certificates."
    echo "Install it from: https://github.com/FiloSottile/mkcert"
    exit 1
fi

mkdir -p "$CERT_DIR"

mkcert -install
mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" "$DOMAIN" "*.${DOMAIN}"

echo "Certificate generated:"
echo "  ${CERT_FILE}"
echo "  ${KEY_FILE}"

if [ -r /etc/hosts ] && awk -v domain="$DOMAIN" '
    $1 == "127.0.0.1" {
        for (i = 2; i <= NF; i++) {
            if (tolower($i) == tolower(domain)) found = 1
        }
    }
    END { exit found ? 0 : 1 }
' /etc/hosts; then
    echo "Hosts entry already exists for ${DOMAIN}."
else
    echo "Add this record to your hosts file if it is not present:"
    echo "  127.0.0.1 ${DOMAIN}"
    echo
    echo "Windows hosts file:"
    echo "  C:\\Windows\\System32\\drivers\\etc\\hosts"
    echo "Linux/macOS hosts file:"
    echo "  /etc/hosts"
fi
