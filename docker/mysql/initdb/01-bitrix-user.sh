#!/usr/bin/env bash
set -euo pipefail

sql_string() {
    printf "%s" "$1" | sed "s/'/''/g"
}

sql_ident() {
    printf "%s" "$1" | sed 's/`/``/g'
}

BITRIX_DB="$(sql_ident "${MYSQL_DATABASE:-bitrix}")"
BITRIX_USER="$(sql_string "${MYSQL_USER:-bitrix}")"
BITRIX_PASSWORD="$(sql_string "${MYSQL_PASSWORD:-bitrix}")"

echo "Configuring Bitrix MySQL user '${MYSQL_USER:-bitrix}'..."

if docker_process_sql --database=mysql -N -B -e "SELECT PLUGIN_NAME FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME = 'mysql_native_password' AND PLUGIN_STATUS = 'ACTIVE';" | grep -q '^mysql_native_password$'; then
    docker_process_sql --database=mysql <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${BITRIX_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${BITRIX_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${BITRIX_PASSWORD}';
        ALTER USER '${BITRIX_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${BITRIX_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${BITRIX_DB}\`.* TO '${BITRIX_USER}'@'%';
        GRANT SESSION_VARIABLES_ADMIN ON *.* TO '${BITRIX_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL
else
    echo "mysql_native_password plugin is not active; using MySQL default authentication for Bitrix user."
    docker_process_sql --database=mysql <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${BITRIX_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${BITRIX_USER}'@'%' IDENTIFIED BY '${BITRIX_PASSWORD}';
        ALTER USER '${BITRIX_USER}'@'%' IDENTIFIED BY '${BITRIX_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${BITRIX_DB}\`.* TO '${BITRIX_USER}'@'%';
        GRANT SESSION_VARIABLES_ADMIN ON *.* TO '${BITRIX_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL
fi
