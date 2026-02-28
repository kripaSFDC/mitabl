# Changes Made

## Scope and baseline

- Baseline compared: current working tree vs `origin/main`.
- Branch status: no committed divergence from `origin/main`; all branch changes are currently local working-tree/untracked changes.
- This document covers all changed files currently present in this branch workspace.

## High-level summary

- Modified files: 42 tracked files.
- Deleted files: 1 tracked file.
- New files/directories (untracked): 30+ files, including deployment stack, env templates, docs, services, observers, and tests.
- Net diff (tracked files): 916 insertions, 2252 deletions.

## Core platform and backend changes

### 1) Runtime, dependency, and framework baseline

- `backend/composer.json`
  - PHP requirement upgraded to `^8.2`.
  - Laravel requirement moved to `^12.0`.
  - Added/updated packages aligned with newer stack (`laravel/horizon`, updated `l5-swagger`, `jwt-auth`, `phpunit`, etc.).
  - Updated Composer scripts to modern Laravel asset publish flow.
  - Set Composer `platform.php` to `8.2.0`.
- `backend/phpunit.xml`
  - Updated PHPUnit runtime configuration for current test environment.
- `backend/Dockerfile`
  - Upgraded base image to `php:8.2-fpm`.
  - Added required PHP extensions/libraries (`mbstring`, `bcmath`, `pcntl`, `zip`, etc.).
  - Removed hardcoded `.env` copy behavior during build.
- `website/Dockerfile` (new)
  - Added container build/runtime spec for the website app using PHP 8.2.

### 2) Queue/cache hardening and observability

- `backend/config/queue.php`
  - Queue default now resolves to Redis outside testing.
- `backend/config/cache.php`
  - Cache default now resolves to Redis outside testing.
- `backend/config/horizon.php` (new)
  - Added Horizon configuration with environment-specific worker settings.
- `backend/app/Providers/AppServiceProvider.php`
  - Added queue lifecycle logging (`Queue::after`, `Queue::failing`) for operational observability.

### 3) Service-layer refactor (Stripe/auth/order/discovery)

- Added new service classes:
  - `backend/app/Services/AuthService.php`
  - `backend/app/Services/PaymentService.php`
  - `backend/app/Services/OrderService.php`
  - `backend/app/Services/DiscoveryService.php`
  - `backend/app/Services/DiscoveryCacheService.php`
  - `backend/app/Services/KitchenService.php`
- Removed legacy trait:
  - `backend/app/Traits/StripeTrait.php` (deleted)
- Key outcomes:
  - OTP sending moved into `AuthService`.
  - Stripe operations centralized in `PaymentService`.
  - Order creation logic extracted to `OrderService`.
  - Discovery APIs now centralized and cache-backed in `DiscoveryService`.
  - Cache invalidation orchestration centralized in `KitchenService`.

### 4) API controllers and behavior changes

- `backend/app/Http/Controllers/Api/User/UserController.php`
  - Refactored to DI-based service usage (`AuthService`, `PaymentService`).
  - Payment/account endpoints modernized and hardened.
  - Added role/ownership checks for payment-related actions.
  - Removed exposed test-only onboarding method.
- `backend/app/Http/Controllers/Api/OrderController.php`
  - Integrated `OrderService`/`PaymentService` flows.
  - Improved defensive checks around payment/order state.
- `backend/app/Http/Controllers/Api/MikitchnController.php`
  - Discovery endpoints delegated to `DiscoveryService`.
  - Structural cleanup and service injection.
- `backend/app/Http/Controllers/Api/FcmController.php`
  - Count/pagination query improvements.
- `backend/app/Http/Controllers/Api/FoodsController.php`
  - Targeted updates aligned with service/refactor flow.
- `backend/app/Http/Controllers/Api/WebApiToCurlController.php`
- `website/app/Http/Controllers/Api/WebApiToCurlController.php`
  - Salesforce calls moved to env/config-driven setup.
  - Added payload normalization for web-form compatibility.
  - Added timeout/exception handling for external HTTP requests.
  - Removed hardcoded Salesforce secrets/tokens.

### 5) Routing and middleware hardening

- `backend/routes/api.php`
  - Added/retained `/api/health` health endpoint.
  - Re-scoped payment/account routes into role-appropriate middleware groups.
  - Removed `testcompletedOnBoarding` route exposure.
- `backend/app/Http/Middleware/SalesForce.php`
  - Fixed header comparison logic to avoid auth bypass edge cases.
- `backend/app/Http/Kernel.php`
  - Middleware config updates to align with current stack.

### 6) Observers, invalidation, and events/listeners

- Added observers:
  - `backend/app/Observers/FoodsObserver.php`
  - `backend/app/Observers/CertificateObserver.php`
