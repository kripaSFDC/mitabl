# mitabl Admin Panel - Plan, Design & Architecture

By: Usman Saleem

28-Feb-2026

---

## Decision Summary

- Keep the public marketing website public and unauthenticated. It remains focused on brand/commercial pages.
- Replace Legacy CRM capabilities with first-party modules in the Laravel backend + Filament admin portal.
- Build internal web apps using Filament PHP for:
  - Customer Service CRM
  - Operations (certification/approval)
  - Platform Administration (configuration, policies, health, controls)
- For mitabl every feature Legacy CRM currently does (certificate review, user lookup, support workflows) maps to Filament primitives:
  - Resource = CRUD manager for one model
  - Action = contextual operation with modal/form
  - Widget = dashboard card/chart/alert
- The admin panel will share the same DB and domain models already used by mobile APIs (`User`, `Mikitchn`, `Certificate`, `Order`, `Payment`, etc.).
- OUT OF SCOPE: 
  - No web-app for the end-users for now. There will be only mobile app that will remain the end-user product channel.
  - Rebuilding mobile app frontend.
  - Replatforming payments away from Stripe.
    
    

---

## Scope, Boundaries

- Legacy CRM replacement for:
  - Certificate approvals/workflows
  - Lead/pre-registration capture
  - Support case/ticket management
  - Internal user/kitchen lookup and operations workflows
- Internal portal for:
  - Customer Service
  - Operations
  - Platform Admin/Super Admin
- Platform controls:
  - Configuration and policies
  - Health checks and status pages
  - Queue/job visibility and operational actions
  - Audit trail and governance
- Marketing Website
  - Marketing site remains public and catchy.
    
    

---

## Current State - What Legacy CRM Does (today and will be replaced)

| Legacy CRM Capability           | Current implementation                                        | Status after this plan                                                 |
| ------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Kitchen certificate approval    | `PUT /api/kitchen/{id}/certificate` called from legacy CRM UI | Replaced by Filament `CertificateResource` with Approve/Reject actions |
| User lookup (mifoodi details)   | `GET /api/legacy/mifoodi` called from legacy CRM              | Replaced by Filament `UserResource`                                    |
| Pre-registration lead capture   | `POST /api/preregister` -> legacy CRM lead                    | Replaced by local `pre_registrations` + Filament                       |
| Contact/support case creation   | `POST /api/mobcontact` -> legacy CRM case                     | Replaced by local `support_tickets` + Filament                         |
| Kitchen profile sync (Account)  | `LegacyKitchenSyncListener` listener -> legacy CRM account    | Listener removed; data remains in mitabl DB                            |
| Legacy CRM account ID storage   | `legacy_kitchen_mappings` table                               | Table dropped after cutover                                            |
| Legacy CRM OAuth token workflow | `WebApiToCurlController::getAccToken()`                       | Removed entirely                                                       |

---

## Architecture Overview

#### Repository Strategy

- Internal ops portal is part of the existing `backend` repo/codebase.
- Public marketing website remains in the existing marketing website repo.
- No new repo required for the ops portal in this phase.
  
  

#### Deployment Topology

Use separate deployable services/containers:

- `marketing-web` container
  - serves public pages only
  - no admin auth surface
- `backend-api` container
  - serves `/api/*` for mobile and intake APIs
  - can also host Filament routes unless split is desired
- `ops-admin` container (recommended split from backend runtime)
  - same Laravel codebase/artifact as backend, but admin-focused entry route and scaling profile
  - isolates admin runtime concerns and access controls
- shared dependencies:
  - DB
  - Redis/queue
  - object storage

Ingress/routing example (same domain):

- `mitabl.com/*` -> `marketing-web`
- `mitabl.com/api/*` -> `backend-api`
- `mitabl.com/admin/*` -> `ops-admin` (authenticated + allowlist/MFA/protected)
- Optional:
  - `mitabl.com/ops/*` for selected admin modules if we want path segmentation by function

