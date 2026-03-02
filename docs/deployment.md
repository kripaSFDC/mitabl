# Deployment Guide

Canonical Docker runbook with exactly two supported stacks:
- Windows Docker test stack: `docker-compose.yml`
- Contabo Linux production stack: `deploy/docker-compose.prod.contabo.yml`

## 1) Windows Docker test stack

Compose file: `docker-compose.yml`

Services included:
- `db` (MySQL 8.0)
- `redis` (Redis `7.2-alpine`)
- `backend` (Laravel PHP-FPM app runtime)
- `backend-web` (Nginx ingress for API/admin)
- `website` (marketing site)

Start:
```bash
docker compose up --build -d
```

Stop:
```bash
docker compose down
```

## 2) Contabo Linux production stack

Compose file: `deploy/docker-compose.prod.contabo.yml`

Services included:
- `db` (MySQL 8.0)
- `redis` (Redis `7.2-alpine`)
- `backend-api` (Laravel PHP-FPM app runtime)
- `backend-web` (Nginx ingress for API)
- `ops-admin` (admin app endpoint)
- `queue-worker` (Horizon)
- `marketing-web` (website)

Start:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```

Stop:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml down
```

## 3) Boot automation and initial data load

Boot automation is controlled by these env params:
- `RUN_MIGRATIONS_ON_BOOT`
- `RUN_SEEDERS_ON_BOOT`

Both are read by `backend/start-server.sh`.

For first production boot (fresh DB):
1. Set in `deploy/environments/prod/backend-api.env`:
   - `RUN_MIGRATIONS_ON_BOOT=true`
   - `RUN_SEEDERS_ON_BOOT=true`
2. Start production stack:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```
3. After first successful initialization, set both back to `false` and restart:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up -d
```

For routine restarts/upgrades, keep both flags `false`.

## 4) Environment templates

Production app env files:
- `deploy/environments/prod/backend-api.env`
- `deploy/environments/prod/ops-admin.env`

Current production templates use internal Docker DB host:
- `DB_HOST=db`

They do not force an external DB host placeholder.

## 5) Health verification

Windows test:
```bash
docker compose ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8080/health
```

Contabo production:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8001/api/health/live
curl -fsS http://localhost:8080/health
```

## 6) Troubleshooting

- If DB initialization fails, check `db` logs first:
  - `docker compose -f deploy/docker-compose.prod.contabo.yml logs db`
- If API fails readiness, verify DB/Redis env values and app keys:
  - `docker compose -f deploy/docker-compose.prod.contabo.yml logs backend-api`
- If queue is unhealthy, inspect Horizon logs:
  - `docker compose -f deploy/docker-compose.prod.contabo.yml logs queue-worker`