- Updated observers:
  - `backend/app/Observers/MikitchnObserver.php`
  - `backend/app/Observers/ReviewObserver.php`
- Observer registration updated in:
  - `backend/app/Providers/AppServiceProvider.php`
- Listener updates:
  - `backend/app/Listeners/MakeOrderPaymentToVendorListener.php`
  - `backend/app/Listeners/CancelOrderRefundListener.php`
  - `backend/app/Listeners/KitchenVerifiedToSales.php`
- Effect:
  - Discovery cache invalidation now triggered on kitchen/menu/certificate/review changes.
  - Salesforce integration listener uses config/env values.

### 7) Security and secret externalization

- `backend/config/services.php`
- `website/config/services.php`
  - Added structured Salesforce config mapping.
  - Added reCAPTCHA config mapping.
  - Added Google Maps API config mapping (backend).
- `backend/app/Traits/GoogleAddress.php`
  - Removed hardcoded Google Maps API keys; now sourced from env/config.
- `.env` templates were sanitized to placeholder-only secret values.

## Frontend/views and JS changes

- `backend/resources/views/frontend/registration.blade.php`
  - Registration form flow updated for API payload compatibility.
- `website/resources/views/frontend/registration.blade.php`
- `website/webdata/mitabl html/registration.html`
  - Updated registration flow and key references.
- `backend/resources/views/frontend/contact.blade.php`
- `website/resources/views/frontend/contact.blade.php`
- `backend/resources/views/mob/contact.blade.php`
- `website/resources/views/mob/contact.blade.php`
  - Submit controls and request flow cleanup.
- `backend/resources/views/savebank.blade.php`
- `website/resources/views/savebank.blade.php`
  - Stripe publishable key now env-driven.
- `backend/public/js/script.js`
  - Stripe key binding and API interaction adjustments.

## Deployment and infrastructure additions (new)

### 1) Compose/supervisor/nginx

- `deploy/docker-compose.phase0.yml`
  - Added runtime split services: `marketing-web`, `backend-api`, `ops-admin`, `queue-worker`, `redis`.
  - Added health checks for API/admin/worker/redis.
- `deploy/nginx/mitabl.phase0.conf`
  - Added same-domain routing policy for `/`, `/api/*`, `/admin/*`.
  - Added TLS redirect/HSTS and admin network controls.
- `deploy/supervisor/queue-worker.conf`
  - Added managed queue worker process configuration.

### 2) Environment templates per service/environment

- New env templates:
  - `deploy/environments/backend-api.env`
  - `deploy/environments/marketing-web.env`
  - `deploy/environments/ops-admin.env`
  - `deploy/environments/dev/backend-api.env`
  - `deploy/environments/dev/marketing-web.env`
  - `deploy/environments/dev/ops-admin.env`
  - `deploy/environments/staging/backend-api.env`
  - `deploy/environments/staging/marketing-web.env`
  - `deploy/environments/staging/ops-admin.env`
  - `deploy/environments/prod/backend-api.env`
  - `deploy/environments/prod/marketing-web.env`
  - `deploy/environments/prod/ops-admin.env`

## Documentation additions/updates

- New docs:
  - `docs/phase-0-foundations.md`
  - `docs/phase-0.5-hardening.md`
  - `docs/hardening-exit-criteria.md`
  - `docs/secrets-management.md`
- Plan artifacts:
  - `Plan.md` (new)
  - `mitabl_enhancement_plan.md` (new)
  - `mitabl_enhancement_plan.pdf` (new)
- Existing docs changed:
  - `README.md` updated.
  - `adminFE.md` removed.

## Testing additions

- `backend/tests/Feature/HardeningRegressionTest.php` (new)
  - Added regression checks for:
    - Redis queue/cache defaults.
    - Env template constraints.
    - Discovery cache invalidation and metrics increments.
    - Secret leakage guardrails.
    - StripeTrait removal and `PaymentService` existence.

## Mobile changes

- `mobile-app/pubspec.yaml`
  - Updated Dart SDK constraints/tooling alignment for newer baseline.

## Complete changed file inventory

### Modified tracked files

