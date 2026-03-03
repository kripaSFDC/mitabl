# mitabl

**mitabl** is a home-cooked food marketplace platform that connects **Foodies** (customers) with **Cooks** operating virtual kitchens (**miKitchens**). The codebase is a mono-repo containing:

- A Laravel backend API and operations console.
- A Flutter mobile app serving both Foodie and Cook journeys.
- A static marketing website served by nginx.
- Deployment manifests, operational scripts, and runbooks.

This document is intentionally detailed and aligned to the **current codebase state**.

---

## Table of Contents

1. [Platform Summary](#1-platform-summary)
2. [Mono-Repo Structure](#2-mono-repo-structure)
3. [Backend (`backend/`) Deep Dive](#3-backend-backend-deep-dive)
4. [Mobile App (`mobile-app/`) Deep Dive](#4-mobile-app-mobile-app-deep-dive)
5. [Marketing Website (`website/`) Deep Dive](#5-marketing-website-website-deep-dive)
6. [CRM + Support Operations](#6-crm--support-operations)
7. [Platform Admin (Filament) Features](#7-platform-admin-filament-features)
8. [Personas and RBAC Profiles](#8-personas-and-rbac-profiles)
9. [ACCESS MATRIX (Current State)](#9-access-matrix-current-state)
10. [Data Model and Domain Highlights](#10-data-model-and-domain-highlights)
11. [Local Development Setup](#11-local-development-setup)
12. [CI/CD and Quality Gates](#12-cicd-and-quality-gates)
13. [Security, Secrets and Operational Notes](#13-security-secrets-and-operational-notes)

---

## 1) Platform Summary

### What mitabl enables

- **Foodies** can discover kitchens, browse menu items, place orders, manage payments/cards, and leave reviews.
- **Cooks** can onboard as miKitchen operators, manage profiles and menu, receive bookings/orders, and handle fulfillment status updates.
- **Operations/Admin teams** can use a Filament admin console for certificate review, customer support, order interventions, payments visibility, policy governance, queue/health operations, and IAM controls.
- **CRM intake** supports support-ticket workflows with event/message tracking.
- **Legacy pre-registration intake is retired** and no longer part of active product functionality; onboarding is handled through standard account registration and support-ticket flows only.

### High-level runtime topology

- Mobile app -> Backend API (`backend/routes/api.php`)
- Website public pages are static marketing content (no website->backend runtime integration)
- Admin operators -> Filament panel in backend (`/admin` by default)
- MySQL datastore + queue/Horizon-backed async operations

---

## 2) Mono-Repo Structure

```text
mitabl/
├── backend/                      # Laravel API + Filament admin + business services
├── mobile-app/                   # Flutter iOS/Android app (Foodie + Cook)
├── website/                      # Static marketing web frontend (nginx-served)
├── deploy/                       # Docker manifests (windows test + contabo prod), env templates, load tests
├── docs/                         # SOPs, validation reports, secrets management docs
├── .github/workflows/ci-cd.yml   # CI pipelines for secret scan + app tests
└── docker-compose.yml            # Canonical Windows test orchestration
```

### Additional important folders

- `deploy/environments/{dev,staging,prod}`: app-specific environment templates.
- `deploy/load-tests`: k6 performance scripts for admin list pages.
- `docs/`: CRM playbook, legacy cutover validation, and secret-handling guidance.

---

## 3) Backend (`backend/`) Deep Dive

### Core stack

| Layer | Current stack |
|---|---|
| Language | PHP 8.2 |
| Framework | Laravel 12 |
| API Auth | JWT (`tymon/jwt-auth`) + Sanctum package present |
| Admin Console | Filament 3 |
| Authorization | `spatie/laravel-permission` |
| Auditing | `owen-it/laravel-auditing` |
| Payments | Stripe (`stripe/stripe-php`) |
| API docs | L5 Swagger |
| Queue monitoring | Horizon |
| Tests | PHPUnit 11 |

### API surface overview

`backend/routes/api.php` includes:

- **Health endpoints**: `/health`, `/health/live`, `/health/startup`, `/health/ready`.
- **Public endpoints**: login/register/OTP/password-reset and support ticket create/reply/read.
- **Authenticated v1 group** with middleware: `auth:api` + `api.user.active`.
- **Role-gated route groups**:
  - `customer` middleware: discovery, favorites, ordering, customer payments, customer reviews.
  - `restaurant` middleware: kitchen/profile/menu management, incoming order handling, cook-side operations.

### Key backend modules

1. **Identity & account lifecycle**
   - User auth, OTP verification, password reset, profile updates, device token updates.
2. **Kitchen management**
   - miKitchen profile creation/editing, certificates, timings, open/close toggles, dashboard data.
3. **Menu and discovery**
   - Food CRUD, availability toggles, nearest/top-rated/recommended/filter endpoints.
4. **Orders**
   - Order creation, status updates, booked date/time validation, order detail retrieval, customer/cook order views.
5. **Payments and payout flows**
   - Card add/list, payment intents, checkout session support, transfer/refund admin actions.
6. **Support/CRM intake**
   - Support ticket API endpoints and associated domain models.
7. **Notifications and reviews**
   - Notification feed retrieval and bi-directional review flows.

### Admin/API boundary hardening

`EnsureApiUserIsActive` enforces:
- Suspended API users are denied.
- Admin identities (role_id 1 path) are denied on API guard and instructed to use web admin login.

---

## 4) Mobile App (`mobile-app/`) Deep Dive

The Flutter app is a **single binary** with dual marketplace experiences.

### Architecture and module layout

```text
mobile-app/lib/
├── main.dart                     # entrypoint
├── app.dart                      # app setup, theme, providers
├── route_generator.dart          # named route wiring
├── auth_bloc/authentication/     # authentication state machine
├── repos/                        # repository abstraction for API calls
├── model/                        # data models/DTOs
├── pages/                        # Foodie-facing feature set
└── pages_cook/                   # Cook-facing feature set
```

### Foodie feature areas (`lib/pages`)

- Landing and role selection UX.
- Login, signup, OTP, forgot-password flows.
- Home/discovery views and kitchen exploration.
- Foodie profile and profile editing.
- Cook onboarding handoff entry (`profile_signup_cook`) for users converting to Cook flow.

### Cook feature areas (`lib/pages_cook`)

- Dashboard with business/booking context.
- Kitchen profile editing and public profile management.
- Menu management (list, add/edit item, detail pages).
- Incoming requests and bookings (current + upcoming).
- Customer detail view and received review context.
- Settings and account-level controls.

### Mobile dependency highlights

- State: `flutter_bloc`, `equatable`, `formz`.
- Storage/config: `shared_preferences`, `global_configuration`, `path_provider`.
- UI/media: `flutter_svg`, `google_fonts`, `cached_network_image`, `carousel_slider`, `image_picker`.
- Input/UX helpers: `pinput`, `fluttertoast`, `flutter_switch`, `flutter_rating_bar`.
- Integrations: `url_launcher`, `intl`.

### Mobile capabilities summary

- Supports both personas (Foodie/Cook) without app switching.
- Centralized auth lifecycle and API repository layer simplify feature additions.
- Structured pages split keeps customer and operator experiences independently evolvable.


### Mobile backend URL + API version configuration

The app reads backend endpoints at startup from:

- `mobile-app/assets/cfg/configuration.json`

Current defaults:

- `base_url`: `https://mitabl.com/`
- `api_base_url`: `https://mitabl.com/api/`
- `image_base_url`: `https://mitabl.com/`

If mobile is still calling an old host (for example `mitabl.xcelanceweb.com`), update this file and rebuild/reinstall the app. Most authenticated app endpoints are now under `/api/v2/*`; login/register/OTP/password-reset remain under `/api/*`.

---

## 5) Marketing Website (`website/`) Deep Dive

### Responsibilities

- Serves public marketing pages and legal pages (`home/about/privacy/terms`).
- Exposes a simple health endpoint (`/health`).
- Contains no website-owned database models/migrations and no intake proxy API surface.

### Website role in platform architecture

- Public, static marketing surface for brand and product messaging.

---

## 6) CRM + Support Operations

The current CRM footprint is fully represented in this repository via backend models/resources, plus runbooks in `docs/`.

### CRM capabilities implemented

- **Ops workflows**: assignment, response, resolution status progression.
- **SLA/operations visibility**: dashboard widgets and list views in admin.
- **Auditability**: action logs and auditable resources.
- **Intake scope**: active CRM intake is support-ticket based; legacy pre-registration lead intake is retired/unsupported.

### Operational documentation present

- `docs/crm_playbook_and_training.md`: SOPs for customer service and operations.
- `docs/legacy_crm_eradication_validation.md`: cutover parity, compatibility, and validation guardrails.
- `docs/secrets-management.md`: secrets handling and verification checklist.

---

## 7) Platform Admin (Filament) Features

Backend ships a dedicated Filament panel provider with grouped navigation and permission-gated resources/pages/widgets.

### Admin resources

- `UserResource`
- `MikitchnResource`
- `OrderResource`
- `SupportTicketResource`
- `CertificateResource`
- `PromoCodeResource`
- `PaymentResource`
- `PolicyResource`
- `TemplateResource`
- `AdminActionLogResource`
- `AuditLogResource`

### Admin pages

- `PlatformSettingsPage`
- `SystemHealthPage`
- `QueueOpsPage`
- `IntegrationLogsPage`
- `SecurityAdminPage`

### Dashboard/ops widgets

- Live operations and operational snapshot widgets.
- SLA health, CRM queue stats, aging buckets.
- Integration health and system health summary.
- Order and registration trend charts.

### Governance and risk controls

- Permission-enforced access checks via role/permission mapping.
- Step-up confirmation patterns for high-risk actions (status overrides/refunds/publishing policies).
- IAM management constrained to super-admin permission path.

---

## 8) Personas and RBAC Profiles

### Product personas

1. **Guest**
   - Unauthenticated public website access.
   - Can invoke public API endpoints such as login/register and support ticket create/read/reply.
2. **Foodie (customer)**
   - Authorized through `customer` middleware.
   - Discovery, favorites, order placement, payment, and customer-side reviews.
3. **Cook (restaurant operator)**
   - Authorized through `restaurant` middleware.
   - Kitchen/menu management, incoming orders, onboarding and fulfillment operations.
4. **Suspended API user**
   - Blocked by `api.user.active` middleware.
5. **Admin identity on API**
   - Blocked from API operations and directed to web admin panel.

### Admin personas (`admin` guard roles)

1. **super_admin**
   - Full platform permissions across operations, finance actions, platform governance, IAM.
2. **platform_admin**
   - Platform governance and control-plane permissions (settings, policy/template governance, queue/health/integration/audit visibility).
3. **operations**
   - Operational management of kitchens/certificates/orders/promo/support.
4. **customer_service**
   - Customer and support ticket handling with order/user visibility and ticket operations.
5. **finance_readonly**
   - Read-only finance/order observability and audit visibility.

---

## 9) ACCESS MATRIX (Current State)

Source of truth: `backend/database/seeders/AdminRolePermissionSeeder.php`.

Legend: ✅ assigned, — not assigned.

| Permission | super_admin | platform_admin | operations | customer_service | finance_readonly |
|---|---:|---:|---:|---:|---:|
| dashboard.view | ✅ | ✅ | ✅ | ✅ | ✅ |
| certificates.view | ✅ | — | ✅ | — | — |
| certificates.review | ✅ | — | ✅ | — | — |
| users.view | ✅ | — | ✅ | ✅ | — |
| users.edit | ✅ | — | — | — | — |
| users.suspend | ✅ | — | — | — | — |
| kitchens.view | ✅ | — | ✅ | — | — |
| kitchens.edit | ✅ | — | ✅ | — | — |
| orders.view | ✅ | — | ✅ | ✅ | ✅ |
| orders.override_status | ✅ | — | ✅ | ✅ | — |
| orders.refund | ✅ | — | — | — | — |
| support_tickets.view | ✅ | — | ✅ | ✅ | — |
| support_tickets.create | ✅ | — | — | ✅ | — |
| support_tickets.assign | ✅ | — | ✅ | ✅ | — |
| support_tickets.respond | ✅ | — | ✅ | ✅ | — |
| support_tickets.resolve | ✅ | — | ✅ | ✅ | — |
| promo_codes.view | ✅ | — | ✅ | — | — |
| promo_codes.edit | ✅ | — | ✅ | — | — |
| payments.view | ✅ | — | — | — | ✅ |
| payments.refund | ✅ | — | — | — | — |
| platform_settings.view | ✅ | ✅ | — | — | — |
| platform_settings.edit | ✅ | ✅ | — | — | — |
| policies.view | ✅ | ✅ | — | — | — |
| policies.edit | ✅ | ✅ | — | — | — |
| templates.view | ✅ | ✅ | — | — | — |
| templates.edit | ✅ | ✅ | — | — | — |
| policy_changes.publish | ✅ | ✅ | — | — | — |
| queue_ops.view | ✅ | ✅ | — | — | — |
| queue_ops.manage | ✅ | ✅ | — | — | — |
| health.view | ✅ | ✅ | — | — | — |
| integration_logs.view | ✅ | ✅ | — | — | — |
| audit_logs.view | ✅ | ✅ | — | — | ✅ |
| iam.manage | ✅ | — | — | — | — |

### Permission -> Filament surface mapping

- `support_tickets.*` -> SupportTicketResource
- `certificates.*` -> CertificateResource
- `users.*` -> UserResource
- `kitchens.*` -> MikitchnResource
- `orders.*` -> OrderResource
- `promo_codes.*` -> PromoCodeResource
- `payments.*` -> PaymentResource
- `policies.*`, `policy_changes.publish` -> PolicyResource
- `templates.*` -> TemplateResource
- `platform_settings.*` -> PlatformSettingsPage
- `queue_ops.*` -> QueueOpsPage
- `health.view` -> SystemHealthPage and health widgets
- `integration_logs.view` -> IntegrationLogsPage
- `audit_logs.view` -> AdminActionLogResource / AuditLogResource
- `iam.manage` -> SecurityAdminPage

---

## 10) Data Model and Domain Highlights

Representative backend model groups:

- **Core marketplace**: `User`, `Role`, `Mikitchn`, `Foods`, `Order`, `OrderData`, `CompletedOrder`, `Timing`, `Image`, `Review`, `Favorite`, `PromoCode`, `Partner`.
- **Payments/settlement**: `Payment`, `Refund`, `Transfer`, `Card`, `StripeAccount`, `StripeBankAccount`.
- **CRM/support**: `SupportTicket`, `SupportTicketMessage`, `SupportTicketEvent`, `SupportTicketAttachment`, `Template`, `Tag`.
- **Platform governance/admin**: `AdminUser`, `AdminActionLog`, `Policy`, `PolicyChangeLog`, `PlatformSetting`, `WatchSubscription`.

---

## 11) Local Development Setup


### Target production architecture (containerized)

- **Backend (`backend/`)** is the main application runtime: API, business logic, workflows, CRM/admin portal.
- **Website (`website/`)** is a separate static nginx-served public site (no app DB dependency).
- **Mobile app (`mobile-app/`)** remains separate and is not part of production compose runtime.
- Use root `docker-compose.yml` for Windows Docker test runs.
- Use `deploy/docker-compose.prod.contabo.yml` for Contabo Linux production.

### Option A: full stack with Docker

```bash
docker compose up --build
```

Compose includes:
- `db` (MySQL)
- `redis` (Redis `7.2-alpine`)
- `backend` on `:8000`
- `website` on `:8080`
- `mobile-app` optional dev-tools container (profile: `mobile-devtools`)

`backend` runs migrations at startup and can run seeders when `RUN_SEEDERS_ON_BOOT=true`.

### Option B: backend local run

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan jwt:secret
php artisan migrate --force
php artisan db:seed
php artisan serve --host=0.0.0.0 --port=8000
```

Optional workers:

```bash
php artisan horizon
php artisan queue:work
```

### Option C: website local run

```bash
docker compose up --build website
```

Then open `http://localhost:8080`.

### Option D: mobile local run

```bash
cd mobile-app
flutter pub get
flutter run
```

---

## 12) CI/CD and Quality Gates

The monorepo GitHub workflow performs:

1. Secret scan gate.
2. Backend setup + tests.
3. Website static checks.
4. Flutter dependency install + tests.

Primary local checks:

```bash
cd backend && php artisan test
cd website && npm run test
cd mobile-app && flutter test
```

---

## 13) Security, Secrets and Operational Notes

- Keep credentials outside source control; use env injection and secret managers.
- Follow `docs/secrets-management.md` for rotation and verification expectations.
- Use `/api/health/live` and `/api/health/ready` for orchestrator probes.
- Use `deploy/load-tests` scripts for support/admin performance verification.
- Use CRM runbook docs for response/assignment/escalation SOP alignment.

