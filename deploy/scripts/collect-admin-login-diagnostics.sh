#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${1:-deploy/docker-compose.prod.contabo.yml}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[error] docker is not installed or not in PATH" >&2
  exit 1
fi

echo "== Compose services =="
docker compose -f "$COMPOSE_FILE" ps || true

echo
echo "== Backend/Website recent logs (last 200 lines each) =="
docker compose -f "$COMPOSE_FILE" logs --tail=200 backend website || true

echo
echo "== Laravel app env/config snapshot (sanitized) =="
docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
  php -v | head -n 1
  php artisan --version
  php artisan about --only=environment,cache,drivers || true
  php -r "echo \"APP_ENV=\".getenv(\"APP_ENV\").PHP_EOL;"
  php -r "echo \"APP_URL=\".getenv(\"APP_URL\").PHP_EOL;"
  php -r "echo \"SESSION_DRIVER=\".getenv(\"SESSION_DRIVER\").PHP_EOL;"
  php -r "echo \"SESSION_DOMAIN=\".(getenv(\"SESSION_DOMAIN\") ?: \"<null>\").PHP_EOL;"
  php -r "echo \"APP_KEY_SET=\".(getenv(\"APP_KEY\") ? \"yes\" : \"no\").PHP_EOL;"
' || true

echo
echo "== Laravel logs (last 200 lines) =="
docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
  if [ -f storage/logs/laravel.log ]; then
    tail -n 200 storage/logs/laravel.log
  else
    echo "storage/logs/laravel.log not found"
  fi
' || true

echo
echo "== Session path write test (for SESSION_DRIVER=file) =="
docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
  php -r "require \"vendor/autoload.php\"; \$app=require_once \"bootstrap/app.php\"; \$kernel=\$app->make(Illuminate\\Contracts\\Console\\Kernel::class); \$kernel->bootstrap(); echo config(\"session.driver\").PHP_EOL; echo config(\"session.files\").PHP_EOL;"
  test -w storage/framework/sessions && echo "sessions dir writable: yes" || echo "sessions dir writable: no"
  ls -ld storage storage/framework storage/framework/sessions
' || true

echo
echo "== Migrations status (high signal for login/runtime 500s) =="
docker compose -f "$COMPOSE_FILE" exec -T backend php artisan migrate:status --no-interaction || true

echo
echo "== Cache clear (safe) and config recache =="
docker compose -f "$COMPOSE_FILE" exec -T backend php artisan optimize:clear || true
docker compose -f "$COMPOSE_FILE" exec -T backend php artisan config:cache || true

echo
echo "== Done =="
echo "If login still fails, immediately rerun this script and share output + exact UTC timestamp of failed login attempt."
