#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

DOMAIN="${DOMAIN:-bitrix.local}"
MYSQL_DATABASE="${MYSQL_DATABASE:-bitrix}"
MYSQL_USER="${MYSQL_USER:-bitrix}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-bitrix}"

if [ ! -d www ]; then
    echo "Missing www directory."
    exit 1
fi

if [ ! -s www/restore.php ]; then
    echo "Missing www/restore.php. Run: make restore"
    exit 1
fi

shopt -s nullglob nocaseglob
archives=(www/*.tar www/*.tar.gz www/*.tgz www/*.tar.bz2 www/*.tar.xz www/*.zip)
shopt -u nocaseglob

if [ "${#archives[@]}" -eq 0 ]; then
    echo "No Bitrix backup archive found in ./www."
    echo "Put a backup archive into ./www before opening restore.php."
    exit 1
fi

echo "Restore entrypoint is ready:"
echo "  https://${DOMAIN}/restore.php"
echo
echo "Use these database settings in the Bitrix restore wizard:"
echo "  Host: mysql"
echo "  Database: ${MYSQL_DATABASE}"
echo "  User: ${MYSQL_USER}"
echo "  Password: ${MYSQL_PASSWORD}"
echo
echo "Backup archives found:"
printf "  %s\n" "${archives[@]}"
echo
echo "After restore, delete restore.php and backup archives from ./www."
