FROM php:8.2-fpm

RUN apt-get update && apt-get install -y unzip nodejs npm git curl libonig-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo pdo_mysql mbstring bcmath pcntl zip && docker-php-ext-enable pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- \
     --install-dir=/usr/local/bin --filename=composer

COPY php.ini /usr/local/etc/php/

WORKDIR /app
COPY . .

EXPOSE 8000

RUN composer install --no-interaction --prefer-dist --optimize-autoloader && npm install

RUN php --ini

# TODO serve with Nginx instead
CMD ["sh","start-server.sh"]
