# Deployment Guide

Canonical Docker runbook with explicit stacks for Windows test and Contabo Linux production.

## 1) Compose files to use

### Windows test stack
File: `deploy/docker-compose.test.windows.yml`

Services:
- `db` (MySQL)
- `redis` (Redis `7.2-alpine`)
- `backend` (Laravel app)
- `backend-web` (Nginx for API)
- `website` (marketing site)

Start:
```bash
docker compose -f deploy/docker-compose.test.windows.yml up --build -d
```

Stop:
```bash
docker compose -f deploy/docker-compose.test.windows.yml down
```

### Contabo Linux production stack
File: `deploy/docker-compose.prod.contabo.yml`

Services:
- `backend-api`
- `ops-admin`
- `queue-worker`
- `marketing-web`
- `redis` (Redis `7.2-alpine`)

Important:
- This production stack does **not** create MySQL.
- Use external/managed DB and set DB values in `deploy/environments/prod/*.env`.

Start:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```

Stop:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml down
```

### Legacy compatibility file
`deploy/docker-compose.architecture.yml` is kept only for backward compatibility. Use `deploy/docker-compose.prod.contabo.yml` for production going forward.

## 2) Environment files

Production env files:
- `deploy/environments/prod/backend-api.env`
- `deploy/environments/prod/ops-admin.env`

Backend app env template:
- `backend/.env.example`

## 3) First boot / bootstrap

For the Windows test stack:
```bash
docker compose -f deploy/docker-compose.test.windows.yml exec backend php artisan key:generate --force
docker compose -f deploy/docker-compose.test.windows.yml exec backend php artisan jwt:secret --force
```

For the Contabo production stack:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml exec backend-api php artisan key:generate --force
docker compose -f deploy/docker-compose.prod.contabo.yml exec backend-api php artisan jwt:secret --force
```

## 4) Health verification

Windows test:
```bash
docker compose -f deploy/docker-compose.test.windows.yml ps
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

## 5) Troubleshooting

- If migrations fail on startup, verify DB connectivity first, then check logs.
- If API fails boot, verify `APP_KEY`, `JWT_SECRET`, DB/Redis settings.
- If queue is unhealthy, verify Redis health and Horizon process logs.
