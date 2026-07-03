#!/usr/bin/env bash
set -euo pipefail

RESTORE_URL="https://www.1c-bitrix.ru/download/scripts/restore.php"
RESTORE_FILE="www/restore.php"

patch_restore_php() {
    if grep -q 'ini_get("max_execution_time")' "$RESTORE_FILE"; then
        return 0
    fi
    sed -i.bak 's/define("STEP_TIME", defined('\''VMBITRIX'\'') ? 30 : 15);/define("STEP_TIME", (int) ini_get("max_execution_time") ?: 3600);/' "$RESTORE_FILE"
    rm -f "${RESTORE_FILE}.bak"
    echo "Patched STEP_TIME in ${RESTORE_FILE}"
}

mkdir -p www

if [ -s "$RESTORE_FILE" ]; then
    patch_restore_php
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

patch_restore_php
echo "Downloaded: ${RESTORE_FILE}"
