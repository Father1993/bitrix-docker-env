#!/usr/bin/env bash
set -euo pipefail

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL is not detected. Windows CA install is not needed."
    exit 0
fi

if ! command -v mkcert >/dev/null 2>&1; then
    echo "mkcert is required. Install: https://github.com/FiloSottile/mkcert"
    exit 1
fi

ROOT_CA="$(mkcert -CAROOT)/rootCA.pem"
if [ ! -f "$ROOT_CA" ]; then
    echo "mkcert root CA not found. Run: make cert"
    exit 1
fi

CERTUTIL="/mnt/c/WINDOWS/system32/certutil.exe"
if [ ! -f "$CERTUTIL" ]; then
    echo "certutil.exe not found. Import this file into Windows Trusted Root (Current User):"
    echo "  $ROOT_CA"
    exit 1
fi

WIN_CA="$(wslpath -w "$ROOT_CA")"
echo "Installing mkcert root CA into Windows user trust store..."
"$CERTUTIL" -addstore -user Root "$WIN_CA"
echo "Done. Restart Chrome/Edge and open your site again."
