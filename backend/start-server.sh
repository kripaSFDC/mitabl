#!/bin/sh
set -eu

set_env_var() {
  key="$1"
  value="$2"
  if grep -q "^${key}=" .env 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '%s=%s\n' "$key" "$value" >> .env
  fi
}

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
fi

if [ -f ".env" ]; then
  # Keep .env in sync with container-provided secrets when present.
  if [ -n "${APP_KEY:-}" ]; then
    set_env_var "APP_KEY" "$APP_KEY"
  fi
  if [ -n "${JWT_SECRET:-}" ]; then
    set_env_var "JWT_SECRET" "$JWT_SECRET"
  fi

  app_key_value="$(grep -E '^APP_KEY=' .env | head -n1 | cut -d '=' -f2- | tr -d '\r')"
  if [ -z "$app_key_value" ]; then
    generated_app_key="$(php artisan key:generate --show --no-interaction | tr -d '\r\n')"
    if [ -n "$generated_app_key" ]; then
      set_env_var "APP_KEY" "$generated_app_key"
    fi
  fi

  jwt_secret_value="$(grep -E '^JWT_SECRET=' .env | head -n1 | cut -d '=' -f2- | tr -d '\r')"
  if [ -z "$jwt_secret_value" ]; then
    set_env_var "JWT_SECRET" ""
    php artisan jwt:secret --force --no-interaction
  fi

  php artisan config:clear --no-interaction
fi

if [ "${RUN_MIGRATIONS_ON_BOOT:-false}" = "true" ]; then
  php artisan migrate --force
fi

# Always run minimal idempotent bootstrap data repair for deployment safety.
php artisan db:seed --class=DeploymentBootstrapSeeder --force

if [ "${RUN_SEEDERS_ON_BOOT:-false}" = "true" ]; then
  php artisan db:seed --force
fi

if [ ! -f "public/css/filament/filament/app.css" ] || [ ! -f "public/js/filament/filament/app.js" ]; then
  php artisan filament:assets --ansi
fi

chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rw storage bootstrap/cache

php-fpm -D
exec nginx -g "daemon off;"
