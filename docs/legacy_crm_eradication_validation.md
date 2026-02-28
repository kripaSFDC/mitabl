# Legacy CRM Dependency Eradication Validation

Date: 2026-03-01

## 1) Contract Parity Matrix

| Legacy capability | Replacement owner | Acceptance coverage | Data invariants |
| --- | --- | --- | --- |
| Certificate approval (`PUT /api/kitchen/{id}/certificate` legacy inbound) | Filament `CertificateResource` actions | `backend/tests/Feature/PhaseSixHardeningTest.php` validates approve/reject/bulk actions and concurrency safeguards | Certificate review transitions remain controlled by local status + lock checks |
| User lookup (`GET /api/legacy/mifoodi` legacy inbound) | Filament `UserResource` search and edit | `backend/tests/Feature/PhaseTwoActionContractTest.php` and `backend/tests/Feature/PhaseTwoResourceScaffoldTest.php` | User lookup is local DB only; no external CRM endpoint dependency |
| Lead intake (`POST /api/preregister`) | `PreRegistrationService` + `pre_registrations` | `backend/tests/Unit/PhaseFiveCutoverUnitTest.php`, `backend/tests/Feature/PhaseThreeApiCompatibilityTest.php` | Duplicate fingerprint dedupe, normalized source mapping, honeypot/captcha protection |
| Support intake (`POST /api/mobcontact`) | Compatibility alias -> `SupportTicketController::store` -> `support_tickets` | `backend/tests/Feature/PhaseThreeApiCompatibilityTest.php` | Same success payload contract, same throttle/captcha rules, duplicate suppression |
| Kitchen sync listener | Removed | No listener binding in `backend/app/Providers/EventServiceProvider.php` | Local DB remains source of truth |

## 2) Compatibility and No-Impact Guardrails

- `/api/preregister` contract retained with existing success envelope (`status`, `isSuccess`, `message`, `data`).
- `/api/mobcontact` alias added and mapped to local support ticket creation.
- Deprecation headers added on alias responses via `AddMobcontactDeprecationHeaders`:
  - `Deprecation`
  - `Sunset`
  - `Link`
  - `X-Deprecated-Endpoint`
  - `X-Replacement-Endpoint`
- Structured alias usage logs emitted (`api.mobcontact.alias_used`).
- Idempotency protections in place:
  - Pre-registration dedupe by `duplicate_fingerprint` + rolling window.
  - Support dedupe by requester + similar subject + rolling window.
- Notifications remain queued/asynchronous through queued mail in `CrmCommunicationService`.

## 3) Data Integrity and Reconciliation

- Added one-time reconciliation command: `php artisan crm:reconcile-intake`.
- Command performs:
  - duplicate group detection in `pre_registrations` and `support_tickets`,
  - email/phone normalization plans and optional writes (`--write`),
  - foreign key consistency checks for support tickets (`user_id`, `order_id`, `mikitchn_id`) with optional null repair in write mode,
  - pre/post counts + mismatch report output as JSON.
- Command coverage: `backend/tests/Feature/PhaseFiveReconciliationCommandTest.php`.

## 4) Security and Secret Cleanup

- No legacy CRM tokens/credentials are present in source templates after scan.
- Environment template keeps only local CRM keys and alias deprecation settings.
- Existing hardening test still guards against token leakage patterns.
- CI secret scanning gate should be configured at pipeline level (outside app code) to block reintroduction.

## 5) Code and Infrastructure Removal

- Removed legacy CRM artifacts from backend:
  - deleted legacy kitchen-mapping drop migration,
  - removed empty `backend/app/Http/Controllers/Api/Sales` directory,
  - no legacy listener/middleware bindings remain in Kernel/Event providers.
- Legacy CRM helper logic is not present in `WebApiToCurlController`.
- Route and health coverage updated for local intake endpoints including compatibility alias.
