#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    source <(grep -vE '^(UID|GID)=' .env)
    set +a
fi

DOMAIN="${DOMAIN:-bitrix.local}"
STATUS=0

check_command() {
    local name="$1"
    local hint="$2"

    if command -v "$name" >/dev/null 2>&1; then
        echo "OK: $name"
    else
        echo "Missing: $name"
        echo "  $hint"
        STATUS=1
    fi
}

check_command docker "Install Docker Desktop or Docker Engine with Compose v2."

if docker compose version >/dev/null 2>&1; then
    echo "OK: docker compose"
else
    echo "Missing: docker compose"
    echo "  Install Docker Compose v2."
    STATUS=1
fi

if command -v mkcert >/dev/null 2>&1; then
    echo "OK: mkcert"
else
    echo "Warning: mkcert is not installed. HTTPS certificates will not be generated."
    echo "  Install mkcert: https://github.com/FiloSottile/mkcert"
fi

if [ -f .env ]; then
    echo "OK: .env"
else
    echo "Warning: .env is missing. Run: cp .env.example .env"
fi

echo "Configured domain: ${DOMAIN}"

if [ -r /etc/hosts ] && awk -v domain="$DOMAIN" '
    $1 == "127.0.0.1" {
        for (i = 2; i <= NF; i++) {
            if (tolower($i) == tolower(domain)) found = 1
        }
    }
    END { exit found ? 0 : 1 }
' /etc/hosts; then
    echo "OK: hosts entry for ${DOMAIN}"
else
    echo "Reminder: add this hosts entry manually if the domain does not resolve:"
    echo "  127.0.0.1 ${DOMAIN}"
fi

case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux|Darwin)
        echo "Current UID/GID: $(id -u)/$(id -g)"
        echo "Use these values in .env if file permissions are wrong."
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows detected. Edit hosts as Administrator:"
        echo "  C:\\Windows\\System32\\drivers\\etc\\hosts"
        ;;
esac

PHP_EXTRA_EXTENSIONS="${PHP_EXTRA_EXTENSIONS:-}"
XDEBUG_MODE="${XDEBUG_MODE:-off}"
if [[ " ${PHP_EXTRA_EXTENSIONS} " == *" xdebug "* ]] && [ "$XDEBUG_MODE" = "off" ]; then
    echo "Warning: xdebug is in PHP_EXTRA_EXTENSIONS but XDEBUG_MODE=off."
    echo "  Set XDEBUG_MODE=debug in .env and rebuild: docker compose build php"
fi

exit "$STATUS"
