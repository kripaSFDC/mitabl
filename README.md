# mitabl

mitabl is a multi-application platform for home-cooked food commerce. It connects **Foodies (customers)** and **Cooks (miKitchen operators)** through a mobile app, while providing a Laravel backend API and a Filament-powered operations/admin console.

This README reflects the **current codebase state** in this repository.

---

## 1) Platform Overview

### Core business capabilities

- Customer and cook onboarding with JWT-based authentication and OTP verification.
- Dual-sided marketplace flows:
  - Foodies discover kitchens, browse menus, place orders, pay, review, and favorite kitchens.
  - Cooks manage kitchen profile, menu, availability, onboarding/compliance artifacts, and order fulfillment.
- Payment operations through Stripe (including refunds and transfer/payout workflows).
- Support and CRM intake for pre-registrations and support tickets.
- Filament admin console for operations, customer service, platform governance, policy management, health/queue operations, and audit visibility.
- Health probes for container orchestration readiness/liveness.

### Runtime applications in this mono-repo

- `backend/`: Laravel API + Filament admin panel.
- `mobile-app/`: Flutter iOS/Android app (Foodie + Cook experiences in one app).
- `website/`: Laravel marketing/public website and intake forwarding endpoints.
- `deploy/`: environment files, compose variants, nginx/supervisor config, and load-test scripts.
- `docs/`: operational runbooks and validation artifacts.

---

## 2) Repository Structure (Detailed)

```text
mitabl/
├── backend/                      # Core Laravel API and Filament admin application
│   ├── app/
│   │   ├── Filament/             # Admin pages/resources/widgets
│   │   ├── Http/                 # API controllers, middleware, resources
│   │   ├── Models/               # Domain + CRM + payment + admin models
│   │   ├── Services/             # Health and business services
│   │   └── Console/Commands/     # Reconciliation/ops commands
│   ├── database/
│   │   ├── migrations/           # Marketplace + admin + CRM schema
│   │   └── seeders/              # Role/permission and baseline domain seeders
│   ├── routes/api.php            # Public/authenticated marketplace + intake APIs
│   └── tests/                    # Feature/unit contract and regression tests
│
├── mobile-app/                   # Flutter client
│   ├── lib/
│   │   ├── auth_bloc/            # Auth lifecycle state management
│   │   ├── repos/                # API abstraction layer
│   │   ├── pages/                # Foodie flows
│   │   └── pages_cook/           # Cook flows
│   └── test/                     # Flutter tests
│
├── website/                      # Laravel marketing/public web app
│   ├── resources/views/frontend/ # Public pages (home/about/contact/register)
│   ├── routes/web.php            # Public website routes + health endpoint
│   ├── routes/api.php            # Intake proxy routes to backend
│   └── app/Http/Controllers/Api/WebApiToCurlController.php
│
├── deploy/
│   ├── environments/             # env templates per environment/app
│   ├── nginx/                    # Nginx config
│   ├── supervisor/               # Worker supervisor config
│   ├── scripts/                  # validation scripts (backup/traffic)
│   └── load-tests/               # k6 scripts for support/admin performance checks
│
├── docs/                         # CRM playbook, secrets, eradication validation docs
├── .github/workflows/ci-cd.yml   # Monorepo CI (secret scan + backend/website/mobile tests)
└── docker-compose.yml            # Local multi-service orchestration
```

---

## 3) What Each App / Sub-Repo Does

## 3.1 `backend/` (Laravel 12 API + Filament 3 Admin)

### API responsibilities

`backend/routes/api.php` contains:
- Health endpoints (`/api/health`, `/live`, `/startup`, `/ready`).
- Public auth/intake endpoints (`login`, `register`, `verifyOtp`, `preregister`, `support/ticket`).
- Authenticated v1 endpoints under `auth:api` + active-user guard.
- Role-gated route groups via middleware:
  - `customer` middleware for Foodie flows.
  - `restaurant` middleware for Cook/Restaurant flows.

### Marketplace domain modules

Based on controllers/models/migrations, backend covers:
- Identity/Auth: users, OTP verification, JWT lifecycle.
- miKitchen domain: kitchen profile, timings, images, certificates.
- Catalog: foods/menu items with availability/status.
- Ordering: order creation, status transitions, order details, booking-time checks.
- Payments: cards, payment intents, checkout, transfers, refunds.
- Growth: promo codes, favorites, partner exposure.
- Trust/quality: reviews and notifications.
- CRM intake: pre-registrations and support tickets (including message/event/attachment model set).

### Admin/operations surface (Filament)

`backend/app/Filament` provides:
- **Resources**: users, kitchens, orders, support tickets, certificates, pre-registrations, promo codes, payments, policies, templates, admin action logs, audit logs.
- **Pages**: platform settings, queue operations, system health, integration logs, security administration.
- **Widgets**: operational dashboard, SLA, queue, integration and health indicators, charts.

### Admin identity split

- Admin users are stored in `admin_users` and authenticated on guard `admin`.
- Marketplace API users are authenticated with `auth:api` and explicitly blocked from using admin identities (`EnsureApiUserIsActive`).

## 3.2 `mobile-app/` (Flutter)

Single mobile codebase supports both user journeys:
- **Foodie journey (`lib/pages/`)**: onboarding/login/OTP, discovery, profile, and ordering-related UX.
- **Cook journey (`lib/pages_cook/`)**: dashboard, menu management, kitchen profile editing, bookings, request handling, reviews, settings.
- `lib/repos/` centralizes backend API integration.
- `lib/auth_bloc/` manages auth state/token-driven navigation.

