#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="deploy/docker-compose.prod.contabo.yml"
REPAIR_MODE="false"

usage() {
  cat <<USAGE
Usage:
  bash deploy/scripts/collect-admin-login-diagnostics.sh [--compose-file <path>] [--repair]

Options:
  --compose-file <path>  Docker compose file to use (default: deploy/docker-compose.prod.contabo.yml)
  --repair               Run optional repair actions (optimize:clear, config:cache, migrate --force, service restart)
  -h, --help             Show this help

Notes:
  - Default mode is read-only diagnostics.
  - Use --repair only after reviewing diagnostics output.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --compose-file)
      COMPOSE_FILE="${2:-}"
      shift 2
      ;;
    --repair)
      REPAIR_MODE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[error] Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "[error] docker is not installed or not in PATH" >&2
  exit 1
fi

echo "== Compose services =="
docker compose -f "$COMPOSE_FILE" ps || true

echo
echo "== Health checks from host =="
curl -sS -o /tmp/mitabl_backend_health.txt -w "backend /api/health/live => HTTP %{http_code}\n" http://127.0.0.1:8000/api/health/live || true
curl -sS -o /tmp/mitabl_website_health.txt -w "website /health => HTTP %{http_code}\n" http://127.0.0.1:8080/health || true

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

if [ "$REPAIR_MODE" = "true" ]; then
  echo
  echo "== Optional repair actions (--repair enabled) =="
  docker compose -f "$COMPOSE_FILE" exec -T backend php artisan optimize:clear || true
  docker compose -f "$COMPOSE_FILE" exec -T backend php artisan config:cache || true
  docker compose -f "$COMPOSE_FILE" exec -T backend php artisan migrate --force || true
  docker compose -f "$COMPOSE_FILE" restart backend website || true
else
  echo
  echo "== Repair actions skipped (default read-only mode) =="
  echo "To run repair actions, execute:"
  echo "  bash deploy/scripts/collect-admin-login-diagnostics.sh --repair"
fi

echo
echo "== Done =="
echo "If login still fails, rerun this script immediately after one failed login and share output + exact UTC timestamp."
