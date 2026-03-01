# Mitabl Functional Delivery Assessment

Date: 2026-03-01
Scope: Validation of **CRM Functional Specification** and **Platform Admin Functional Specification** sections in `mitabl_enhancement_plan.md` against the current codebase implementation.

## Executive Verdict

**Not fully delivered yet.**

The repository contains substantial implementation progress for CRM and Platform Admin (support ticket domain model, SLA/escalation automation, policy/versioning controls, health/queue/integration pages, and security admin controls). However, several functional-spec commitments are still partially delivered or missing, and a few contract mismatches introduce potential breakage risk.

---

## Methodology

- Reviewed scope and acceptance statements in:
  - `mitabl_enhancement_plan.md` (CRM + Platform Admin functional sections).
- Validated implementation in:
  - Filament resources/pages/widgets.
  - API routes/controllers.
  - Services, policies, and migrations.
  - Platform and support configuration.

---

## CRM Functional Specification Validation

### 1) CRM Agent UX requirements

#### Delivered / Strongly implemented

- Triage queue with fast filters and saved-view equivalents exists (`My Queue`, `Unassigned`, `SLA Risk`, `Ops Certificates Pending`) through table filters in `SupportTicketResource`.
- Keyboard shortcuts are implemented for key actions (assign/reply/resolve).
- SLA indicators and status badges are implemented at list level.
- Internal-note vs public-reply distinction is implemented.
- Collision protection is implemented with optimistic-concurrency checks (`expected_updated_at` + guard).
- High-risk irreversible action confirmation exists for merge using typed `MERGE`.

#### Gaps / Partial delivery

- **Single-screen triage layout (left queue / center timeline / right context pane) is not fully realized as specified.** Current implementation remains table/action oriented with default edit page and no dedicated tri-pane UX.
- **Canned macros/templates integrated into ticket reply flow are not evident.** A generic `TemplateResource` exists, but there is no direct “insert macro/template” action in support reply workflow.
- **Auto-suggest related tickets/similar past resolutions** is not implemented in the support UI workflow.
- **Accessibility/WCAG AA and keyboard-nav evidence** is not validated by automated tests or explicit accessibility audit artifacts in repo.

### 2) Ticket lifecycle

#### Delivered

- Status model includes all required lifecycle states including `spam` terminal.
- Reopen behavior exists with reason requirement and configurable reopen window.

### 3) Assignment and routing

#### Delivered / Partial

- Manual assignment/reassignment with required reason and auditing exists.
- Auto-routing exists via configurable routing rules in `config/support.php` and service resolution logic.
- SLA escalation jobs/notifications exist.

#### Gap

- Full explicit “escalation ladder (time-based and severity-based)” policy-to-runtime behavior is partially present but not fully demonstrated as a configurable multi-step ladder (e.g., tier N escalation chains).

### 4) SLA

#### Delivered

- Per-priority SLA windows are implemented.
- Automated breach scanning/escalation command and job are implemented.
- Dashboard widgets expose SLA risk/breach metrics.

### 5) Communication

#### Delivered

- Confirmation and reply outbound communication implemented.
- Internal notes are explicitly private.

### 6) Knowledge and macros

#### Partial

- `TemplateResource` exists for template management.
- **Missing:** direct category-aware macro recommendation/insertion from ticket reply UI.

---

## Platform Admin Functional Specification Validation

### 1) Configurations

#### Delivered / Strongly implemented

- Runtime settings registry with typed values exists (`PlatformSettingsPage` + `PlatformSettingRegistry`).
- High-risk key protection includes permission gating, mandatory reason, and step-up password confirmation.
- Audit logging for setting changes exists.

#### Gap

- Spec mentions explicit validate -> approve (if high-risk) -> activate workflow. Current implementation enforces stronger auth and role permission but does not implement a distinct two-person approval workflow/state machine for high-risk settings.

### 2) Policies

#### Delivered

- Versioned policy model and publish flow exist.
- Effective dating and activation scheduling are present.
- Diff preview and rollback path via creating new draft versions are present.
- Policy change logging exists.

### 3) Health checks

#### Delivered

- Liveness/readiness/startup endpoints exist.
- Synthetic checks command exists and is scheduled in scheduler.
- Health checks cover ticket intake, email, queue processing, storage, Redis/DB, Stripe/FCM, and scheduler heartbeat.

### 4) Operations

#### Delivered / Partial

- Failed job triage page supports retry/requeue/discard and bulk retry-all.
- Integration logs page shows status/error/retry attempts.
- Incident/degraded mode setting is surfaced via health checks.

#### Gap

- Integration dashboard is currently read-focused; no direct replay/retry operation for failed integrations from the integration logs page itself.

### 5) Security admin

#### Delivered

- Security Admin page includes session policy snapshot, access review metrics, and dormant admin detection.
- Runbook linkage for secret rotation is present.

---

## Cross-cutting Contract / Delivery Gaps (High Risk)

1. **Lead / Pre-registration replacement appears regressed**
   - Plan expects `pre_registrations` + Filament resource.
   - Current migration includes `retire_pre_registrations` dropping the table.
   - No `PreRegistrationResource` or `PreRegistration` model currently exists.

2. **API contract mismatch with documented replacement paths**
   - Plan expects updated `/api/preregister` local storage path and `/api/mobcontact` 410 deprecation handling.
   - Current routes expose support ticket APIs but do not expose `POST /api/preregister` nor a 410 response route for `/api/mobcontact`.
   - Legacy-ish authenticated `v1/mob-contact` endpoint remains active.

These two points indicate the Legacy CRM replacement is not fully closed for lead/contact intake path consistency.

---

## Recommended Remediation Plan

1. **Re-introduce lead module to match plan or explicitly revise plan**
   - Decide whether `pre_registrations` is truly deprecated.
   - If still in-scope, restore table/model/resource and intake endpoint.
   - If out-of-scope now, update enhancement plan/docs to avoid false “delivered” claims.

2. **Fix API contract parity with migration notes**
   - Implement `POST /api/preregister` intake endpoint (or documented replacement route).
   - Add `/api/mobcontact` deprecation endpoint returning HTTP 410 with deprecation headers.
   - Sunset `v1/mob-contact` with migration notice/versioned deprecation timeline.

3. **Close CRM UX gaps**
   - Add dedicated triage workspace page (queue/timeline/context panel).
   - Add macro insertion + category suggestions in reply composer.
   - Add related-ticket similarity surfacing in ticket detail.

4. **Harden governance workflows**
   - Add optional dual-approval workflow for high-risk platform settings/policy classes.

5. **Add acceptance tests for functional-spec parity**
   - API contract tests for retired/replaced endpoints.
   - Filament feature tests for permission gates and high-risk action confirmations.
   - SLA scan/escalation integration tests.

---

## Final Assessment

- **CRM Functional Specification:** **Partially delivered** (core engine strong, UX/workspace and macros/recommendation pieces incomplete).
- **Platform Admin Functional Specification:** **Mostly delivered** (strong policy/config/health/security base, with approval-workflow and integration-ops depth still to complete).
- **Overall claim “completely delivered”:** **Not validated**.
