# Phase 5.5 Release Runbook

Date: 2026-02-28  
Scope: `mitabl_enhancement_plan.md` -> **Phase 5.5 (5.5.1-5.5.10)**  
Owners: Platform, Backend/API, Ops Admin, SRE/Infra, QA

## 1) Pre-requisites and Dependency Gate

Do not start Phase 5.5 execution until all of the following are complete:

1. `5.1` contract parity suite passed in staging.
2. `5.2` shadow-read/dual-observe baseline captured.
3. `5.3` Salesforce traffic cut from runtime paths.
4. `5.4` `/api/mobcontact` compatibility alias active and monitored.
5. Redis queue workers are operational (`0.5.5`), async checks are healthy, and cutover reconciliation command is available:
   - `php artisan phase5:cutover:reconcile --normalize`

## 2) Phase 5.5 Execution Checklist

### 5.5.1 Build container images for backend and ops

- Build from shared backend artifact and split runtime services:
  - `backend-api`
  - `ops-admin`
  - `queue-worker`
- Evidence:
  - `deploy/docker-compose.phase0.yml`
  - shared build context: `../backend`
  - zero-downtime boot flags in env templates (`RUN_MIGRATIONS_ON_BOOT=false`, `RUN_SEEDERS_ON_BOOT=false`)

### 5.5.2 Deploy `ops-admin` under same-domain path

- Route `/admin/*` to `ops-admin`.
- Keep admin runtime separate from `/` marketing and `/api/*` backend.
- Evidence:
  - `deploy/nginx/mitabl.phase0.conf` (`location /admin/` -> `ops-admin`)

### 5.5.3 Configure ingress and WAF rules

- Enforce TLS redirect + HSTS.
- Apply tighter admin restrictions than public/API:
  - network allowlist on `/admin/*`
  - deny-by-default outside trusted ranges
- Evidence:
  - `deploy/nginx/mitabl.phase0.conf`

### 5.5.4 Configure horizontal scaling policies

- `backend-api` and `ops-admin` must scale independently.
- Baseline policy targets:
  - API: CPU target 60-70%, queue latency p95 < 2s
  - Admin: CPU target 50-60%, request p95 < 600ms
  - Queue worker: scale by queue depth + failed job growth
- Minimum runtime baseline:
  - API replicas >= 2 in staging/prod
  - Ops admin replicas >= 2 in staging/prod
  - Queue workers >= 2 processes (supervisor) and horizontally scalable by queue depth
- Evidence:
  - `deploy/supervisor/queue-worker.conf`
  - environment split in `deploy/environments/*`
  - `deploy/docker-compose.phase0.yml` deploy resource limits/replica policy
- Note:
  - For non-Swarm Docker Compose, treat `deploy.*` as policy source-of-truth and mirror equivalent settings in your runtime orchestrator (AKS/ECS/Kubernetes/HPA).

### 5.5.5 Queue worker deployment separation

- Keep queue workers out of API/admin web serving path.
- Prioritize dedicated CRM queues:
  - `crm-escalations`
  - `crm-communications`
  - `default`
- Evidence:
  - `deploy/docker-compose.phase0.yml`
  - `deploy/supervisor/queue-worker.conf`
  - `backend/app/Jobs/ProcessSupportTicketSlaEscalationJob.php`
  - `backend/app/Services/CrmCommunicationService.php`

### 5.5.6 Add health probes

- Use service health probes for API/admin/worker/redis.
- API/admin health endpoints:
  - `/api/health` (liveness baseline)
  - `/api/health/live`
  - `/api/health/startup`
  - `/api/health/ready`
- Marketing health endpoint:
  - `/health`
- Probe targets:
  - startup: warm app + dependencies
  - liveness: process is alive
  - readiness: DB/queue/mail/storage checks healthy enough for traffic
- Evidence:
  - `deploy/docker-compose.phase0.yml` healthcheck blocks
  - `backend/routes/api.php`
  - `website/routes/web.php`
  - `backend/app/Services/SystemHealthService.php`

### 5.5.7 Zero-downtime DB migration steps

Run deployment in 3 stages:

1. Pre-deploy:
   - run additive-safe migrations only
   - verify Horizon workers are active and no failed migration lock
   - keep `RUN_MIGRATIONS_ON_BOOT=false` and `RUN_SEEDERS_ON_BOOT=false` in runtime env
2. Deploy:
   - roll API/admin first, keep workers running
   - disable destructive schema changes during this window
3. Post-deploy:
   - run reconciliation:
     - `php artisan phase5:cutover:reconcile --normalize`
   - validate no orphan links and duplicate spikes in intake data

### 5.5.8 Configure centralized logs/metrics/traces

- Tag logs by service boundary:
  - `marketing-web`
  - `backend-api`
  - `ops-admin`
- Ensure queue metrics and synthetic health checks are emitted.
- Evidence:
  - `APP_SERVICE` in `deploy/environments/*`
  - `backend/app/Providers/AppServiceProvider.php`
  - `website/app/Providers/AppServiceProvider.php`
  - `backend/app/Console/Commands/PlatformSyntheticHealthCheckCommand.php`

### 5.5.9 Define rollback runbook

If release fails:

1. Route rollback:
   - send `/admin/*` and `/api/*` to previous healthy revision.
2. App rollback:
   - rollback `backend-api`, `ops-admin`, then workers.
3. Migration rollback:
   - only if migration is reversible and validated in staging.
   - otherwise use forward-fix migration.
4. Safety checks:
   - rerun health checks
   - run reconciliation command
   - verify no Salesforce traffic markers:
     - `deploy/scripts/verify-no-salesforce-traffic.ps1`

### 5.5.10 Production cutover rehearsal

Dry-run in staging with timestamps and owners:

1. Build + deploy `backend-api`, `ops-admin`, `queue-worker`.
2. Validate ingress behavior for `/`, `/api/*`, `/admin/*`.
3. Validate queue separation and SLA escalation delivery.
4. Execute reconciliation command and compare pre/post counts.
5. Execute rollback drill and restore target release.
6. Capture action log with:
   - start/end times
   - owner per step
   - issues and mitigation
   - go/no-go decision

## 3) Verification Commands

```bash
# API health endpoints
curl -fsS http://localhost:8000/api/health
curl -fsS http://localhost:8000/api/health/live
curl -fsS http://localhost:8000/api/health/ready

# Cutover reconciliation
php artisan phase5:cutover:reconcile --normalize

# No-salesforce-traffic verification (7-day window)
powershell -File deploy/scripts/verify-no-salesforce-traffic.ps1 -LogPath ./storage/logs -Days 7
```

## 4) Exit Criteria

Phase 5.5 is complete only when:

1. All checklist items `5.5.1` to `5.5.10` are executed and evidenced.
2. Staging rehearsal is recorded with owners and timing.
3. Rollback drill succeeds.
4. Health checks pass for API/admin/queue.
5. No Salesforce traffic markers are detected for the defined window.
