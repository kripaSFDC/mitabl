# mitabl

**mitabl** is a marketplace platform that revolutionises home cooking by connecting foodies (customers) with home cooks who operate virtual kitchens ("miKitchens"). Customers can discover nearby home-cooked meals, book time slots, order food, and pay securely while cooks manage their kitchen profile, menu, bookings, and earnings from a single app.



---

## Repository Structure

```
mitabl/
├── backend/        # Laravel REST API :  core business logic and mobile API
├── mobile-app/     # Flutter cross-platform app : iOS & Android for foodies and cooks
└── website/        # Laravel marketing website : public-facing web presence
```

---

## 1. `backend/`  REST API Server

### Functional Overview

The backend is the central engine of the mitabl platform. It exposes a JSON REST API consumed by the mobile app (and proxies used by the marketing site). It handles all business logic including user registration and authentication (with OTP verification), kitchen (miKitchen) profile management, food menu CRUD, order lifecycle management (request → accept → complete → pay out), Stripe payment processing, review and rating collection, push notifications, support ticket intake and SLA workflows, and internal CRM operations/admin modules. Health‑check endpoints (`/api/health*`) and a SystemHealthService are provided for container liveness/readiness.

### Tech Stack

| Layer              | Technology                                           |
| ------------------ | ---------------------------------------------------- |
| Language           | PHP 8.2+                                             |
| Framework          | Laravel 12                                           |
| Authentication     | JWT (`tymon/jwt-auth` v2.2) & optional Sanctum      |
| Payments           | Stripe SDK (`stripe/stripe-php` v16) + Stripe Connect |
| API Documentation  | Swagger / OpenAPI (`darkaonline/l5-swagger` v10)     |
| CORS               | `fruitcake/laravel-cors`                             |
| Favourites         | `overtrue/laravel-favorite` v5                      |
| Authorization      | `spatie/laravel-permission`                         |
| Auditing           | `owen-it/laravel-auditing`                          |
| ORM                | Laravel Eloquent                                     |
| Database           | MySQL (via `pdo_mysql`), Doctrine DBAL for migrations |
| HTTP Client        | Guzzle 7                                             |
| Queue / Events     | Laravel Queues/Horizon, Events, Listeners            |
| Job Monitoring     | Laravel Horizon                                      |
| Push Notifications | Firebase Cloud Messaging (FCM)                       |
| Container          | Docker (PHP 8.2‑FPM image)                           |
| Testing            | PHPUnit 11                                           |

### Architecture

The backend follows the standard **Laravel MVC** pattern with an additional Resource layer for API response shaping.  Health routes and a `SystemHealthService` provide liveness/readiness probes used by Kubernetes/containers.

```
routes/api.php
    ├── health*                  # /health, /health/live, /health/ready, /health/startup
    └── Middleware (JwtMiddleware, Customer, Restaurant, api.user.active)
        └── Http/Controllers/Api/
            ├── User/UserController          # Auth, profile, Stripe account
            ├── MikitchnController           # Kitchen profile, dashboard, search
            ├── FoodsController              # Menu item CRUD
            ├── OrderController              # Full order lifecycle
            ├── PaymentController            # Stripe payment helpers
            ├── SupportTicketController      # Public support ticket API
            ├── ReviewController             # Reviews ↔ foodies & cooks
            ├── FavoriteController           # Favourite kitchens
            ├── FcmController                # Push notification retrieval
            ├── ForgotPasswordController     # Password reset flow
            ├── WebApiToCurlController       # Pre‑registration proxy
            └── ... (other utility controllers)
```

**Middleware roles:**

- `JwtMiddleware`  validates JWT token on every authenticated route
- `Customer`  gates routes to foodie users only
- `Restaurant`  gates routes to kitchen operator users only
- `api.user.active`  blocks disabled users

**API response shaping** uses Laravel API Resources (`Http/Resources/`) split into `User/`, `Restaurant/`, `Order/`, and `Reviews/` namespaces to keep response contracts clean.

### Key Functional Components

#### Authentication & Users (`User` model, `UserController`)

- OTP-based phone/email verification at registration (`verify_otps` table)
- JWT token issuance/refresh/logout, optional Laravel Sanctum support
- Dual-role accounts: a user can be both a **Foodie** (customer) and a **Cook** (kitchen operator) and switch between roles (`becomecook` / `becomefoodie` endpoints)
- Device token management for FCM push messages
- Password reset via email link
- Role/permission management via Spatie package

#### miKitchen Profiles (`Mikitchn` model, `MikitchnController`)

