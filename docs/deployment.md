# Deployment Guide

Canonical Docker runbook with two supported stacks:
- Windows test stack: `deploy/docker-compose.test.windows.yml` (extends root compose)
- Contabo Linux production stack: `deploy/docker-compose.prod.contabo.yml`

Both stacks run all required application capabilities:
- `backend` (API + admin surface)
- `queue-worker` (Horizon queue processing)
- `scheduler` (Laravel scheduled jobs)
- `website` (public site and reverse-proxy routes)
- `db` (MySQL 8.0)
- `redis` (Redis 7.2)

## 1) Prerequisites

Windows (test):
- Docker Desktop with Linux containers enabled
- Docker Compose v2 (`docker compose version`)
- Git

Contabo Linux (production):
- Docker Engine 24+ and Compose plugin v2
- Git
- Open firewall ports: `8000` (API/admin), `8080` (website), optional `3306` and `6379` if external access is needed

## 2) Required env files

Windows test backend env:
- `deploy/environments/dev/backend-api.env`

Production backend env:
- `deploy/environments/prod/backend-api.env`

Required values for production before first boot:
- `APP_KEY` (valid Laravel key, format `base64:...`)
- `JWT_SECRET`
- `DB_ROOT_PASSWORD` (set in shell environment or `.env` in repo root)
- `ADMIN_BOOTSTRAP_EMAIL` (only for first prod bootstrap when seeding)
- `ADMIN_BOOTSTRAP_PASSWORD` (only for first prod bootstrap when seeding)

`DB_HOST` is internal Docker host in all deployment env templates:
- `DB_HOST=db`

## 3) Generate production secrets

Generate `APP_KEY` and `JWT_SECRET` directly on host shell (no Docker required).

Bash:
```bash
APP_KEY="base64:$(openssl rand -base64 32)"
JWT_SECRET="$(openssl rand -hex 32)"
printf 'APP_KEY=%s\nJWT_SECRET=%s\n' "$APP_KEY" "$JWT_SECRET"
```

PowerShell:
```powershell
$appKey = "base64:" + [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
$jwtSecret = -join ((1..64) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) })
Write-Output "APP_KEY=$appKey"
Write-Output "JWT_SECRET=$jwtSecret"
```

Paste generated values into `deploy/environments/prod/backend-api.env`.

Set DB root password in shell before `up`:
```bash
export DB_ROOT_PASSWORD='replace_with_strong_password'
```

PowerShell:
```powershell
$env:DB_ROOT_PASSWORD='replace_with_strong_password'
```

## 4) Windows test deployment

Start:
```bash
docker compose -f deploy/docker-compose.test.windows.yml up --build -d
```

Equivalent shortcut:
```bash
docker compose up --build -d
```

Stop:
```bash
docker compose -f deploy/docker-compose.test.windows.yml down
```

## 5) Contabo production deployment

First boot on a fresh database:
1. Set in `deploy/environments/prod/backend-api.env`:
   - `RUN_MIGRATIONS_ON_BOOT=true`
   - `RUN_SEEDERS_ON_BOOT=true` (only if seed data is required)
   - `ADMIN_BOOTSTRAP_EMAIL=<your-admin-email>`
   - `ADMIN_BOOTSTRAP_PASSWORD=<strong-password>`
   - Optional: `ADMIN_BOOTSTRAP_NAME=<display-name>`
2. Start:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```
3. Login to admin at `http://<server-ip>:8080/admin` using `ADMIN_BOOTSTRAP_EMAIL` and `ADMIN_BOOTSTRAP_PASSWORD`.
4. After initialization succeeds, set both flags back to `false` and clear:
   - `ADMIN_BOOTSTRAP_PASSWORD=`
   - (optional) `ADMIN_BOOTSTRAP_EMAIL=`
5. Apply:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up -d
```

Routine upgrades/restarts:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```

Stop:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml down
```

## 6) Health verification

Windows test:
```bash
docker compose -f deploy/docker-compose.test.windows.yml ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8080/health
docker compose -f deploy/docker-compose.test.windows.yml exec queue-worker php artisan horizon:status
```

Windows admin login (after seeding with `APP_ENV=local`):
- URL: `http://localhost:8080/admin`
- Seeded super admin: `admin@example.com`
- Password: `password`

Contabo production:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml ps
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8080/health
docker compose -f deploy/docker-compose.prod.contabo.yml exec queue-worker php artisan horizon:status
```

## 7) Troubleshooting

Logs:
```bash
docker compose -f deploy/docker-compose.prod.contabo.yml logs backend
docker compose -f deploy/docker-compose.prod.contabo.yml logs queue-worker
docker compose -f deploy/docker-compose.prod.contabo.yml logs scheduler
docker compose -f deploy/docker-compose.prod.contabo.yml logs db
docker compose -f deploy/docker-compose.prod.contabo.yml logs redis
docker compose -f deploy/docker-compose.prod.contabo.yml logs website
```

Common fixes:
- If `backend` starts but worker/scheduler fail, validate `APP_KEY` and `JWT_SECRET` in `deploy/environments/prod/backend-api.env`.
- If DB auth fails, verify `DB_ROOT_PASSWORD` is exported in the shell used to run compose.
- If admin login fails in production on first boot, verify `ADMIN_BOOTSTRAP_EMAIL` / `ADMIN_BOOTSTRAP_PASSWORD` were set while `RUN_SEEDERS_ON_BOOT=true`.
- Keep `RUN_MIGRATIONS_ON_BOOT=false` and `RUN_SEEDERS_ON_BOOT=false` after initial bootstrap.
- If local/test DB login fails after config changes, reset volumes and recreate:
```bash
docker compose -f deploy/docker-compose.test.windows.yml down -v
docker compose -f deploy/docker-compose.test.windows.yml up --build -d
```