Note:

- `backend-api` and `ops-admin` can be built from the same image with different runtime env/entrypoint.

#### Surface 1: Public Marketing Website (keep)

- Public/commercial pages only.
- No admin or CRM business logic.
- Contact/lead forms submit to backend intake APIs.

#### Surface 2: Backend Core (Laravel API, source of truth)

- Existing mobile APIs remain.
- New CRM and platform-admin modules live in same Laravel codebase.
- Events/jobs drive automation.

#### Surface 3: Internal Admin Portal (Filament at `/admin`)

- Session-authenticated, role-gated.
- Multi-panel navigation by function:
  - Customer Service
  - Operations
  - Platform Admin

### Where the Admin Panel Lives

The admin panel is not a separate application. It is mounted inside `backend/`:

```text
backend/
|-- app/
|   |-- Filament/                  # admin panel code
|   |   |-- Resources/
|   |   |-- Pages/
|   |   `-- Widgets/
|   |-- Domain/                    # new domain services/workflows
|   |-- Http/Controllers/Api/      # existing mobile APIs + new intake APIs
|   `-- Models/                    # shared domain models
|-- database/
|   `-- migrations/
`-- routes/
    |-- api.php                    # mobile + intake APIs
    `-- web.php                    # marketing + admin auth routes
```

### Request Flow - Parallel Entry Points

```text
Mobile App (Flutter)                     Admin Browser (Ops/CS/Admin)
      |                                            |
      | JWT Bearer                                | Session auth
      v                                            v
