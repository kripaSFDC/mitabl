# Phase 0.5 Implementation (0.5.1-0.5.15)

## 0.5.1 PHP 8.2+ baseline
- `backend/composer.json` now requires `php:^8.2` and sets Composer platform `8.2.0`.
- `backend/Dockerfile` upgraded to `php:8.2-fpm`.

## 0.5.2 Laravel framework upgrade (status: partially complete)
- Current state: `backend/composer.json` is still on `laravel/framework:^8.75`.
- Completed in this phase: upgrade preparation baseline (PHP 8.2 alignment, service extraction, queue/cache hardening, secret externalization).
- Remaining for full completion: execute the Laravel major-version migration path and update dependent packages to Laravel 11-compatible versions.

## 0.5.3 Dart 3+ toolchain
- `mobile-app/pubspec.yaml` SDK constraint set to `>=3.3.0 <4.0.0`.

## 0.5.4 Enforce redis queue in non-test
- `backend/.env.example` and `backend/.env.aws` set `QUEUE_CONNECTION=redis`.
- `backend/config/queue.php` default now resolves to redis outside testing.

## 0.5.5 Dedicated queue workers / Horizon
- `backend/composer.json` includes `laravel/horizon`.
- Worker process definitions added:
  - `deploy/docker-compose.phase0.yml` (`queue-worker`)
  - `deploy/supervisor/queue-worker.conf`
- Container health checks added for `backend-api`, `ops-admin`, `queue-worker`, and `redis` in `deploy/docker-compose.phase0.yml`.
- `backend/config/horizon.php` added.

## 0.5.6 Redis cache backend
- `backend/.env.example` and `backend/.env.aws` set `CACHE_DRIVER=redis`.
- `backend/config/cache.php` defaults to redis outside testing.

## 0.5.7 Discovery endpoint caching
- `backend/app/Services/DiscoveryService.php` now caches nearest/top-rated/recommended responses.
- `backend/app/Services/DiscoveryCacheService.php` provides keying + versioned invalidation.

## 0.5.8 Remove double-fetch pagination patterns
- Replaced `get()->count()` with query-level `count()` in critical paths:
  - discovery endpoints moved to service with query-level counts.
  - `FcmController` and listeners updated.

## 0.5.9 Cache invalidation hooks
- Added invalidation via observers/services:
  - `MikitchnObserver`, `ReviewObserver`, `FoodsObserver`, `CertificateObserver`
  - `KitchenService::invalidateDiscoveryCaches()`

## 0.5.10 StripeTrait -> PaymentService extraction
- Added `backend/app/Services/PaymentService.php`.
- Controllers/listeners now call `PaymentService` via DI or wrappers.
- Removed hard dependency on `StripeTrait` from `UserController`, `OrderController`, and payment listeners.

## 0.5.11 Core service layer extraction
- Added service layer classes:
  - `AuthService`
  - `KitchenService`
  - `OrderService`
  - `DiscoveryService`
- Controllers delegate key logic to services (auth OTP, discovery, order create/payment).

## 0.5.12 Remove hardcoded Salesforce secrets/tokens
- `WebApiToCurlController` and `KitchenVerifiedToSales` now read from `config/services.php` + env.
- `.env.example` scrubbed of plaintext secrets.
- Salesforce org-specific constants moved out of backend/website Blade forms into config/env (`services.salesforce.*`).
- Stripe publishable key hardcodes removed from views/scripts.

## 0.5.13 Async/cache observability
- Discovery logs emit latency + cache hit/miss metrics.
- Queue processing/failure logs added in `AppServiceProvider` hooks.
- Discovery hit/miss counters tracked in cache.

## 0.5.14 Hardening regression tests
- Added `backend/tests/Feature/HardeningRegressionTest.php` for:
  - queue/cache default wiring checks
  - redis queue/cache defaults in env template
  - discovery cache invalidation behavior
  - discovery cache metrics increment
  - secret leakage guardrails
  - Stripe trait removal + PaymentService presence

## 0.5.15 Hardening exit criteria gate
- Criteria codified in `docs/hardening-exit-criteria.md`.
- Gate references concrete files, commands, and verification evidence.