- `README.md`
- `backend/.env.aws`
- `backend/.env.example`
- `backend/Dockerfile`
- `backend/app/Http/Controllers/Api/FcmController.php`
- `backend/app/Http/Controllers/Api/FoodsController.php`
- `backend/app/Http/Controllers/Api/MikitchnController.php`
- `backend/app/Http/Controllers/Api/OrderController.php`
- `backend/app/Http/Controllers/Api/User/UserController.php`
- `backend/app/Http/Controllers/Api/WebApiToCurlController.php`
- `backend/app/Http/Kernel.php`
- `backend/app/Http/Middleware/SalesForce.php`
- `backend/app/Listeners/CancelOrderRefundListener.php`
- `backend/app/Listeners/KitchenVerifiedToSales.php`
- `backend/app/Listeners/MakeOrderPaymentToVendorListener.php`
- `backend/app/Observers/MikitchnObserver.php`
- `backend/app/Observers/ReviewObserver.php`
- `backend/app/Providers/AppServiceProvider.php`
- `backend/app/Traits/GoogleAddress.php`
- `backend/composer.json`
- `backend/config/cache.php`
- `backend/config/queue.php`
- `backend/config/services.php`
- `backend/config/stripe.php`
- `backend/phpunit.xml`
- `backend/public/js/script.js`
- `backend/resources/views/frontend/contact.blade.php`
- `backend/resources/views/frontend/registration.blade.php`
- `backend/resources/views/mob/contact.blade.php`
- `backend/resources/views/savebank.blade.php`
- `backend/routes/api.php`
- `mobile-app/pubspec.yaml`
- `website/.env.example`
- `website/app/Http/Controllers/Api/WebApiToCurlController.php`
- `website/config/services.php`
- `website/resources/views/frontend/contact.blade.php`
- `website/resources/views/frontend/registration.blade.php`
- `website/resources/views/mob/contact.blade.php`
- `website/resources/views/savebank.blade.php`
- `website/webdata/mitabl html/registration.html`

### Deleted tracked files

- `backend/app/Traits/StripeTrait.php`

### New files

- `backend/app/Observers/CertificateObserver.php`

- `backend/app/Observers/FoodsObserver.php`

- `backend/app/Services/AuthService.php`

- `backend/app/Services/DiscoveryCacheService.php`

- `backend/app/Services/DiscoveryService.php`

- `backend/app/Services/KitchenService.php`

- `backend/app/Services/OrderService.php`

- `backend/app/Services/PaymentService.php`

- `backend/config/horizon.php`

- `backend/tests/Feature/HardeningRegressionTest.php`

- `deploy/docker-compose.phase0.yml`

- `deploy/environments/backend-api.env`

- `deploy/environments/dev/backend-api.env`

- `deploy/environments/dev/marketing-web.env`

- `deploy/environments/dev/ops-admin.env`

- `deploy/environments/marketing-web.env`

- `deploy/environments/ops-admin.env`

- `deploy/environments/prod/backend-api.env`

- `deploy/environments/prod/marketing-web.env`

- `deploy/environments/prod/ops-admin.env`

- `deploy/environments/staging/backend-api.env`

- `deploy/environments/staging/marketing-web.env`

- `deploy/environments/staging/ops-admin.env`

- `deploy/nginx/mitabl.phase0.conf`

- `deploy/supervisor/queue-worker.conf`

- `docs/hardening-exit-criteria.md`

- `docs/phase-0-foundations.md`

- `docs/phase-0.5-hardening.md`

- `docs/secrets-management.md`

- `mitabl_enhancement_plan.md`

- `mitabl_enhancement_plan.pdf`

- `website/Dockerfile`
  
  

---



## New environment variables introduced in this branch

### Backend env templates

- `REDIS_HOST`
- `REDIS_PASSWORD`
- `REDIS_PORT`
- `SALESFORCE_AUTH_HEADER`
- `SALESFORCE_BASE_URL`
- `SALESFORCE_API_VERSION`
- `SALESFORCE_CLIENT_ID`
- `SALESFORCE_CLIENT_SECRET`
- `SALESFORCE_USERNAME`
- `SALESFORCE_PASSWORD`
- `SALESFORCE_SECURITY_TOKEN`
- `RECAPTCHA_SITE_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `GOOGLE_MAPS_API_KEY`

### Website env templates

- `SALESFORCE_BASE_URL`
- `SALESFORCE_API_VERSION`
- `SALESFORCE_CLIENT_ID`
- `SALESFORCE_CLIENT_SECRET`
- `SALESFORCE_USERNAME`
- `SALESFORCE_PASSWORD`
- `SALESFORCE_SECURITY_TOKEN`
- `RECAPTCHA_SITE_KEY`
- `STRIPE_PUBLISHABLE_KEY`

### Deployment service env templates

- `backend-api` templates include:
  - `SALESFORCE_AUTH_HEADER`
  - `SALESFORCE_BASE_URL`
  - `SALESFORCE_CLIENT_ID`
  - `SALESFORCE_CLIENT_SECRET`
  - `SALESFORCE_USERNAME`
  - `SALESFORCE_PASSWORD`
  - `SALESFORCE_SECURITY_TOKEN`
  - `RECAPTCHA_SITE_KEY`
  - `GOOGLE_MAPS_API_KEY`
- `marketing-web` templates include:
  - `RECAPTCHA_SITE_KEY`