routes/api.php                              routes/web.php (/admin/*)
      |                                            |
API middleware                               Filament auth + policies
      |                                            |
Controllers/Services                          Filament Resources/Pages
      |______________________________  ______________________________|
                                     \/
                               Eloquent Models
                                     |
                                  MySQL DB
```

Admin panel does not call mobile API endpoints. It uses domain services + Eloquent directly.



---



## Admin Authentication and Roles

Use separate admin identities from consumer/mobile users.

### Admin Identity Model

- Recommended: `admin_users` table + `AdminUser` model.
- Separate auth guard/provider from API JWT user auth.
- Supports least-privilege and avoids session/JWT boundary mistakes.

### RBAC Roles (Spatie)

| Role                          | Core permissions                                                          |
| ----------------------------- | ------------------------------------------------------------------------- |
| `super_admin`                 | Full access, IAM, policy/config changes, emergency ops                    |
| `platform_admin`              | Config/policy/health, integrations, feature flags, observability controls |
| `operations`                  | Certification workflows, kitchen lifecycle, onboarding approvals          |
| `customer_service`            | Tickets, dispute handling, user/order lookup, limited override actions    |
| `finance_readonly` (optional) | Read-only payments/refunds/reporting visibility                           |

### Permission Guardrails

- No implicit role inheritance; explicit permission mapping.
- High-risk actions require step-up confirmation:
  - Suspend account
  - Manual refund
  - Force status transitions
  - Policy changes affecting production behavior

---

## Feature Modules

## Module 1 - Dashboard (Home)

Purpose: real-time operational view at login.

Widgets:
| Widget | Data source | Refresh |
|---|---|---|
| Users by role (Foodies/Cooks) | `users` grouped by `role_id` | On load |
| Active kitchens | `mikitchns.status=1` | On load |
| Pending certificate approvals | `certificates.status=0` | Poll 30s |
| Open support tickets | `support_tickets.status in (open,in_progress,pending_user)` | Poll 30s |
| SLA breach risk | tickets due in next N mins / overdue | Poll 30s |
| Orders today | `orders.delivery_date=today` | On load |
| Revenue this month | `payments` joined with confirmed orders | On load |
| Queue health | failed jobs + queue latency snapshot | Poll 30s |
| Integration health | mail/storage/FCM/Stripe status checks | Poll 30s |
| Orders/day chart (30d) | `orders` grouped by date | On load |
| Registrations/day chart (30d) | `users` grouped by date | On load |

---

## Module 2 - Kitchen Certificate Management (replaces legacy CRM approval flow)

Resource: `CertificateResource`

Table:

- Kitchen, cook, phone, ABN, certificate number
- Upload date
- Document preview/download
- Status badge (Pending/Approved/Rejected)
- Reviewer, reviewed timestamp

Filters:

- Status
- Submission date range
- Kitchen/cook search

Actions:

- Approve
  - sets `status=1`
  - captures `reviewed_by`, `reviewed_at`
  - sends approved notification
- Reject
  - sets `status=2`
  - mandatory `rejection_reason`
  - captures reviewer metadata
  - sends rejection email + in-app notification
- Request Re-Submission (optional intermediate)
  - keeps ticket/workflow open for revised docs

Status values:

```text
0 = Pending review
1 = Approved
2 = Rejected
```

Required fields:

```php
$table->text('rejection_reason')->nullable();
$table->timestamp('reviewed_at')->nullable();
$table->foreignId('reviewed_by')->nullable()->constrained('admin_users');
```

Edge cases:

- Missing/invalid file type
- Multiple uploads during review
- Concurrent approvals by two agents
- Retry-safe notifications on queue retries

Replaces/removes:

- Legacy CRM approval endpoints/middleware
- Legacy CRM kitchen sync listener dependency

---

## Module 3 - User Management

Resource: `UserResource`

Table:

- ID, name, email, phone
- Role(s) and verification
- Account status (active/suspended/deleted)
- Order count and last activity

Actions:

- View profile timeline (orders, tickets, flags, notes)
- Edit profile (restricted fields)
- Suspend/Unsuspend (with reason)
- Soft delete / restore path (if policy permits)
- Link to kitchen/orders/tickets

New fields:

```php
$table->boolean('suspended')->default(false);
$table->text('suspension_reason')->nullable();
$table->timestamp('suspended_at')->nullable();
```

Edge cases:

- Prevent suspension of super admin accounts
- Prevent self-lockout for final super admin
- Audit every status change and reason

---

## Module 4 - Kitchen Management

Resource: `MikitchnResource`

Table:

- Kitchen ID/name, cook, location
- Kitchen status
- Certificate status
- Dine-in/take-away flags
- Rating/orders summary

Actions:

- View kitchen profile, media gallery, menu, reviews
- Activate/Deactivate kitchen
- Edit kitchen metadata
- Embedded certificate review panel

Edge cases:

- Status transitions blocked when certificate invalid
- Existing open bookings while attempting deactivation
- Data quality checks for geolocation and address fields

---

## Module 5 - Order Management

Resource: `OrderResource`

Table:

- Order ID, kitchen, customer
- Order/delivery dates
- Type (dine-in/take-away)
- Total, paid flag, refund state
- Status badge

Actions:

- View full order detail and payment metadata
- View cancel reason and timeline
- Manual override for exceptional cases (permission-gated)
- Trigger full refund via controlled service endpoint

Status reference (confirm exact mapping in code):

```text
1 = Completed
2 = Requested
3 = Confirmed
4 = Cancelled
```

Edge cases:

- Prevent duplicate refund execution
- Idempotent admin actions
- Mandatory rationale for manual override

---

## Module 6 - Support Ticket Management (replaces legacy CRM cases)

New tables:

- `support_tickets`
- `support_ticket_messages`
- `support_ticket_attachments` (recommended)
- `support_ticket_events` (recommended immutable audit stream)

Core ticket schema (minimum):

```php
Schema::create('support_tickets', function (Blueprint $table) {
    $table->id();
    $table->string('ticket_number')->unique();   // TKT-000001
    $table->foreignId('user_id')->nullable()->constrained('users');
    $table->string('requester_name')->nullable();
    $table->string('requester_email');
    $table->string('requester_phone')->nullable();
    $table->string('subject');
    $table->text('description');
    $table->string('source');                    // mobile_app, website, admin
    $table->string('category');                  // order_dispute,payment,account,general,other
    $table->string('priority')->default('normal');
    $table->string('status')->default('open');   // open,in_progress,pending_user,resolved,closed,spam
    $table->foreignId('assigned_to')->nullable()->constrained('admin_users');
    $table->foreignId('order_id')->nullable()->constrained('orders');
    $table->foreignId('mikitchn_id')->nullable()->constrained('mikitchns');
    $table->timestamp('first_response_due_at')->nullable();
    $table->timestamp('resolution_due_at')->nullable();
    $table->timestamp('first_responded_at')->nullable();
    $table->timestamp('resolved_at')->nullable();
    $table->timestamps();
    $table->index(['status', 'priority', 'assigned_to']);
});
```

Thread messages:

```php
Schema::create('support_ticket_messages', function (Blueprint $table) {
    $table->id();
    $table->foreignId('ticket_id')->constrained('support_tickets')->cascadeOnDelete();
    $table->string('sender_type'); // user, admin, system
    $table->unsignedBigInteger('sender_id')->nullable();
    $table->text('message');
    $table->boolean('is_internal_note')->default(false);
    $table->timestamps();
});
```

Resource: `SupportTicketResource`

Capabilities:

- Queue/list with SLA-aware sorting
- Assign/reassign ownership
- Change status/priority/category
- Public reply vs internal note
- Merge duplicate tickets
- Link to user/order/kitchen context
- Resolve/close with required resolution summary

CRM edge cases to support:

- Anonymous requester handling
- Duplicate detection (same requester + similar subject in short time)
- Spam/abuse throttling and spam state
- Collision handling when two agents edit same ticket
- SLA breach alerts/escalation routing
  
  

---

## Module 7 - Pre-Registration / Lead Management (replaces legacy CRM leads)

New table: `pre_registrations`

```php
Schema::create('pre_registrations', function (Blueprint $table) {
    $table->id();
    $table->string('first_name');
    $table->string('last_name');
    $table->string('email')->nullable();
    $table->string('phone')->nullable();
    $table->string('city')->nullable();
    $table->string('interested_as');   // cook, foodie, both
    $table->string('source');          // website, referral, campaign, admin
    $table->string('status')->default('new'); // new,contacted,converted,disqualified,spam
    $table->text('notes')->nullable();
    $table->foreignId('followed_up_by')->nullable()->constrained('admin_users');
    $table->timestamp('followed_up_at')->nullable();
    $table->timestamps();
    $table->index(['status', 'source']);
});
```

Resource: `PreRegistrationResource`

Actions:

- Mark contacted/converted/disqualified/spam
- Add follow-up notes
- Link conversion to created user account when available

Edge cases:

- Duplicate lead ingestion
- Email/phone normalization
- Consent and communication preference capture

---

## Module 8 - Promo Code Management

Resource: `PromoCodeResource` over existing `promo_codes`.

Actions:

- Create/edit/deactivate
- Usage history
- Guardrails for invalid overlapping rules

---

## Module 9 - Financial Overview (Read-Only + controlled refund action)

Resource: `PaymentResource`

Capabilities:

- Visibility into payment/refund states
- Link to order/user/kitchen
- External Stripe dashboard link (no secrets exposed)
- Controlled full refund action via service endpoint and strict permissions

Constraints:

- No direct key handling in UI
- All mutations idempotent and audited

---

## Module 10 - Platform Admin: Configuration & Policies

Purpose: replace Legacy CRM admin/process controls and centralize operational governance.

Resources/pages:

- `PlatformSettingsPage`
  - business toggles (feature flags)
  - support defaults (priority, routing)
  - approval requirements
  - maintenance banner / operational notices
- `PolicyResource`
  - SLA policy (first response, resolution windows)
  - escalation policy
  - suspension policy
  - refund policy constraints
  - document retention policy
- `TemplateResource`
  - email templates for ticket/certification flows
  - notification templates

Recommended data model:

- `platform_settings` (key/value, typed, versioned)
- `policies` (name, version, json, effective_at, active)
- `policy_change_log` (immutable audit)

Edge cases:

- Policy draft/publish workflow
- Validation by JSON schema before activation
- Blast-radius warning for high-impact policy changes

---

## Module 11 - Platform Admin: Health, Operations, and Observability

Purpose: operations control plane for platform stability.

Resources/pages:

- `SystemHealthPage`
  - DB connectivity/latency
  - Redis/queue health
  - mail provider status
  - storage disk status
  - Stripe and FCM connectivity checks
  - scheduler heartbeat and failed cron detection
- `QueueOpsPage`
  - failed jobs list
  - retry/discard/requeue actions
  - queue depth and age
- `IntegrationLogsPage`
  - outbound webhook/API calls
  - response status and error body snapshots
  - retry attempts
- `AuditLogResource`
  - who changed what, before/after snapshots, request metadata

Operational edge cases:

- queue saturation
- poison-message retries
- dead-letter handling
- partial outage mode (degraded features)
- incident annotation and postmortem link fields

---

## Module 12 - Internal Notes, Tags, Watchers, and Collaboration

Cross-module productivity features:

- Internal notes on users, kitchens, orders, tickets
- Tagging taxonomy (`fraud_risk`, `vip`, `repeat_issue`, etc.)
- Watchers/subscriptions for ticket updates
- Mentions in internal comments (future enhancement)

---

## Database Migrations Required

| Migration                             | Purpose                                                                       |
| ------------------------------------- | ----------------------------------------------------------------------------- |
| `add_rejected_fields_to_certificates` | `rejection_reason`, `reviewed_at`, `reviewed_by`, status support for rejected |
| `add_suspended_to_users`              | `suspended`, `suspension_reason`, `suspended_at`                              |
| `create_support_tickets`              | Ticket master table                                                           |
| `create_support_ticket_messages`      | Ticket conversation threads                                                   |
| `create_support_ticket_attachments`   | Attachment metadata                                                           |
| `create_support_ticket_events`        | Immutable event trail                                                         |
| `create_pre_registrations`            | Lead replacement table                                                        |
| `create_platform_settings`            | Runtime platform settings                                                     |
| `create_policies`                     | Versioned policy definitions                                                  |
| `create_policy_change_log`            | Policy audit trail                                                            |
| `create_admin_users`                  | Separate admin identity table                                                 |
| `drop_legacy_kitchen_mappings`        | Remove legacy CRM mapping table after cutover                                 |

---

## New / Modified Code Components

### New Filament Resources

```text
app/Filament/Resources/
|-- CertificateResource.php
|-- UserResource.php
|-- MikitchnResource.php
|-- OrderResource.php
|-- SupportTicketResource.php
|-- PreRegistrationResource.php
|-- PaymentResource.php
|-- PromoCodeResource.php
|-- PolicyResource.php
|-- AuditLogResource.php
`-- TemplateResource.php
```

### New Filament Widgets

```text
app/Filament/Widgets/
|-- PlatformStatsOverview.php
|-- OrdersPerDayChart.php
|-- NewUsersChart.php
|-- PendingCertificatesWidget.php
|-- OpenTicketsWidget.php
|-- SlaBreachWidget.php
|-- QueueHealthWidget.php
`-- IntegrationHealthWidget.php
```

### New Filament Pages

```text
app/Filament/Pages/
|-- Dashboard.php
|-- PlatformSettingsPage.php
|-- SystemHealthPage.php
`-- QueueOpsPage.php
```

### New Models

```text
app/Models/
|-- AdminUser.php
|-- SupportTicket.php
|-- SupportTicketMessage.php
|-- SupportTicketAttachment.php
|-- SupportTicketEvent.php
|-- PreRegistration.php
|-- PlatformSetting.php
|-- Policy.php
`-- PolicyChangeLog.php
```

### New Mailables

```text
app/Mail/
|-- CertificateRejected.php
|-- SupportTicketConfirmation.php
|-- SupportTicketReply.php
|-- PreRegistrationAcknowledgement.php
`-- SlaEscalationAlert.php
```

### New/Modified API Endpoints

| Method | Route                           | Change                                            |
| ------ | ------------------------------- | ------------------------------------------------- |
| `POST` | `/api/support/ticket`           | New ticket intake (replaces legacy CRM case path) |
| `GET`  | `/api/support/ticket/{id}`      | User-side status lookup (scoped access)           |
| `POST` | `/api/preregister`              | Modified to store local lead                      |
| `POST` | `/api/mobcontact`               | Deprecated endpoint; responds with 410            |
| `PUT`  | `/api/kitchen/{id}/certificate` | Removed (legacy CRM inbound)                      |
| `GET`  | `/api/legacy/mifoodi`           | Removed (legacy CRM inbound)                      |

Backward compatibility:

- No compatibility alias required for greenfield deployments.
- `/api/mobcontact` responds with 410 and deprecation headers when called.
  
  

---

## 

## CRM Functional Specification (Delivered)

### CRM Agent UX Requirements (Customer Service + Operations)

- Single-screen triage lawet:
  - left: queue/inbox with fast filters,
  - center: conversation/ticket timeline,
  - right: contextual profile (user, kitchen, orders, payment summary).
- Productivity-first interactions:
  - keyboard shortcuts for assign/status/reply,
  - saved views (`My Queue`, `Unassigned`, `SLA Risk`, `Ops Certificates Pending`),
  - bulk actions with confirmation for high-risk changes.
- Clear visual hierarchy:
  - color-safe status badges,
  - SLA countdown chips (`on track`, `at risk`, `breached`),
  - unread/new indicators and sticky action bar.
- Friction reduction:
  - canned macros/templates with variables,
  - auto-suggest related tickets and similar past resolutions,
  - one-click jump links to user/order/kitchen resources.
- Safe operations UX:
  - irreversible actions require typed confirmation,
  - optimistic UI only where idempotent; otherwise explicit completion feedback,
  - collision detection with "updated by another agent" conflict resolution modal.
- Accessibility and device support:
  - WCAG AA contrast baseline,
  - full keyboard navigability and visible focus,
  - usable 1280px desktop baseline with responsive fallback for tablet.

### Ticket Lifecycle

- `open` -> `in_progress` -> `pending_user` -> `resolved` -> `closed`
- `spam` terminal state for abuse/noise
- Reopen rules:
  - allowed within configurable window after resolve
  - requires reason

### Assignment and Routing

- Auto-routing by category/priority/policy.
- Manual reassignment with audit reason.
- Escalation ladder (time-based and severity-based).

### SLA

- Define per category/priority:
  - first response target
  - resolution target
- Automated breach flags, notifications, and escalation.

### Communication

- Outbound email confirmation and reply notifications.
- Internal notes never exposed to requester.
- Optional later extension: in-app ticket thread for authenticated users.

### Knowledge and Macros

- Canned responses/templates by category.
- Tag-based recommendations for frequent issue patterns.

### Data Governance

- PII masking in list views where not required.
- Ticket/message retention policy.
- Export with role-based redaction.

---

## Platform Admin Functional Specification (Delivered)

### Configurations

- Runtime settings registry:
  - support defaults
  - onboarding policy toggles
  - maintenance/operational flags
- Change workflow:
  - validate
  - approve (if high-risk)
  - activate with audit trail

### Policies

- Versioned JSON policy documents.
- Effective dating and rollback.
- Diff view before publishing.

### Health Checks

- Liveness/readiness endpoints.
- Scheduled synthetic checks for key flows:
  - ticket intake
  - email dispatch
  - queue processing
  - storage read/write

### Operations

- Failed job triage with bulk retry.
- Integration failure dashboard.
- Incident mode flag (degraded operation handling).

### Security Admin

- Admin session policy (expiry, re-auth for sensitive actions).
- API key/secret rotation runbook.
- Access review report and dormant admin detection.

---

## Dependency Summary

```bash
# required
composer require filament/filament:"^3.0"
composer require spatie/laravel-permission

# recommended
composer require laravel/horizon
composer require owen-it/laravel-auditing
```

No separate hosting tier is required for the internal portal.



--- 

## Testing, UAT, and Cutover Acceptance

### Must-pass automated tests

- Certificate approve/reject/resubmit paths
- Ticket intake, assignment, SLA transitions, close/reopen
- Role boundary tests for all high-risk resources/actions
- Policy publish/rollback behavior
- Health check and queue operational pages permissions

### UAT scenarios

- Customer service day-in-the-life workflows
- Operations certificate triage under load
- Platform admin emergency runbook execution

### Cutover acceptance criteria

- 100% parity for legacy CRM flows used in production
- No data loss for prereg/support submissions
- Ticket SLA timers accurate in production timezone
- Zero unresolved P1 security findings

---



* * *

# IMPLEMENTATION DONE

* * *

## Tasks Implemented

## Phase 0 - Repository and Deployment Foundations

| #   | Task                                       |
| --- | ------------------------------------------ |
| 0.1 | Finalize repo boundaries                   |
| 0.2 | Define same-domain ingress routes          |
| 0.3 | Decide runtime split                       |
| 0.4 | Configure TLS and path-based gateway rules |
| 0.5 | Configure admin network controls           |
| 0.6 | Add deployment environments                |
| 0.7 | Add secrets management plan                |

## Phase 0.5 - Platform Hardening Baseline

Purpose: remove known production blockers before building Filament modules. No feature/module work should start until this phase is complete.

| #      | Task                                                           |
| ------ | -------------------------------------------------------------- |
| 0.5.1  | Upgrade PHP runtime baseline to 8.2+                           |
| 0.5.2  | Upgrade Laravel from 8 to 12                                   |
| 0.5.3  | Upgrade mobile toolchain to Dart 3+                            |
| 0.5.4  | Enforce asynchronous queue in non-test environments            |
| 0.5.5  | Deploy dedicated queue workers                                 |
| 0.5.6  | Switch cache backend to Redis                                  |
| 0.5.7  | Add cache wrappers for discovery endpoints                     |
| 0.5.8  | Remove wasteful double-fetch pagination patterns               |
| 0.5.9  | Add cache invalidation hooks                                   |
| 0.5.10 | Extract payment logic from `StripeTrait` into `PaymentService` |
| 0.5.11 | Introduce core service layer for large controllers             |
| 0.5.12 | Remove Legacy CRM secrets and static tokens from source        |
| 0.5.13 | Add observability for async + cache behavior                   |
| 0.5.14 | Add regression tests for hardening work                        |
| 0.5.15 | Define hardening exit criteria                                 |

## Phase 1 - Foundation

| #    | Task                                      |
| ---- | ----------------------------------------- |
| 1.1  | Install Filament panel                    |
| 1.2  | Scaffold admin panel                      |
| 1.3  | Create `AdminUser` model/migration/seeder |
| 1.4  | Install Spatie permission                 |
| 1.5  | Configure panel branding                  |
| 1.6  | Add certificate migration changes         |
| 1.7  | Add user suspension fields                |
| 1.8  | Create support ticket tables              |
| 1.9  | Create pre-registration table             |
| 1.10 | Create platform settings/policy tables    |

## Phase 2 - Core Resources

| #   | Task                                               |
| --- | -------------------------------------------------- |
| 2.1 | Build `CertificateResource` with approve/reject    |
| 2.2 | Build certificate mail/notification templates      |
| 2.3 | Build `UserResource` with suspension controls      |
| 2.4 | Build `MikitchnResource` with embedded cert panel  |
| 2.5 | Build `OrderResource` and controlled refund action |
| 2.6 | Build `PromoCodeResource`                          |

## Phase 3 - CRM

| #    | Task                                                                        |
| ---- | --------------------------------------------------------------------------- |
| 3.1  | Build ticket models + relationships + indexes                               |
| 3.2  | Build `SupportTicketResource` with full agent workflow                      |
| 3.3  | Build intake and conversation APIs                                          |
| 3.4  | Build spam/abuse protections for CRM intake                                 |
| 3.5  | Build ticket automations                                                    |
| 3.6  | Build `PreRegistrationResource` with operator workflow                      |
| 3.7  | Replace legacy CRM behavior inside `/api/preregister` and `/api/mobcontact` |
| 3.8  | Build CRM communications layer                                              |
| 3.9  | Build Customer Service UX flows in Filament                                 |
| 3.10 | Build Operations UX flows in Filament                                       |
| 3.11 | Build user-friendly data presentation                                       |
| 3.12 | Add accessibility and usability standards                                   |
| 3.13 | Build CRM analytics widgets                                                 |
| 3.14 | UAT with CS/Ops and iterate UX                                              |
| 3.15 | Finalize CRM playbooks and training assets                                  |

## Phase 4 - Platform Admin and Health

| #   | Task                                         |
| --- | -------------------------------------------- |
| 4.1 | Build `PlatformSettingsPage`                 |
| 4.2 | Build `PolicyResource` + versioning workflow |
| 4.3 | Build `SystemHealthPage`                     |
| 4.4 | Build `QueueOpsPage`                         |
| 4.5 | Build dashboard widgets for SLA/health       |
| 4.6 | Add immutable audit logs for admin actions   |

## Phase 5 - Legacy CRM Cutover

| #   | Task                                                                 |
| --- | -------------------------------------------------------------------- |
| 5.1 | Execute contract parity suite in staging                             |
| 5.2 | Run shadow-read/dual-observe period (no legacy CRM write dependence) |
| 5.3 | Cut traffic to internal modules only                                 |
| 5.4 | Keep `/api/mobcontact` as compatibility alias                        |
| 5.5 | Remove legacy CRM runtime dependencies from code                     |
| 5.6 | Remove legacy CRM persistence artifacts                              |
| 5.7 | Remove legacy CRM secrets and rotate exposed credentials             |
| 5.8 | Verify zero legacy CRM traffic in production logs                    |
| 5.9 | Sign-off on no-impact outcomes                                       |

## Phase 5.5 - Deployment and Release Tasks

| #      | Task                                                 |
| ------ | ---------------------------------------------------- |
| 5.5.1  | Build container image(s) for backend and ops         |
| 5.5.2  | Deploy `ops-admin` to staging under same-domain path |
| 5.5.3  | Configure ingress and WAF rules                      |
| 5.5.4  | Configure horizontal scaling policies                |
| 5.5.5  | Queue worker deployment separation                   |
| 5.5.6  | Add health probes                                    |
| 5.5.7  | Add zero-downtime DB migration steps                 |
| 5.5.8  | Configure centralized logs/metrics/traces            |
| 5.5.9  | Define rollback runbook                              |
| 5.5.10 | Production cutover rehearsal                         |

## Phase 6 - Hardening

| #   | Task                                          |
| --- | --------------------------------------------- |
| 6.1 | Redis queue + Horizon                         |
| 6.2 | Add intake throttles and abuse controls       |
| 6.3 | Feature tests: certificate flow               |
| 6.4 | Feature tests: ticket lifecycle + SLA         |
| 6.5 | Feature tests: policy permissions             |
| 6.6 | Load tests on ticket intake and admin lists   |
| 6.7 | Disaster recovery runbook + backup validation |



---