## 3.3 `website/` (Laravel marketing + intake proxy)

- Public pages are Blade-based (`/`, `/about`, `/register`, `/contact`, `/privacy-policy`, `/terms`, `/mob-contact`).
- Provides `/health` endpoint for uptime checks.
- Exposes API endpoints (`/api/preregister`, `/api/support/ticket`) that forward payloads to backend via `WebApiToCurlController`, preserving selected headers for deprecation/sunset handling.

## 3.4 `deploy/` (deployment and operations packaging)

- Root `docker-compose.yml` orchestrates db, migration jobs, backend, website, and mobile container build.
- `deploy/environments` holds app/env-specific templates for dev/staging/prod.
- `deploy/load-tests` includes k6 scenarios for support intake and admin lists.
- `deploy/scripts` contains operational validation scripts.

## 3.5 `docs/` (runbooks and governance)

Current docs include:
- CRM playbook and training SOP.
- Legacy CRM dependency eradication validation.
- Secrets management policy and verification checklist.

---

## 4) Architecture and Request Flow

### External users

- Mobile app talks directly to `backend` API.
- Website public forms can go through `website` API routes, which proxy to backend intake endpoints.

### Internal/admin users

- Admin operators log into Filament panel served by backend (`/admin` by default, configurable via `ADMIN_PANEL_PATH`).
- Queue and health controls are available via dedicated Filament pages subject to permission checks.

### Data and orchestration

- MySQL is the primary datastore in local compose.
- Queue/Horizon components are present in backend dependencies and runtime conventions.
- Health/readiness endpoints support deployment probes.

---

## 5) Personas and RBAC Profiles

This section rectifies the access model using current middleware, seeded permissions, and Filament permission checks.

### 5.1 Product personas (customer-side and API-side)

1. **Guest (unauthenticated)**
   - Can access public website pages.
   - Can call public API endpoints (register/login/intake).
2. **Foodie (customer)**
   - Authorized by `customer` middleware (`role->role === 'Foodie'`).
   - Can perform discovery, favorites, ordering, payment, and customer-review actions.
3. **Cook / Restaurant Operator**
   - Authorized by `restaurant` middleware (`role->role === 'Restaurant'`).
   - Can manage kitchen, menu, incoming orders, and cook-side reviews.
4. **Suspended API user**
   - Blocked by `api.user.active` middleware.
5. **Admin identity attempting mobile/API auth**
   - Explicitly blocked from API use; must authenticate through web admin panel.

### 5.2 Admin personas (Filament / `admin` guard)

Seeded admin roles:
- `super_admin`
- `platform_admin`
- `operations`
- `customer_service`
- `finance_readonly`

Permissions are defined in `backend/database/seeders/AdminRolePermissionSeeder.php` and enforced throughout Filament pages/resources.

---

## 6) ACCESS MATRIX (Current Codebase)

Legend:
- ✅ = permission assigned to role
- — = not assigned

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
| pre_registrations.view | ✅ | — | ✅ | ✅ | — |
| pre_registrations.edit | ✅ | — | ✅ | ✅ | — |
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

### Permission → Admin surface mapping (high-level)

- `support_tickets.*` → `SupportTicketResource`
- `pre_registrations.*` → `PreRegistrationResource`
- `certificates.*` → `CertificateResource`
- `users.*` → `UserResource`
- `kitchens.*` → `MikitchnResource`
- `orders.*` → `OrderResource`
- `promo_codes.*` → `PromoCodeResource`
- `payments.*` → `PaymentResource`
- `policies.*`, `policy_changes.publish` → `PolicyResource`
- `templates.*` → `TemplateResource`
- `platform_settings.*` → `PlatformSettingsPage`
- `queue_ops.*` → `QueueOpsPage`
- `health.view` → `SystemHealthPage` + health widgets
- `integration_logs.view` → `IntegrationLogsPage`
- `audit_logs.view` → `AdminActionLogResource` / `AuditLogResource`
- `iam.manage` → `SecurityAdminPage`

---

## 7) Local Development

### 7.1 Full stack with Docker Compose

```bash
docker compose up --build
```

Services include migration jobs (`db-migrate`, `website-db-migrate`), backend (`:8000`), website (`:8080`), and MySQL (`:3306`).

### 7.2 Backend quick start

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

Optional queue/horizon:

```bash
php artisan horizon
php artisan queue:work
```

### 7.3 Website quick start

```bash
cd website
cp .env.example .env
composer install
php artisan key:generate
php artisan serve --host=0.0.0.0 --port=8080
```

### 7.4 Mobile quick start

```bash
cd mobile-app
flutter pub get
flutter run
```

---

## 8) Quality Gates and CI

GitHub Actions (`.github/workflows/ci-cd.yml`) runs:
- secret scan gate,
- backend test suite,
- website test suite,
- mobile flutter tests.

Recommended local checks:

```bash
cd backend && php artisan test
cd website && php artisan test
cd mobile-app && flutter test
```

---

## 9) Security and Operations Notes

- Do not commit secrets; use environment injection and secret managers.
- Keep Stripe/FCM/auth secrets in runtime config, not source.
- Use `/api/health/live` and `/api/health/ready` for probe wiring.
- Use docs under `docs/` for CRM SOP, validation, and secret management policy.