- Cooks create a kitchen profile with name, address, images, cooking styles, special diets, opening hours (`Timing` model), and dine‑in availability
- Kitchen availability toggle (`updateopenmikitchen`)
- Certificate upload & ABN/GST fields with local approval workflows
- Dashboard data endpoint aggregating revenue, order counts, and ratings

#### Food Menu (`Foods` model, `FoodsController`)

- Cooks add/edit/delete menu items with images, price, and availability status
- Customers retrieve paginated menus per kitchen

#### Order Lifecycle (`Order`, `OrderData`, `CompletedOrder` models, `OrderController`)

- Foodies create an order with a selected date/time slot
- `getBookedDates` / `checkBookedTimeByDate` prevent double‑booking
- Status machine: `requested → accepted/rejected → completed`
- Promo code validation (`PromoCode` model) with discounted‑user tracking
- Completed orders archived to `completed_orders` table

#### Payments (`Payment`, `Transfer`, `Refund`, `Card`, `StripeAccount`, `StripeBankAccount` models)

- Stripe Connect: cooks onboard via the Connect OAuth flow (`onboardingLink`)
- Customers pay via Stripe Payment Intents or Checkout sessions
- Funds held on platform; payout to cook via `transfertovendor`
- Full refund endpoint with `Refund` tracking
- Top‑up capability for platform wallet
- Card management (add/list cards per customer)

#### Support & Contact (`SupportTicket` models, `SupportTicketController`)

- Public ticket API accepts enquiries from mobile/web (creates `support_tickets`, `support_ticket_messages`, attachments, events)
- Guests can create tickets and follow up via token or authenticated user
- Replies, categories, priorities, SLA escalation commands
- `WebApiToCurlController` handles preregistration intake from public forms

#### Health Checks

- Simple `/api/health` plaintext ping
- `/api/health/live`, `/api/health/startup` for container probes
- `/api/health/ready` runs `SystemHealthService` checks (DB, cache, queue, external integrations) and returns 503 on failures

#### Notifications (`FcmController`, `Mail/`, `Notifications/`)

- Firebase FCM push notifications for new orders, kitchen verification, and order status changes
- Email notifications: OTP, registration welcome, password reset, invoice, refund invoice, kitchen activation, account deletion confirmation, support ticket replies/escalations
- In‑app notification feed (stored in `notifications` table)

#### Reviews & Ratings (`Review` model, `ReviewController`)

- Foodies leave reviews on kitchens (linked to a completed order)
- Cooks leave reviews on foodies
- Reviews stored with `by_user` flag to distinguish direction

#### Favourites (`Favorite` model, `FavoriteController`)

- Toggle and list favourite kitchens per user (polymorphic via `overtrue/laravel-favorite`)

#### Discovery & Search (`MikitchnController`)

- `nearestRestaurant`  geo‑proximity search
- `topRatedRestaurant`  sorted by aggregated review scores
- `recommendedRestaurant`  personalised recommendation feed
- `filterRestaurant`  filter by cooking style, special diet, etc.

#### CRM and Admin Operations (Post‑Cutover)

- Support/lead intake uses `/api/preregister` and `/api/support/ticket` with local persistence.
- Internal approval, SLA dashboards, user and ticket management are served through Filament 3 admin modules.

### ACCESS MATRIX
Strict Permission Matrix (Role Table)
Legend: SA=super_admin, PA=platform_admin, OP=operations, CS=customer_service, FR=finance_readonly

Permission	SA	PA	OP	CS	FR
dashboard.view	✓	✓	✓	✓	✓
certificates.view	✓	—	✓	—	—
certificates.review	✓	—	✓	—	—
users.view	✓	—	✓	✓	—
users.edit	✓	—	—	—	—
users.suspend	✓	—	—	—	—
kitchens.view	✓	—	✓	—	—
kitchens.edit	✓	—	✓	—	—
orders.view	✓	—	✓	✓	✓
orders.override_status	✓	—	✓	✓	—
orders.refund	✓	—	—	—	—
support_tickets.view	✓	—	✓	✓	—
support_tickets.create	✓	—	—	✓	—
support_tickets.assign	✓	—	✓	✓	—
support_tickets.respond	✓	—	✓	✓	—
support_tickets.resolve	✓	—	✓	✓	—
pre_registrations.view	✓	—	✓	✓	—
pre_registrations.edit	✓	—	✓	✓	—
promo_codes.view	✓	—	✓	—	—
promo_codes.edit	✓	—	✓	—	—
payments.view	✓	—	—	—	✓
platform_settings.view	✓	✓	—	—	—
platform_settings.edit	✓	✓	—	—	—
policies.view	✓	✓	—	—	—
policies.edit	✓	✓	—	—	—
policy_changes.publish	✓	✓	—	—	—
queue_ops.view	✓	✓	—	—	—
queue_ops.manage	✓	✓	—	—	—
health.view	✓	✓	—	—	—
audit_logs.view	✓	✓	—	—	✓
iam.manage	✓	—	—	—	—

