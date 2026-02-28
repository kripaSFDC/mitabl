# Hardening Exit Criteria (G0.5)

A release can proceed to Phase 1 only when all items are true.

## Required
- `QUEUE_CONNECTION=redis` in deployed env for dev/staging/prod.
- Redis cache active (`CACHE_DRIVER=redis`) in deployed env.
- Queue workers running (`queue:work redis` or Horizon supervisors healthy).
- No hardcoded Salesforce/Stripe secrets in source templates.
- Discovery endpoints served through cache wrappers.
- Cache invalidation triggered by kitchen/menu/certificate/review changes.
- Discovery telemetry logs include latency and cache hit/miss signals.
- Failed jobs are logged and visible.
- Hardening regression tests pass.
- Framework baseline matches plan target (`laravel/framework` at major 11).

## Verification commands
- `rg -n "sk_test_|pk_test_|00D0w|Integration@" backend website --glob '!**/tests/**'`
- `php artisan test --filter=HardeningRegressionTest`
- `php artisan queue:failed`
- Request and compare discovery endpoint latency in logs (`discovery.api.metrics`).
- `rg -n "\"laravel/framework\"" backend/composer.json` (verify major version target).

## Exit record template
- Date:
- Environment:
- Verified by:
- Queue async evidence:
- Cache evidence:
- Secret scan evidence:
- Regression test evidence:
- Go/No-Go:
