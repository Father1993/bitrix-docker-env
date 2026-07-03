ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-bookworm

ARG UID=1000
ARG GID=1000
ARG PHP_EXTRA_EXTENSIONS=""

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        default-mysql-client \
        git \
        less \
        procps \
        unzip \
        zip; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL https://github.com/mlocati/docker-php-extension-installer/releases/download/2.11.12/install-php-extensions \
        -o /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    IPE_GD_WITHOUTAVIF=1 install-php-extensions \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        soap \
        zip \
        ${PHP_EXTRA_EXTENSIONS}

RUN set -eux; \
    groupadd --gid "${GID}" bitrix; \
    useradd --uid "${UID}" --gid bitrix --home-dir /home/bitrix --create-home --shell /bin/bash bitrix; \
    mkdir -p /var/www/html; \
    chown -R bitrix:bitrix /var/www /home/bitrix; \
    sed -ri 's/^user = .*/user = bitrix/' /usr/local/etc/php-fpm.d/www.conf; \
    sed -ri 's/^group = .*/group = bitrix/' /usr/local/etc/php-fpm.d/www.conf

COPY php.ini /usr/local/etc/php/conf.d/99-bitrix.ini
COPY opcache.ini /usr/local/etc/php/conf.d/99-opcache.ini
COPY docker-entrypoint.sh /usr/local/bin/bitrix-entrypoint.sh
RUN chmod +x /usr/local/bin/bitrix-entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["bitrix-entrypoint.sh"]
CMD ["php-fpm"]