#### Permission-to-Filament surface mapping

dashboard.view: dashboard widgets including CRM/live/integration/SLA/charts.
certificates.view/review: CertificateResource.php
users.view/edit/suspend: UserResource.php
kitchens.view/edit: MikitchnResource.php
orders.view/override_status/refund: OrderResource.php
support_tickets.*: SupportTicketResource.php
pre_registrations.*: PreRegistrationResource.php
promo_codes.*: PromoCodeResource.php
payments.view: PaymentResource.php
platform_settings.*: PlatformSettingsPage.php
policies.* + policy_changes.publish: PolicyResource.php
queue_ops.*: QueueOpsPage.php
health.view: SystemHealthPage.php, SystemHealthSummaryWidget.php
audit_logs.view: AdminActionLogResource.php
iam.manage: SecurityAdminPage.php

### Database Schema Highlights

60+ migrations covering: `users`, `roles`, `verify_otps`, `mikitchns`, `foods`, `cooking_styles`, `special_diets`, `timings`, `images`, `certificates`, `orders`, `order_data`, `completed_orders`, `promo_codes`, `payments`, `transfers`, `refunds`, `cards`, `stripe_accounts`, `stripe_bank_accounts`, `reviews`, `favorites`, `notifications`, `cancel_reasons`, `partners`, `user_auth_tokens`, plus support ticket tables (`support_tickets`, `support_ticket_messages`, `support_ticket_events`, `support_ticket_attachments`).

### Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan jwt:secret        # or configure sanctum cookies
php artisan migrate --force
php artisan db:seed
php artisan optimize:clear
composer dump-autoload
# Permissions
chmod -R 777 storage bootstrap public
# Run locally
php artisan serve   # localhost:8000
# or start workers/horizon in background
php artisan horizon
php artisan queue:work
```

**Docker:**

```bash
docker build -t mitabl-backend .
docker run -p 8000:8000 \
    --health-cmd="curl --fail http://localhost/health || exit 1" \
    mitabl-backend
```

---
---

## 2. `mobile-app/`  Flutter Mobile App

### Functional Overview

A cross-platform Flutter application (iOS + Android) that serves both **Foodies** (customers discovering and ordering home-cooked meals) and **Cooks** (home kitchen operators managing their business). The app provides two distinct UX flows within a single binary, switchable at the account level.

### Tech Stack

| Layer            | Technology                        |
| ---------------- | --------------------------------- |
| Language         | Dart (SDK ≥3.3)                   |
| Framework        | Flutter 3.x                       |
| State Management | BLoC / Cubit (`flutter_bloc` v8+) |
| Value Equality   | `equatable` v2                   |
| Config           | `global_configuration`           |
| Local Storage    | `shared_preferences` v2          |
| File Access      | `path_provider` v2               |
| Fonts            | `google_fonts` v2.3.2            |
| Form Validation  | `formz` v0.4                     |
| SVG Rendering    | `flutter_svg` v1                 |
| Toast Messages   | `fluttertoast` v8                |
| Image Picking    | `image_picker` v0.8              |
| Network Images   | `cached_network_image` v3        |
| OTP Input        | `pinput` v2                      |
| Rating Widget    | `flutter_rating_bar` v4          |
| Carousel         | `carousel_slider` v4             |
| Toggles          | `flutter_switch` v0.3            |
| Date/Time        | `intl` v0.17                     |
| URL Handling     | `url_launcher` v6                |
| Target Platforms | iOS, Android                     |

### Architecture

The app follows a **BLoC (Business Logic Component)** pattern with a clean separation of layers:

```
lib/
├── main.dart                  # App entry point, global config injection
├── app.dart                   # MaterialApp, theme, BLoC providers
├── splash.dart                # Splash screen
├── route_generator.dart       # Centralised named-route factory
│
├── auth_bloc/                 # Global authentication BLoC (token lifecycle)
│   └── authentication/
│
├── model/                     # Pure Dart data models (API response DTOs)
│
├── repos/                     # Repository layer  all API calls abstracted
│   ├── authentication_repository.dart
│   ├── home_repository.dart
│   ├── cook_repository.dart
│   ├── bookings_repository.dart
│   └── user_repository.dart
│
├── helper/                    # Shared utilities (route args, etc.)
│
├── pages/                     # Foodie (customer) screens
│   ├── landing_page/          # App entry / role selector
│   ├── login/                 # Login with JWT
│   ├── signup/                # Registration
│   ├── otp/                   # OTP verification
│   ├── forgot/                # Forgot password
│   ├── home/                  # Main discovery feed
│   ├── profile_foodie/        # Foodie public profile
│   ├── edit_profile_foodie/   # Edit foodie profile
│   └── profile_signup_cook/   # Cook profile onboarding
│
└── pages_cook/                # Cook (kitchen operator) screens
    ├── dashboard_cook/        # Revenue & stats dashboard
    ├── home_page/             # Cook home
    ├── menu/                  # Full menu list
    ├── menu_detail/           # Single item detail
    ├── add_menu_item/         # Add / edit menu item
    ├── edit_kitchen_profile/  # Edit miKitchen profile
    ├── edit_profile_cook/     # Edit cook personal profile
    ├── profile_cook/          # Cook public profile
    ├── requests/              # Incoming order requests
    ├── bookings/              # All bookings history
    ├── upcoming_bookings/     # Upcoming confirmed bookings
    ├── customer_reviews/      # Reviews left by foodies
    ├── user_details_page/     # Customer detail for a booking
    └── settings_page/         # Notification toggles, logout, etc.
