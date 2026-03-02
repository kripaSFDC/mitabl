#!/bin/sh
set -eu

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
fi

if [ -f ".env" ]; then
  if ! grep -Eq '^APP_KEY=.+$' .env; then
    php artisan key:generate --force --no-interaction
  fi

  if ! grep -Eq '^JWT_SECRET=.+$' .env; then
    php artisan jwt:secret --force --no-interaction
  fi
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

php \
  -d opcache.enable=1 \
  -d opcache.enable_cli=1 \
  -d opcache.validate_timestamps=1 \
  -d opcache.revalidate_freq=2 \
  -d realpath_cache_size=4096K \
  -d realpath_cache_ttl=600 \
  -S 0.0.0.0:8000 -t public server.php
