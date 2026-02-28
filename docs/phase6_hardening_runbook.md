# Phase 6 Hardening Runbook

Date: 2026-02-28  
Scope: `mitabl_enhancement_plan.md` -> **Phase 6 (6.1-6.7)**  
Owners: Backend/API, Ops Admin, SRE/Infra, QA, Security

## 1) Dependency and Entry Gate

Do not execute Phase 6 tasks until:

1. Phase `5.9` no-impact sign-off is complete.
2. Salesforce traffic verification (`5.8`) is clean for 7 consecutive days.
3. Platform hardening baseline (`0.5`) remains green in CI.

## 2) Execution Checklist

### 6.1 Redis queue + Horizon

- Keep `QUEUE_CONNECTION=redis` in all deploy env templates.
- Run queue runtime with Horizon for async stability and queue partitioning.
- Validate Horizon queues:
  - `crm-escalations`
  - `crm-communications`
  - `default`
- Validate Horizon dashboard gate:
  - non-local access only for admin users with `queue_ops.view` or `health.view`
- Evidence:
  - `backend/config/horizon.php`
  - `backend/app/Providers/HorizonServiceProvider.php`
  - `deploy/docker-compose.phase0.yml`
  - `deploy/supervisor/queue-worker.conf`
  - `deploy/environments/*/backend-api.env`

### 6.2 Intake throttles and abuse controls

- Keep API throttles active:
  - `support-intake`
  - `support-read`
  - `support-reply`
- Keep spam controls active on support intake:
  - honeypot field
  - optional captcha verification when secret is configured (support ticket + preregister + mobcontact)
- Evidence:
  - `backend/app/Providers/RouteServiceProvider.php`
  - `backend/routes/api.php`
  - `backend/app/Http/Controllers/Api/SupportTicketController.php`
  - `backend/app/Http/Controllers/Api/WebApiToCurlController.php`

### 6.3 Feature tests: certificate flow

- Validate approve/reject review actions remain guarded.
- Validate cook certificate submission resets status for resubmission.
- Evidence:
  - `backend/tests/Feature/PhaseSixHardeningTest.php`
  - `backend/app/Filament/Resources/CertificateResource.php`
  - `backend/app/Http/Controllers/Api/MikitchnController.php`

### 6.4 Feature tests: ticket lifecycle + SLA

- Validate lifecycle methods and state guards:
  - assign/reply/resolve/reopen/merge/split
- Validate SLA automation wiring:
  - periodic scan command
  - queued escalation job
- Evidence:
  - `backend/tests/Feature/PhaseSixHardeningTest.php`
  - `backend/tests/Unit/PhaseThreeSupportTicketServiceTest.php`
  - `backend/app/Console/Commands/SupportTicketSlaScanCommand.php`
  - `backend/app/Jobs/ProcessSupportTicketSlaEscalationJob.php`

### 6.5 Feature tests: policy permissions

- Validate role boundaries for policy access and publish operations.
- Ensure publish action requires `policy_changes.publish`.
- Evidence:
  - `backend/tests/Feature/PhaseSixHardeningTest.php`
  - `backend/app/Filament/Resources/PolicyResource.php`
  - `backend/database/seeders/AdminRolePermissionSeeder.php`

### 6.6 Load tests on ticket intake and admin lists

- Execute k6 suite and capture latency/failure outcomes.
- Scripts:
  - `deploy/load-tests/support-intake-load-test.js`
  - `deploy/load-tests/admin-list-load-test.js`
- Run guide:
  - `deploy/load-tests/README.md`

### 6.7 Disaster recovery runbook + backup validation

- Run backup artifact freshness validation:

```bash
powershell -ExecutionPolicy Bypass -File deploy/scripts/validate-backup-restore.ps1 `
  -BackupRoot C:\backups\mitabl `
  -MaxArtifactAgeHours 26 `
  -RestoreEvidenceFile C:\backups\mitabl\restore\latest-restore.log
```

- Validate restore drill evidence is present and fresh.
- Evidence:
  - `deploy/scripts/validate-backup-restore.ps1`
  - this runbook

## 3) Exit Criteria

Phase 6 is complete only when:

1. All checklist items `6.1` to `6.7` are implemented and evidenced.
2. Phase 6 feature tests pass in CI.
3. Load test thresholds meet SLO targets.
4. Backup validation script passes for required scopes.
5. Restore drill evidence is documented for sign-off.
