# DEPLOYEMENT.md

This guide provides **step-by-step deployment instructions** for:

1. **Windows Docker test environment** (single-host validation / UAT-style setup).
2. **Production Linux server deployment** (hardened VM/bare-metal with Docker Compose, Nginx, SSL, backups, and operational controls).

> Note: file name intentionally uses `DEPLOYEMENT.md` per project request.

---

## 1. Prerequisites

## 1.1 Common prerequisites

- Access to this repository.
- Environment-specific `.env` values for:
  - backend (`backend/.env`)
  - website (`website/.env`)
- DNS names (production) for website and API.
- Stripe/FCM/Auth secrets and DB credentials.

## 1.2 Ports used in current compose

- `8000` -> backend service
- `8080` -> website service
- `3306` -> MySQL

---

## 2. Windows Docker (Test) Deployment

Target use case: local QA/UAT, non-production tests, endpoint validation, smoke/regression runs.

## 2.1 Install required software

1. Install **Docker Desktop for Windows**.
2. Enable **WSL2 backend** in Docker Desktop settings.
3. Install **Git for Windows**.
4. Optional: install **k6** for load test scripts under `deploy/load-tests`.

## 2.2 Clone repository

```powershell
git clone <your-repo-url> mitabl
cd mitabl
```

## 2.3 Create runtime environment files

1. Backend env:

```powershell
Copy-Item backend/.env.example backend/.env
```

2. Website env:

```powershell
Copy-Item website/.env.example website/.env
```

3. Update key variables in **backend/.env**:

- `APP_ENV=local` (or `staging` for test parity)
- `APP_URL=http://localhost:8000`
- `DB_HOST=db`
- `DB_PORT=3306`
- `DB_DATABASE=mitabl`
- `DB_USERNAME=root`
- `DB_PASSWORD=root`
- `JWT_SECRET` (generate later if blank)
- Stripe/FCM variables as needed for test

4. Update key variables in **website/.env**:

- `APP_ENV=local`
- `APP_URL=http://localhost:8080`
- `DB_HOST=db`
- `DB_PORT=3306`
- `DB_DATABASE=mitabl`
- `DB_USERNAME=root`
- `DB_PASSWORD=root`
- `BACKEND_API_BASE_URL=http://backend:8000` (or equivalent configured key in `config/services.php`)

## 2.4 Build and start stack

From repo root:

```powershell
docker compose up --build -d
```

Expected services:

- `mitabl-db`
- `mitabl-db-migrate`
- `mitabl-website-db-migrate`
- `mitabl-backend`
- `mitabl-website`
- `mitabl-mobile` (build/runtime container)

## 2.5 Verify service health

```powershell
docker compose ps
curl http://localhost:8000/api/health
curl http://localhost:8080/health
```

Readiness checks:

```powershell
curl http://localhost:8000/api/health/live
curl http://localhost:8000/api/health/ready
```

## 2.6 Initial app bootstrap (if required)

If migrations/seeding were not run by container jobs:

```powershell
docker compose exec backend php artisan key:generate --force
docker compose exec backend php artisan jwt:secret --force
docker compose exec backend php artisan migrate --force
docker compose exec backend php artisan db:seed --force
```

Website key/migrations if needed:

```powershell
docker compose exec website php artisan key:generate --force
docker compose exec website php artisan migrate --force
```

## 2.7 Admin access setup

1. Seed admin data (`AdminUserSeeder`) if not already seeded.
2. Access Filament admin at:

```text
http://localhost:8000/admin
```

3. Validate role permissions using seeded roles:
- super_admin
- platform_admin
- operations
- customer_service
- finance_readonly

## 2.8 Logs and troubleshooting

```powershell
docker compose logs -f backend
docker compose logs -f website
docker compose logs -f db
```

Common fixes:
- Container fails on DB connection: wait for DB healthcheck and re-run migration job.
- 500 errors: verify env keys (`APP_KEY`, `JWT_SECRET`).
- Intake proxy failures on website: verify backend base URL env/config.

## 2.9 Stop and clean test environment

```powershell
docker compose down
docker compose down -v   # remove DB volume when full reset is needed
```

---

## 3. Production Linux Server Deployment

Target use case: internet-facing production deployment with hardened controls.

## 3.1 Recommended infrastructure

- Ubuntu 22.04 LTS (or equivalent Linux distro).
- Minimum baseline:
  - 4 vCPU
  - 8 GB RAM
  - SSD storage with backup policy
- Public reverse proxy (Nginx) with TLS termination.
- Firewall restricted to required ports.

## 3.2 Install platform dependencies

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git

