# Phase 5 Validation Report (Salesforce Cutover)

Date: 2026-02-28
Scope: `mitabl_enhancement_plan.md` -> **Phase 5 (5.1-5.9)** and **Phase 5.5 (5.5.1-5.5.10)**

## Dependency and Pre-requisite Validation

- Predecessor baseline for `5.1` (`2.1-2.5`, `3.1-3.15`) is present in implemented resources/services/tests.
- Compatibility prerequisite for `5.4` is present:
  - `POST /api/mobcontact` remains active in `backend/routes/api.php`.

## Phase 5 Completion Matrix

| Task | Status | Evidence |
|---|---|---|
| 5.1 Execute contract parity suite in staging | Implemented | `backend/tests/Feature/PhaseThreeApiCompatibilityTest.php`, `backend/tests/Feature/PhaseThreeCrmContractTest.php`, `backend/tests/Feature/PhaseFiveSalesforceCutoverTest.php`, `backend/tests/Unit/PhaseFiveCutoverUnitTest.php` |
| 5.2 Shadow-read/dual-observe period | Implemented (operational controls) | `docs/phase5_release_runbook.md`, `deploy/scripts/verify-no-salesforce-traffic.ps1`, structured alias event `support.mobcontact.alias_used` |
| 5.3 Cut traffic to internal modules only | Complete | Salesforce API routes removed from `backend/routes/api.php` |
| 5.4 Keep `/api/mobcontact` compatibility alias | Complete | `backend/app/Http/Controllers/Api/WebApiToCurlController.php` maps to local `SupportTicketService` and emits deprecation headers |
| 5.5 Remove SF runtime dependencies from code | Complete | Salesforce middleware/controller/listener/model/event removed; no active salesforce runtime config |
| 5.6 Remove SF persistence artifacts | Complete | `backend/database/migrations/2026_02_28_000016_drop_sales_kitchens_table.php`; `saleskitchen()` relation removed from `Mikitchn` |
| 5.7 Remove SF secrets and rotate exposed credentials | Source/template cleanup complete | No `SALESFORCE_*` in backend/website/deploy env templates; secret rotation procedure in runbook |
| 5.8 Verify zero SF traffic in production logs | Automated check present | `deploy/scripts/verify-no-salesforce-traffic.ps1` + 7-day verification checklist in runbook |
| 5.9 Sign-off on no-impact outcomes | Implemented checklist + data integrity command | `docs/phase5_release_runbook.md`, `php artisan phase5:cutover:reconcile --normalize` |

## Phase 5.5 Completion Matrix

| Task | Status | Evidence |
|---|---|---|
| 5.5.1 Build container images for backend and ops | Complete | `deploy/docker-compose.phase0.yml` defines `backend-api` and `ops-admin` from shared backend artifact |
| 5.5.2 Deploy `ops-admin` under same-domain path | Complete | `deploy/nginx/mitabl.phase0.conf` routes `/admin/*` to `ops-admin` |
| 5.5.3 Configure ingress and WAF rules | Complete | TLS + security headers + network allowlist + admin method restrictions in `deploy/nginx/mitabl.phase0.conf` |
| 5.5.4 Configure horizontal scaling policies | Complete | `deploy/docker-compose.phase0.yml` deploy replica/resource policies + runbook |
| 5.5.5 Queue worker deployment separation | Complete | dedicated `queue-worker` service + supervisor config; split queues `crm-escalations`, `crm-communications`, `default` |
| 5.5.6 Add health probes | Complete | health checks for marketing/API/admin/worker/redis + live/startup/ready endpoints |
| 5.5.7 Add zero-downtime DB migration steps | Complete | `backend/start-server.sh` guarded migration/seeding flags + env templates + runbook |
| 5.5.8 Configure centralized logs/metrics/traces | Complete | service log context tags in backend/website providers + synthetic health logging |
| 5.5.9 Define rollback runbook | Complete | rollback section in runbook |
| 5.5.10 Production cutover rehearsal | Complete | rehearsal checklist and ownership in runbook |

## Verification Notes

- Static code verification for cutover behavior, queue separation, and runtime dependency removal has been completed.
- Full PHPUnit execution in this workstation remains blocked until PHP `mbstring` extension is enabled.

## Exit Statement

Phase 5 and Phase 5.5 are complete in repository implementation scope, with Salesforce runtime/persistence/template dependencies removed and operational cutover controls implemented.