```

### Key Functional Components

#### Global Auth BLoC (`auth_bloc/`)

Manages the JWT authentication state across the entire app. Persists tokens via `shared_preferences` and drives navigation between authenticated and unauthenticated states.

#### Repository Layer (`repos/`)

Explanation: Replace root README with a consolidated, enterprise-style README that matches the current repository contents and developer workflows.

# mitabl — Enterprise Overview

This repository contains the mitabl platform: a production-grade marketplace connecting home cooks (miKitchens) and customers (Foodies). It comprises three primary projects maintained in a single mono-repo:

- `backend/` — Laravel 12 REST API (core business logic, admin, and mobile API).
- `mobile-app/` — Flutter cross-platform mobile application (iOS & Android).
- `website/` — Laravel marketing/landing site used for acquisition and public content.

Additional folders include deployment, documentation, Nginx configs, and automation scripts.

This README is an up-to-date enterprise-level reference for developers, SREs, and integrators. It documents architecture, technology choices, developer workflows, common environment variables, deployment notes, and troubleshooting tips. It does not attempt to list removed or deprecated features except when necessary for context.

--

**Repository layout (top-level)**

```
mitabl/
├── backend/        # Laravel API + Filament admin
├── mobile-app/     # Flutter app (Foodie + Cook flows)
├── website/        # Marketing/landing Laravel app
├── deploy/         # Compose files, environment and deployment helpers
├── docs/           # Operational runbooks, playbooks, release artifacts
├── load-tests/     # Load testing scripts and scenarios
├── nginx/          # Nginx configurations used in deployments
└── docker-compose.yml
```

**Primary contacts & governance**
- Platform owner: see `docs/` for contact and runbook ownership.
- Security: report to the security contact in `docs/secrets-management.md`.

--

**High-level architecture**

- Backend: Laravel 12 REST API (PHP 8.2+) — business logic, auth, payments, notifications, admin (Filament).
- Mobile App: Flutter (Dart >=3.3) — single binary handling both Foodie and Cook experiences via role switch.
- Website: Laravel-based marketing site — form capture, legal pages, and light integrations to backend API.
- Data: MySQL (migrations in backend/database/migrations).
- External services: Stripe (Payments & Connect), Firebase FCM (push notifications), optional Filament admin UI for operations.

--

**Quick links**
- API routes: [backend/routes/api.php](backend/routes/api.php)
- Website routes: [website/routes/web.php](website/routes/web.php)
- Mobile entry: [mobile-app/lib/main.dart](mobile-app/lib/main.dart)
- Docker compose: [docker-compose.yml](docker-compose.yml)
- Docs folder: [docs](docs)

--

**Technology summary**

- Backend: PHP 8.2, Laravel 12, JWT auth (`tymon/jwt-auth`), Filament admin, Horizon, Doctrine DBAL, L5-Swagger.
- Website: Laravel 12, Blade views, `laravel/cashier` for Stripe-related flows.
- Mobile: Flutter 3.x (Dart 3.3+), BLoC pattern, commonly used packages listed in `mobile-app/pubspec.yaml`.
- Containers: Docker, a multi-service compose is provided at repository root.

--

**What’s in `backend/` (developer summary)**

- API surface for mobile and website integrations. Implements authentication (OTP + JWT), dual-role user model (Foodie / Cook), miKitchen profile management, menu CRUD, booking/order lifecycle, promo codes, Stripe Connect payouts, refunds, support ticketing, reviews, favourites, and health endpoints.
- Admin UX built with Filament (resources and pages for managing users, kitchens, orders, support tickets, certificates, and policy changes).
- Health endpoints for readiness/liveness: `/api/health`, `/api/health/live`, `/api/health/ready`, `/api/health/startup`.

See `backend/composer.json` for the dependency list and `backend/README.md` for any module-specific notes.

--

Getting started — Development (local)

Prerequisites: PHP 8.2+, Composer, Node.js & npm (for assets), Docker (optional), Flutter SDK (for mobile).

Backend (local dev)

1. Copy environment and install deps:

```bash
cd backend
cp .env.example .env
composer install
npm install
```

2. Generate keys and run migrations:

```bash
php artisan key:generate
php artisan jwt:secret
php artisan migrate --force
php artisan db:seed
```

3. Start the app:

```bash
php artisan serve --host=0.0.0.0 --port=8000
php artisan horizon       # in another terminal for queues
```

Or use Docker Compose (recommended for parity):

```bash
docker compose up --build
```

Notes:
- Filament admin UI is available when the `admin` user is created by seeding or via artisan commands.
- Check `backend/.env` for Stripe keys, FCM credentials, and DB connection strings before running.

Mobile app (local dev)

1. Install dependencies:

```bash
cd mobile-app
flutter pub get
```

2. Run on an emulator/device:

```bash
flutter run
```

3. Build releases:

```bash
flutter build apk
flutter build ios
```

Website (local dev)

```bash
cd website
cp .env.example .env
composer install
npm install
php artisan key:generate
php artisan serve --host=0.0.0.0 --port=8080
```

--

Testing

- Backend PHPUnit tests: `cd backend && ./vendor/bin/phpunit`
- Mobile widget/unit tests: `cd mobile-app && flutter test`
- Website PHPUnit: `cd website && ./vendor/bin/phpunit`

CI pipelines (where present) should run linting, unit tests, and build artifact steps for each project.

--

Deployment notes

- Production deployments rely on the container images (Dockerfiles are present in `backend/`, `website/`, and `mobile-app/`).
- Use the `deploy/` folder and the provided Compose/phase files for environment-specific orchestration.
- Health checks must be configured by the orchestrator against `/api/health/ready` and `/api/health/live`.
- Migrations should be run as part of the release pipeline with explicit migration-run steps (avoid running migrations automatically in entrypoint for safety).

Stripe & Payments

- The backend implements Stripe Connect onboarding for cooks. Configure `STRIPE_SECRET`, `STRIPE_CLIENT_ID` and the platform account keys in `backend/.env`.
- Cashier is included in `website/` for any web-initiated billing flows.

Notifications

- FCM configuration is required to send push notifications. Add `FCM_SERVER_KEY` / `FCM_SENDER_ID` to `backend/.env`.

API Documentation

- OpenAPI/Swagger docs are generated via `darkaonline/l5-swagger`. Visit the generated documentation endpoint in the running backend (commonly `/api/documentation` or `/api/docs`) after publishing assets.

Operational considerations

- Queue processing: use Horizon for real-time monitoring. Ensure worker counts and supervisor config match expected throughput.
- Audit logs: `owen-it/laravel-auditing` records model changes — retention and access controls must be determined by platform policy.
- Sensitive data: card and bank details are handled through Stripe or stored in truncated form. Follow PCI rules — do not store raw card numbers.

Security & Secrets

- Secrets must be stored in a secure store (Key Vault / AWS Secrets Manager / Vault). The repository contains `.env.example` only.
- Rotate Stripe secrets and webhook signing secrets periodically and after key personnel changes.

Troubleshooting

- Database connection issues: check `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` in `backend/.env`.
- Queue backlog: inspect `php artisan horizon:status` and `php artisan queue:failed`.
- Migrations do not apply: inspect `doctrine/dbal` version and any schema edge-cases; run `php artisan migrate:status`.

Contributing

- Follow the repo coding standards. Open PRs against `main`/`master` depending on branch policy. Include tests for feature changes and update API docs when adding endpoints.
- Add migration files for schema changes under `backend/database/migrations` and model factories under `backend/database/factories`.

Support & runbooks

- Operational runbooks and release notes are in the `docs/` folder.

License

- See top-level `LICENSE` if present. Most backend and website code follow MIT-style dependencies but confirm licensing for third-party assets before release.

--

If you want, I can now:

- Run a dependency scan across `backend/composer.json`, `website/composer.json`, and `mobile-app/pubspec.yaml` and produce a consolidated dependency report.
- Open a PR with this README change and include a short changelog entry.

Would you like me to proceed with either of those follow-ups?


