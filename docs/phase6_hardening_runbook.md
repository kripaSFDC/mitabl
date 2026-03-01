# Phase 6 Hardening Runbook

This runbook captures the operational checks required to validate the Phase 6 hardening controls described in `mitabl_enhancement_plan.md`.

## 6.1 Redis queue + Horizon

- Confirm queue transport is Redis in every non-test runtime:
  - `QUEUE_CONNECTION=redis`
  - `HORIZON_PREFIX=mitabl_horizon:`
- Validate Horizon is running:
  - container/supervisor command must execute `php artisan horizon`
- Validate escalation queue lanes are active:
  - `crm-escalations`
  - `crm-communications`

## 6.2 Public intake hardening (captcha + throttle + honeypot)

- Validate throttles are attached to:
  - `POST /api/preregister`
  - `POST /api/support/ticket`
  - `POST /api/mobcontact` (deprecated alias)
- Validate bot honeypot acceptance path returns success without persisting records.
- Validate captcha behavior with `RECAPTCHA_SECRET` set:
  - bad token returns `422`
  - transport outages return `422` (not `500`)

## 6.3 Certificate workflow resilience

- Approve/reject actions enforce concurrency protections (`lockForUpdate`) and stale-review checks.
- Certificate document preview only allows approved extensions.
- Rejection path must require reason and persist reviewer metadata.

## 6.4 SLA escalation idempotency

- Run SLA scan command and verify one escalation event per breach type.
- Re-running escalation jobs must not duplicate `sla_escalated` events.

## 6.5 Policy and admin permission boundaries

- Seed admin roles/permissions and verify:
  - `platform_admin` and `super_admin` can publish policy changes.
  - `operations` and `customer_service` cannot publish policy changes.

## 6.6 Load-test verification

Run support intake load test:

```bash
k6 run deploy/load-tests/support-intake-load-test.js \
  -e BASE_URL=https://staging.mitabl.com \
  -e CAPTCHA_TOKEN="<valid-captcha-token>"
```

Capture p50/p95/p99 latency, error rate, and threshold pass/fail.

## 6.7 Disaster recovery runbook + backup validation

Execute backup/restore validation script and collect JSON evidence:

```powershell
pwsh -ExecutionPolicy Bypass -File deploy/scripts/validate-backup-restore.ps1 \
  -BackupRoot "<path-to-artifacts>" \
  -RequiredScopes @("database","redis","uploads") \
  -RestoreEvidenceFile "<restore-evidence-file>"
```

Attach output evidence to release ticket and incident archive.
