ARG MYSQL_IMAGE=mysql:8.0.36
FROM ${MYSQL_IMAGE}

COPY my.cnf /etc/mysql/conf.d/bitrix.cnf
RUN chmod 644 /etc/mysql/conf.d/bitrix.cnf
