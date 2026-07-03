#!/bin/bash
set -e

if [ -n "${TZ:-}" ]; then
    printf 'date.timezone = %s\n' "$TZ" > /usr/local/etc/php/conf.d/98-timezone.ini
fi

exec docker-php-entrypoint "$@"
