# Deployment Guide

Canonical Docker runbook with two supported stacks:

- Windows test stack: `deploy/docker-compose.test.windows.yml` (extends root compose)
- Contabo Linux production stack: `deploy/docker-compose.prod.contabo.yml`

Both stacks run:

- `backend` (public pages + admin + API)
- `queue-worker` (Horizon queue processing)
- `scheduler` (Laravel scheduled jobs)
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
- Host nginx on `80/443` as public ingress

## 2) Required env files

Windows test backend env:

- `deploy/environments/dev/backend-api.env`

Production backend env:

- `deploy/environments/prod/backend-api.env`

Required production values before first boot:

- `APP_KEY` (format `base64:...`)
- `JWT_SECRET`
- `DB_ROOT_PASSWORD` (must be set in shell env or repo root `.env`)
- `ADMIN_BOOTSTRAP_EMAIL` (only for first prod bootstrap when seeding)
- `ADMIN_BOOTSTRAP_PASSWORD` (only for first prod bootstrap when seeding)

`DB_HOST` in production is:

- `DB_HOST=db`

## 3) Generate production secrets

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

Set DB root password before compose:

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

Stop:

```bash
docker compose -f deploy/docker-compose.test.windows.yml down
```

Windows first-run notes:

- Ensure `APP_ENV=local` in `deploy/environments/dev/backend-api.env`.
- For fresh DB init:
  - `RUN_MIGRATIONS_ON_BOOT=true`
  - `RUN_SEEDERS_ON_BOOT=true`
- Set both back to `false` after first successful bootstrap.

## 5) Contabo production deployment

First boot on fresh DB:

1. Set in `deploy/environments/prod/backend-api.env`:
   
   - `RUN_MIGRATIONS_ON_BOOT=true`
   - `RUN_SEEDERS_ON_BOOT=true` (only if seed data is required)
   - `ADMIN_BOOTSTRAP_EMAIL=<your-admin-email>`
   - `ADMIN_BOOTSTRAP_PASSWORD=<strong-password>`
   - Optional: `ADMIN_BOOTSTRAP_NAME=<display-name>`

2. Set DB password and start:
   
   ```bash
   export DB_ROOT_PASSWORD='replace_with_strong_password'
   echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD" > .env
   docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
   ```

3. Login to admin:
   
   - Before host nginx: `http://<server-ip>:8000/admin`
   - After host nginx + TLS: `https://www.mitabl.com/admin`

4. After initialization, set both flags back to `false` and clear bootstrap password/email.

5. Apply:
   
   ```bash
   docker compose -f deploy/docker-compose.prod.contabo.yml up -d
   ```

Routine upgrades/restarts:

```bash
cd ~/mitabl
git pull --ff-only origin main
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d --remove-orphans
```

Important password handling note:

- `DB_ROOT_PASSWORD` is required by compose, but you do **not** need to run `export DB_ROOT_PASSWORD=...` and `echo ... > .env` on every deploy.
- Set it once and keep it persistent in repo root `.env`:

  ```bash
  cd ~/mitabl
  printf 'DB_ROOT_PASSWORD=%s\n' 'replace_with_strong_password' > .env
  chmod 600 .env
  ```

- On future deploys, just run `git pull` and `docker compose ... up -d --build`.
- Only update `.env` again if you intentionally rotate the DB root password.

Stop:

```bash
docker compose -f deploy/docker-compose.prod.contabo.yml down
```

Note: `down` does not delete DB data unless `-v` is used.

## 6) Deploying Updates to Production & Health verification

Production code update (recommended):

```bash
cd ~/mitabl
git pull --ff-only origin main
docker compose -f deploy/docker-compose.prod.contabo.yml up -d --build --remove-orphans
```

If `.env` does not exist yet (first server setup only):

```bash
cd ~/mitabl
printf 'DB_ROOT_PASSWORD=%s\n' 'replace_with_strong_password' > .env
chmod 600 .env
docker compose -f deploy/docker-compose.prod.contabo.yml up -d --build --remove-orphans
```

Nginx after code deploy:

- You do **not** need to restart/reload nginx for normal application code updates.
- Reload nginx only when nginx config or TLS certs change.

Commands when nginx changes are made:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

If `restart` fails while `nginx -t` succeeds, treat it as a runtime/process issue rather than a syntax issue:

```bash
sudo systemctl status nginx --no-pager -l
sudo journalctl -xeu nginx.service --no-pager
sudo ss -ltnp '( sport = :80 or sport = :443 or sport = :8443 )'
```



Windows test:

```bash
docker compose -f deploy/docker-compose.test.windows.yml ps
curl -fsS http://localhost:8000/health
curl -fsS http://localhost:8000/api/health/live
docker compose -f deploy/docker-compose.test.windows.yml exec queue-worker php artisan horizon:status
```

Contabo production:

```bash
docker compose -f deploy/docker-compose.prod.contabo.yml ps
curl -fsS http://127.0.0.1:8000/health
curl -fsS http://127.0.0.1:8000/api/health/live
docker compose -f deploy/docker-compose.prod.contabo.yml exec queue-worker php artisan horizon:status
```

## 7) Contabo host nginx + HTTPS (`mitabl.com`)

Use host-level nginx as TLS terminator and reverse proxy to Docker backend on `127.0.0.1:8000`.

### 7.1 Install nginx + certbot

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

### 7.2 Host site config

Use `deploy/nginx/mitabl.host.unified.conf`:

```bash
sudo cp deploy/nginx/mitabl.host.unified.conf /etc/nginx/sites-available/mitabl.com
sudo ln -sf /etc/nginx/sites-available/mitabl.com /etc/nginx/sites-enabled/mitabl.com
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
```

### 7.3 Issue or reinstall TLS certificate

```bash
sudo certbot --nginx -d mitabl.com -d www.mitabl.com --redirect -m admin@mitabl.com --agree-tos --no-eff-email
```

If cert already exists, choose reinstall option.

### 7.4 Validate active nginx proxy config

```bash
sudo nginx -T | grep -nE "server_name|proxy_pass|X-Forwarded-Proto|X-Forwarded-Port"
```

Expected:

- `proxy_pass http://127.0.0.1:8000;`
- `X-Forwarded-Proto https`
- `X-Forwarded-Port 443`

Production note:

- The supported Contabo stack does not use a `website` container in front of Laravel.
- Public ingress should be host nginx on `80/443` using [deploy/nginx/mitabl.host.unified.conf](/c:/Code/mitabl/deploy/nginx/mitabl.host.unified.conf).
- If any old listener still exposes `8443`, remove it before debugging admin redirects.

## 8) Troubleshooting

Logs:

```bash
docker compose -f deploy/docker-compose.prod.contabo.yml logs backend
docker compose -f deploy/docker-compose.prod.contabo.yml logs queue-worker
docker compose -f deploy/docker-compose.prod.contabo.yml logs scheduler
docker compose -f deploy/docker-compose.prod.contabo.yml logs db
docker compose -f deploy/docker-compose.prod.contabo.yml logs redis
```

Common fixes:

- If backend DB auth fails, verify both:
  
  - `deploy/environments/prod/backend-api.env` has correct `DB_PASSWORD`
  - repo root `.env` has correct `DB_ROOT_PASSWORD`

- If compose says `DB_ROOT_PASSWORD is required`, export it and write `.env` before `up`.

- If admin login returns `419` right after restart, clear cookies / use private window and retry.

- If stale old container still exists:
  
  ```bash
  docker rm -f mitabl-website 2>/dev/null || true
  docker rm -f mitabl-prod-contabo-website-1 2>/dev/null || true
  docker compose -f deploy/docker-compose.prod.contabo.yml up -d --remove-orphans
  ```

- If `nginx -t` passes but `systemctl restart nginx` fails, inspect service logs and port conflicts:
  
  ```bash
  sudo systemctl status nginx --no-pager -l
  sudo journalctl -xeu nginx.service --no-pager
  sudo ss -ltnp '( sport = :80 or sport = :443 or sport = :8443 )'
  ```
