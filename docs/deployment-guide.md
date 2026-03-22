# mitabl — Deployment Guide

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive

---

## Architecture Overview

```
Internet
    │
    ▼
Host Nginx (SSL/TLS — Let's Encrypt)
    │  port 80 → 301 redirect to HTTPS
    │  port 443 → proxy_pass to localhost:8000
    ▼
Docker Container: backend (port 8000)
    │  Nginx → PHP-FPM (port 9000)
    │  Serves: Laravel API + Filament Admin + Static Website
    │
    ├── Queue Worker Container (Horizon)
    ├── Scheduler Container (schedule:work)
    ├── MySQL 8.0 Container (port 3306)
    └── Redis 7.2 Container (port 6379)
```

---

## Production Environment (Contabo VPS)

### Docker Compose File
`deploy/docker-compose.prod.contabo.yml`

### Services
| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| backend | mitabl-backend:latest | 127.0.0.1:8000 | API + Admin + Website |
| queue-worker | mitabl-backend:latest | - | Laravel Horizon |
| scheduler | mitabl-backend:latest | - | Cron scheduler |
| db | mysql:8.0 | 3306 (internal) | Database |
| redis | redis:7.2-alpine | 6379 (internal) | Cache + Queue |

### Deploy Steps
```bash
# On Contabo VPS
cd /path/to/mitabl
docker compose -f deploy/docker-compose.prod.contabo.yml up --build -d
```

### Environment Configuration
- Production env: `deploy/environments/prod/backend-api.env`
- Key settings: APP_ENV=production, APP_DEBUG=false, JWT_TTL=10080 (7 days)
- Database password via `DB_ROOT_PASSWORD` shell variable

---

## Host Nginx Configuration

File: `deploy/nginx/mitabl.host.unified.conf`

- Listens on ports 80 (redirect) and 443 (SSL)
- Domains: `mitabl.com`, `www.mitabl.com`
- SSL certificates: `/etc/letsencrypt/live/mitabl.com/`
- Proxies all traffic to `http://127.0.0.1:8000`
- Adds `X-Internal-Proxy-Token`, `X-Forwarded-Proto: https`

---

## Container Nginx Configuration

File: `backend/nginx/default.conf`

- Root: `/app/public` (contains both Laravel and website files)
- `/` serves index.html (static website)
- `/health` returns "ok"
- `/api/*` routed to Laravel via PHP-FPM
- `/admin/*` routed to Filament via PHP-FPM
- Static files served directly by nginx

---

## Dockerfile (Production)

File: `deploy/Dockerfile.backend.unified`

Two-stage build:
1. **vendor** stage (composer:2): Install PHP dependencies
2. **runtime** stage (php:8.2-fpm): PHP-FPM + Nginx + app code + website files

Key features:
- OPcache enabled (256MB, timestamps disabled)
- PHP extensions: mysqli, pdo_mysql, mbstring, bcmath, pcntl, zip, intl, redis
- Website files copied into Laravel public directory

---

## Health Checks

| Endpoint | Type | Used By |
|----------|------|---------|
| `/api/health/live` | Liveness | Docker healthcheck, monitoring |
| `/api/health/ready` | Readiness | Orchestrator readiness probe |
| `/api/health/startup` | Startup | Initial boot verification |
| `/health` | Static | Nginx-level health (no PHP) |

---

## CI/CD Pipeline

File: `.github/workflows/ci-cd.yml`

**Triggers:** Push to main, PRs targeting main

**Jobs:**
1. **secret-scan** — Scans for leaked credentials
2. **backend** — PHP 8.2 tests with coverage (80% threshold)
3. **support-ticket-contract** — Dedicated CRM E2E test gate
4. **website** — Static site build verification
5. **mobile-app** — Flutter test suite

All workstream jobs run in parallel after secret-scan passes.

---

## Operations Scripts

| Script | Purpose |
|--------|---------|
| `deploy/scripts/collect-admin-login-diagnostics.sh` | Diagnose admin login failures (read-only mode + repair mode) |
| `deploy/scripts/validate-backup-restore.ps1` | Validate backup freshness and completeness |
| `deploy/scripts/verify-no-legacy-crm-traffic.ps1` | Confirm no legacy CRM traffic in logs |

---

## Load Testing

Tool: k6 (`deploy/load-tests/`)

- Tests admin panel pages (`/admin/policies`, `/admin/support-tickets`)
- 10 virtual users, 5 minutes duration
- Thresholds: <1% failure rate, p95 <900ms
