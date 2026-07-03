#!/usr/bin/env bash
set -euo pipefail

RESTORE_URL="https://www.1c-bitrix.ru/download/scripts/restore.php"
RESTORE_FILE="www/restore.php"

mkdir -p www

if [ -s "$RESTORE_FILE" ]; then
    echo "restore.php already exists: ${RESTORE_FILE}"
    exit 0
fi

echo "Downloading restore.php..."

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RESTORE_URL" -o "$RESTORE_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$RESTORE_FILE" "$RESTORE_URL"
else
    echo "curl or wget is required to download restore.php."
    exit 1
fi

echo "Downloaded: ${RESTORE_FILE}"
