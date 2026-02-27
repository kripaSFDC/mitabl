FROM php:7.4-fpm

RUN apt-get update && apt-get install -y unzip nodejs npm

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- \
     --install-dir=/usr/local/bin --filename=composer

COPY php.ini /usr/local/etc/php/

WORKDIR /app
COPY . .

EXPOSE 8000

RUN composer update && npm install
RUN cp .env.aws .env

RUN php --ini

# TODO serve with Nginx instead
CMD ["sh","start-server.sh"]
