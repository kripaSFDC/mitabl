#!/bin/sh
set -eu

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
fi

if [ -f ".env" ]; then
  app_key_value="$(grep -E '^APP_KEY=' .env | head -n1 | cut -d '=' -f2- | tr -d '\r')"
  if [ -z "$app_key_value" ]; then
    php artisan key:generate --force --no-interaction
  fi

  jwt_secret_value="$(grep -E '^JWT_SECRET=' .env | head -n1 | cut -d '=' -f2- | tr -d '\r')"
  if [ -z "$jwt_secret_value" ]; then
    php artisan jwt:secret --force --no-interaction
  fi

  php artisan config:clear --no-interaction
fi

if [ "${RUN_MIGRATIONS_ON_BOOT:-false}" = "true" ]; then
  php artisan migrate --force
fi

if [ "${RUN_SEEDERS_ON_BOOT:-false}" = "true" ]; then
  php artisan db:seed --force
fi

if [ ! -f "public/css/filament/filament/app.css" ] || [ ! -f "public/js/filament/filament/app.js" ]; then
  php artisan filament:assets --ansi
fi

chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rw storage bootstrap/cache

exec php-fpm -F
