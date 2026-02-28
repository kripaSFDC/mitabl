# mitabl Admin Panel - Plan, Design & Architecture

## Decision Summary (Revised)
- Keep the public marketing website public and unauthenticated. It remains focused on brand/commercial pages.
- Replace Salesforce capabilities with first-party modules in the Laravel backend + Filament admin portal.
- Build internal web apps for:
  - Customer Service CRM
  - Operations (certification/approval)
  - Platform Administration (configuration, policies, health, controls)
- Do not build an end-user web app in this phase. Mobile remains the end-user product channel.

---

## What is Filament PHP?
Filament is a Laravel admin panel framework - think of it as the "missing backend UI" for any Laravel app. It installs into your existing Laravel project via Composer and builds a reactive web admin interface from Eloquent models. There is no separate React/Vue app, no separate API tier, no separate hosting stack.

For mitabl specifically: every feature Salesforce currently does (certificate review, user lookup, support workflows) maps to Filament primitives:
- Resource = CRUD manager for one model
- Action = contextual operation with modal/form
- Widget = dashboard card/chart/alert

The admin panel shares the same DB and domain models already used by mobile APIs (`User`, `Mikitchn`, `Certificate`, `Order`, `Payment`, etc.).

Filament is a first-party Laravel admin and CRUD framework built on [Livewire](https://livewire.laravel.com/) and [Alpine.js](https://alpinejs.dev/). It enables reactive admin UIs in PHP without building a separate SPA.

Key characteristics relevant to mitabl:

| Property | Detail |
|---|---|
| Lives inside `backend/` | Installed via Composer in the same Laravel app; same models, DB, queues. |
| Eloquent-native | Existing models are used directly; no admin API duplication. |
| Reactive without custom JS app | Tables/forms/modals/notifications are reactive via Livewire. |
| RBAC-ready | Integrates cleanly with `spatie/laravel-permission`. |
| Themeable | Tailwind-based theme, easy branding to mitabl style. |
| Extensible | Custom pages, widgets, actions, workflows in plain PHP classes. |

Why this fits mitabl: the replacement scope is internal ops CRM and platform admin, not a consumer-facing web app.

---

## Scope, Boundaries, and Non-Goals

### In Scope
- Salesforce replacement for:
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

### Out of Scope (this phase)
- Rebuilding mobile app frontend.
- Building customer-facing authenticated web app.
- Replatforming payments away from Stripe.

### Marketing Website Rule (Explicit)
- Marketing site remains public and catchy.
- No login required for marketing pages.
- Marketing pages must not own CRM/system-of-record logic.
- Marketing forms should call backend intake APIs, not third-party CRM forms directly.

---

## Current State - What Salesforce Does (and What Dies With It)

| SF Capability | Current implementation | Status after this plan |
|---|---|---|
| Kitchen certificate approval | `PUT /api/kitchen/{id}/certificate` called from SF UI | Replaced by Filament `CertificateResource` with Approve/Reject actions |
| User lookup (mifoodi details) | `GET /api/sales/mifoodi` called from SF | Replaced by Filament `UserResource` |
| Pre-registration lead capture | `POST /api/preregister` -> SF Lead | Replaced by local `pre_registrations` + Filament |
| Contact/support case creation | `POST /api/mobcontact` -> SF Case | Replaced by local `support_tickets` + Filament |
| Kitchen profile sync (Account) | `KitchenVerifiedToSales` listener -> SF Account | Listener removed; data remains in mitabl DB |
| SF Account CRM ID storage | `sales_kitchens` table | Table dropped after cutover |
| SF OAuth token workflow | `WebApiToCurlController::getAccToken()` | Removed entirely |

---

## Architecture Overview

## Repository Strategy (Explicit)

Recommended:
- Internal ops portal is part of the existing `backend` repo/codebase.
- Public marketing website remains in the existing marketing website repo.
- No new repo required for the ops portal in this phase.

Why:
- Ops portal uses backend domain models/services directly.
- Avoids API duplication and cross-repo contract drift.
- Faster delivery and simpler security/governance.

Alternative (not recommended now):
- Separate ops repo only if you later require independent team ownership and release trains.

## Deployment Topology (Explicit)

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
  - `mitabl.com/ops/*` for selected admin modules if you want path segmentation by function

Note:
- `backend-api` and `ops-admin` can be built from the same image with different runtime env/entrypoint.

## Surface 1: Public Marketing Website (keep)
- Public/commercial pages only.
- No admin or CRM business logic.
- Contact/lead forms submit to backend intake APIs.

## Surface 2: Backend Core (Laravel API, source of truth)
- Existing mobile APIs remain.
- New CRM and platform-admin modules live in same Laravel codebase.
- Events/jobs drive automation.

## Surface 3: Internal Admin Portal (Filament at `/admin`)
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
| Role | Core permissions |
|---|---|
| `super_admin` | Full access, IAM, policy/config changes, emergency ops |
| `platform_admin` | Config/policy/health, integrations, feature flags, observability controls |
| `operations` | Certification workflows, kitchen lifecycle, onboarding approvals |
| `customer_service` | Tickets, dispute handling, user/order lookup, limited override actions |
| `finance_readonly` (optional) | Read-only payments/refunds/reporting visibility |

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

## Module 2 - Kitchen Certificate Management (replaces SF approval flow)

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
- Salesforce approval endpoints/middleware
- Salesforce kitchen sync listener dependency

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

## Module 6 - Support Ticket Management (replaces SF Cases)

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
- Attachment size/type malware scanning policy
- PII redaction policy for exports and notifications

---

## Module 7 - Pre-Registration / Lead Management (replaces SF Leads)

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

Purpose: replace Salesforce admin/process controls and centralize operational governance.

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
- Rollback to previous policy version
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

| Migration | Purpose |
|---|---|
| `add_rejected_fields_to_certificates` | `rejection_reason`, `reviewed_at`, `reviewed_by`, status support for rejected |
| `add_suspended_to_users` | `suspended`, `suspension_reason`, `suspended_at` |
| `create_support_tickets` | Ticket master table |
| `create_support_ticket_messages` | Ticket conversation threads |
| `create_support_ticket_attachments` | Attachment metadata |
| `create_support_ticket_events` | Immutable event trail |
| `create_pre_registrations` | Lead replacement table |
| `create_platform_settings` | Runtime platform settings |
| `create_policies` | Versioned policy definitions |
| `create_policy_change_log` | Policy audit trail |
| `create_admin_users` | Separate admin identity table |
| `drop_sales_kitchens` | Remove SF mapping table after cutover |

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

| Method | Route | Change |
|---|---|---|
| `POST` | `/api/support/ticket` | New ticket intake (replaces SF case path) |
| `GET` | `/api/support/ticket/{id}` | User-side status lookup (scoped access) |
| `POST` | `/api/preregister` | Modified to store local lead |
| `POST` | `/api/mobcontact` | Kept as deprecated alias to `/api/support/ticket` during transition |
| `PUT` | `/api/kitchen/{id}/certificate` | Removed (SF inbound) |
| `GET` | `/api/sales/mifoodi` | Removed (SF inbound) |

Backward compatibility:
- Keep `/api/mobcontact` alias for one release window.
- Emit deprecation headers/log warning.
- Remove after client updates are completed.

### Code to Delete (Salesforce removal)

```text
app/Listeners/KitchenVerifiedToSales.php
app/Http/Controllers/Api/Sales/...
app/Http/Middleware/SalesForce.php
app/Models/SalesKitchen.php
Salesforce logic inside WebApiToCurlController
EventServiceProvider SF listener bindings
Kernel salesforce middleware alias
SF route group in routes/api.php
```

Note: remove `KitchenVerified` event only if no non-SF listeners remain.

### Env Variables to Remove

```text
SALES_AUTH
SF_CLIENT_ID
SF_CLIENT_SECRET
SF_USERNAME
SF_PASSWORD
```

---

## Implementation Tasks

## Phase 0 - Repository and Deployment Foundations (Week 0)
| # | Task | Notes |
|---|---|---|
| 0.1 | Finalize repo boundaries | `backend` owns ops portal; marketing remains separate repo |
| 0.2 | Define same-domain ingress routes | `/` marketing, `/api/*` backend, `/admin/*` ops portal |
| 0.3 | Decide runtime split | one shared image with 2 services (`backend-api`, `ops-admin`) |
| 0.4 | Configure TLS and path-based gateway rules | certs + HSTS + strict rules on `/admin/*` |
| 0.5 | Configure admin network controls | IP allowlist/VPN and MFA policy |
| 0.6 | Add deployment environments | dev, staging, prod parity for all 3 services |
| 0.7 | Add secrets management plan | remove hardcoded secrets, use vault/secret store |

## Phase 1 - Foundation (Week 1)
| # | Task | Notes |
|---|---|---|
| 1.1 | Install Filament panel | `composer require filament/filament:"^3.0"` |
| 1.2 | Scaffold admin panel | `php artisan filament:install --panels` |
| 1.3 | Create `AdminUser` model/migration/seeder | Separate from mobile `User` |
| 1.4 | Install Spatie permission | Define role/permission matrix |
| 1.5 | Configure panel branding | Logo/colors/navigation |
| 1.6 | Add certificate migration changes | reject metadata fields |
| 1.7 | Add user suspension fields | |
| 1.8 | Create support ticket tables | tickets/messages/events/attachments |
| 1.9 | Create pre-registration table | |
| 1.10 | Create platform settings/policy tables | |

## Phase 2 - Core Resources (Weeks 2-3)
| # | Task | Notes |
|---|---|---|
| 2.1 | Build `CertificateResource` with approve/reject | include concurrency protection |
| 2.2 | Build certificate mail/notification templates | queue-based |
| 2.3 | Build `UserResource` with suspension controls | audited actions |
| 2.4 | Build `MikitchnResource` with embedded cert panel | |
| 2.5 | Build `OrderResource` and controlled refund action | idempotent |
| 2.6 | Build `PromoCodeResource` | |

## Phase 3 - CRM (Weeks 3-4)
| # | Task | Notes |
|---|---|---|
| 3.1 | Build ticket models + relationships | |
| 3.2 | Build `SupportTicketResource` thread/assignment/SLA | |
| 3.3 | Build ticket mailables | confirmation/reply/escalation |
| 3.4 | Build `/api/support/ticket` endpoint | spam-safe + rate limit |
| 3.5 | Build `/api/support/ticket/{id}` endpoint | scoped visibility |
| 3.6 | Build `PreRegistrationResource` | |
| 3.7 | Modify `/api/preregister` storage path | remove SF call |
| 3.8 | Add lead acknowledgment mailable | |
| 3.9 | Update marketing forms to backend intake APIs | no direct SF forms |

## Phase 4 - Platform Admin and Health (Week 4)
| # | Task | Notes |
|---|---|---|
| 4.1 | Build `PlatformSettingsPage` | runtime toggles/config |
| 4.2 | Build `PolicyResource` + versioning workflow | draft/publish/rollback |
| 4.3 | Build `SystemHealthPage` | DB/queue/mail/storage/FCM/Stripe checks |
| 4.4 | Build `QueueOpsPage` | retry/discard/requeue |
| 4.5 | Build dashboard widgets for SLA/health | |
| 4.6 | Add immutable audit logs for admin actions | |

## Phase 5 - Salesforce Cutover (Week 5)
| # | Task | Notes |
|---|---|---|
| 5.1 | Staging parity tests vs current SF workflows | approval, lead, support |
| 5.2 | Enable dual-write/read shadow period (optional, 1 week) | validate confidence |
| 5.3 | Switch traffic to internal modules | |
| 5.4 | Keep `/api/mobcontact` compatibility alias | temporary |
| 5.5 | Remove SF middleware/routes/controllers/listeners | |
| 5.6 | Drop `sales_kitchens` table | post-validation |
| 5.7 | Remove SF secrets/env vars | |

## Phase 5.5 - Deployment and Release Tasks (parallel to cutover)
| # | Task | Notes |
|---|---|---|
| 5.5.1 | Build container image(s) for backend and ops | same artifact, separate services recommended |
| 5.5.2 | Deploy `ops-admin` to staging under same-domain path | e.g. `staging.mitabl.com/admin/*`, restricted access |
| 5.5.3 | Configure ingress and WAF rules | tighter rules for admin than public/api |
| 5.5.4 | Configure horizontal scaling policies | api and admin tuned separately |
| 5.5.5 | Queue worker deployment separation | dedicate workers for CRM notifications/escalations |
| 5.5.6 | Add health probes | liveness/readiness/startup probes per service |
| 5.5.7 | Add zero-downtime DB migration steps | pre-deploy, deploy, post-deploy phases |
| 5.5.8 | Configure centralized logs/metrics/traces | tagged by `marketing`, `api`, `admin` |
| 5.5.9 | Define rollback runbook | route rollback + migration rollback strategy |
| 5.5.10 | Production cutover rehearsal | full dry-run in staging with timing and owners |

## Phase 6 - Hardening (Week 6)
| # | Task | Notes |
|---|---|---|
| 6.1 | Redis queue + Horizon | async stability |
| 6.2 | Add intake throttles and abuse controls | API + captcha if needed |
| 6.3 | Feature tests: certificate flow | approve/reject/resubmit |
| 6.4 | Feature tests: ticket lifecycle + SLA | |
| 6.5 | Feature tests: policy permissions | role boundary checks |
| 6.6 | Load tests on ticket intake and admin lists | |
| 6.7 | Disaster recovery runbook + backup validation | |

---

## CRM Functional Specification (Detailed)

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

## Platform Admin Functional Specification (Detailed)

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

## Security Considerations

| Risk | Mitigation |
|---|---|
| Admin session and mobile JWT cross-contamination | Separate `AdminUser` guard/provider |
| Brute-force on `/admin/login` | Login throttling + optional IP allowlisting + MFA |
| Unauthorized approval/refund actions | Permission-gated actions + policy checks + step-up confirmation |
| Sensitive docs exposure | Signed temporary URLs + strict storage access policy |
| Ticket spam abuse | Rate limits + honeypot/captcha on public forms + spam status |
| Duplicate action execution | Idempotency keys + DB transaction locks |
| Lost auditability | Immutable audit log with actor, before/after, correlation ID |
| PII overexposure | Field-level masking and export redaction by role |

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
- 100% parity for legacy SF flows used in production
- No data loss for prereg/support submissions
- Ticket SLA timers accurate in production timezone
- Zero unresolved P1 security findings

---

## Rollout and Risk Management

### Rollout strategy
- Feature-flagged module rollout by team:
  - week 1: internal pilot
  - week 2: CS
  - week 3: Ops
  - week 4: full admin

### Rollback strategy
- Keep compatibility alias routes temporarily.
- Keep Salesforce code path disabled but recoverable for a short fallback window.
- DB migrations designed with reversible steps where possible.

### Deployment rollback specifics
- Ingress rollback for `/admin/*` path to maintenance page or previous service if needed.
- Blue/green or canary switch for `backend-api` and `ops-admin`.
- Keep previous container image digest pinned and ready for instant redeploy.
- Run post-rollback data integrity checks (tickets, certificate states, lead intake).

---

## Final Notes
- This plan keeps the marketing website unchanged in purpose (public, no auth), while removing CRM dependency from Salesforce.
- It introduces a robust internal admin/CRM platform with explicit governance, observability, and edge-case handling.
- It stays aligned with current mitabl architecture: Laravel backend as system of record, Flutter as end-user channel.