# Docker Engine + Compose plugin (official repo setup)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
```

## 3.3 Create deploy user and directories

```bash
sudo adduser --disabled-password --gecos "" mitabl
sudo usermod -aG docker mitabl
sudo mkdir -p /opt/mitabl
sudo chown -R mitabl:mitabl /opt/mitabl
```

Switch user:

```bash
sudo su - mitabl
```

## 3.4 Fetch source and prepare env files

```bash
cd /opt
git clone <your-repo-url> mitabl
cd mitabl
cp backend/.env.example backend/.env
cp website/.env.example website/.env
```

Set production values:

### backend/.env (minimum)

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://api.<your-domain>`
- DB credentials (`DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`)
- Redis/queue settings (if used)
- `JWT_SECRET` (generated securely)
- Stripe + FCM keys
- mail transport settings

### website/.env (minimum)

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://www.<your-domain>`
- DB credentials if website DB is used
- backend API base URL -> `https://api.<your-domain>` (matching `config/services.php` key)

## 3.5 Bring up stack

```bash
cd /opt/mitabl
docker compose pull
docker compose up --build -d
```

Verify:

```bash
docker compose ps
curl -f http://127.0.0.1:8000/api/health
curl -f http://127.0.0.1:8080/health
```

## 3.6 Run one-time production initialization

```bash
docker compose exec backend php artisan key:generate --force
docker compose exec backend php artisan jwt:secret --force
docker compose exec backend php artisan migrate --force
docker compose exec backend php artisan db:seed --force

docker compose exec website php artisan key:generate --force
docker compose exec website php artisan migrate --force
```

> Run `db:seed` in production only when approved by release policy.

## 3.7 Nginx reverse proxy setup

Install Nginx:

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

Create API vhost (`/etc/nginx/sites-available/mitabl-api.conf`):

```nginx
server {
    listen 80;
    server_name api.<your-domain>;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Create website vhost (`/etc/nginx/sites-available/mitabl-web.conf`):

```nginx
server {
    listen 80;
    server_name www.<your-domain> <your-domain>;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and reload:

```bash
sudo ln -s /etc/nginx/sites-available/mitabl-api.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/mitabl-web.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 3.8 Enable TLS (Let’s Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.<your-domain> -d www.<your-domain> -d <your-domain>
```

Confirm renewal timer:

```bash
systemctl status certbot.timer
```

## 3.9 Queue workers and horizon

If using queue-heavy workloads:

- Run horizon in backend container (or dedicated worker containers in a production override compose file).
- Use `deploy/supervisor/queue-worker.conf` pattern if supervisor-managed workers are preferred.

Basic checks:

```bash
docker compose exec backend php artisan horizon:status
docker compose exec backend php artisan queue:failed
```

## 3.10 Firewall and hardening

Using UFW example:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Recommended controls:

- Keep DB port `3306` non-public.
- Restrict SSH by IP where possible.
- Disable `APP_DEBUG` in production.
- Rotate secrets and use managed secret stores.
- Enable external monitoring and alerting on health endpoints.

## 3.11 Backup strategy

Minimum production backup scope:

1. MySQL logical dump (daily + retention policy).
2. Uploaded/static storage backup (if local volume-backed).
3. `.env` and deployment metadata backup in secure encrypted location.

Example DB backup command:

```bash
docker compose exec db sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" mitabl' > /opt/backups/mitabl-$(date +%F).sql
```

## 3.12 Zero/low-downtime release flow

1. Pull latest code.
2. Build new images.
3. Run migrations.
4. Restart services.
5. Run health checks.
6. Run smoke tests for:
   - API auth + health
   - Website landing + intake forms
   - Admin login + key list screens

Example:

```bash
cd /opt/mitabl
git pull
docker compose up --build -d
docker compose exec backend php artisan migrate --force
curl -f https://api.<your-domain>/api/health/ready
curl -f https://www.<your-domain>/health
```

---

## 4. Post-Deployment Validation Checklist

- [ ] Backend health endpoints return expected status.
- [ ] Website `/health` returns `ok`.
- [ ] Admin panel reachable and role-based access behaves correctly.
- [ ] Intake APIs (`/api/preregister`, `/api/support/ticket`) working from website and direct backend paths.
- [ ] Payment configuration keys present and no hardcoded secrets in repo.
- [ ] Queue backlog and failed jobs are monitored.

---

## 5. Rollback Plan

1. Keep previous working git tag/image references.
2. If release fails:
   - Roll back to previous compose/image version.
   - Restore DB backup if schema/data migration requires reversal.
3. Re-run health checks and smoke tests.

---

## 6. Useful Commands (Quick Reference)

```bash
# View running services
docker compose ps

# Tail backend logs
docker compose logs -f backend

# Tail website logs
docker compose logs -f website

# Exec backend shell
docker compose exec backend sh

# Check backend health
curl -f http://127.0.0.1:8000/api/health/ready

# Restart a service
docker compose restart backend
```
