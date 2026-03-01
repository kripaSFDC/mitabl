FROM nginx:1.27-alpine

<<<<<<< Updated upstream
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public/ /usr/share/nginx/html/
=======
RUN apt-get update && apt-get install -y unzip git curl libonig-dev libzip-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo pdo_mysql mbstring bcmath pcntl zip intl && docker-php-ext-enable pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- \
     --install-dir=/usr/local/bin --filename=composer

WORKDIR /app
COPY . .
>>>>>>> Stashed changes

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
