FROM composer:2 AS vendor

WORKDIR /app
COPY . .

RUN composer install \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --no-dev \
    --ignore-platform-req=ext-intl \
    --ignore-platform-req=ext-pcntl \
    --optimize-autoloader \
    && composer clear-cache

FROM php:8.2-fpm AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libonig-dev \
        libzip-dev \
        libicu-dev \
        unzip \
    && docker-php-ext-install mysqli pdo pdo_mysql mbstring bcmath pcntl zip intl \
    && pecl install redis \
    && docker-php-ext-enable pdo_mysql redis \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

COPY php.ini /usr/local/etc/php/

WORKDIR /app
COPY --from=vendor /app /app

RUN mkdir -p storage/framework/views storage/framework/cache storage/framework/sessions storage/logs bootstrap/cache

EXPOSE 8000

RUN php --ini

# TODO serve with Nginx instead
CMD ["sh","start-server.sh"]
