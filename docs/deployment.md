# Deployment Guide

This is the canonical deployment runbook for Docker-based environments.

## 1) Supported compose stacks

### Local full-stack (`docker-compose.yml`)
Services:
- `db` (MySQL)
- `db-migrate` (one-off migrations + optional seeding)
- `backend` (Laravel API + admin)
- `website` (Nginx static site)
- `mobile-app` (optional dev-tools container, profile `mobile-devtools`)

Start:
```bash
docker compose up --build -d
```

If you need the mobile build tools container:
```bash
docker compose --profile mobile-devtools up --build -d mobile-app
```

### Phase0 stack (`deploy/docker-compose.phase0.yml`)
Services:
- `db` (MySQL)
- `db-migrate`
- `backend-api`
- `ops-admin`
- `queue-worker`
- `marketing-web`
- `redis`

Start:
```bash
docker compose -f deploy/docker-compose.phase0.yml up --build -d
```

## 2) Environment templates

Use these backend env templates only:
- `backend/.env.example` → production-like template
- `backend/.env.text` → test deployment template

Create runtime env:
```bash
cp backend/.env.example backend/.env
```

## 3) Platform-managed (non-env) settings

The following are no longer managed as env variables and must be changed via Platform Settings (super admin/platform admin only):
- Support SLA and ticket policy controls
- Admin reauth policy
- Session lifetime/expire-on-close policy
- Stripe runtime integration controls (`stripe.*`, dashboard URL)

## 4) First boot / bootstrap

```bash
docker compose exec backend php artisan key:generate --force
docker compose exec backend php artisan jwt:secret --force
```

`db-migrate` already runs migrations at startup. Seeders can be enabled with:
- `RUN_SEEDERS_ON_BOOT=true`

## 5) Health verification

```bash
docker compose ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8000/api/health/ready
curl -fsS http://localhost:8080/health
```

Phase0:
```bash
docker compose -f deploy/docker-compose.phase0.yml ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8001/api/health/live
curl -fsS http://localhost:8080/health
```

## 6) Troubleshooting

- If `db-migrate` fails, inspect logs and rerun after DB is healthy:
```bash
docker compose logs db-migrate
```
- If API fails boot, verify `APP_KEY`, `JWT_SECRET`, DB/Redis connectivity.
- If queue is unhealthy in phase0, verify Redis health and Horizon process logs.
