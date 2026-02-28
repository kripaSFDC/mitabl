# Phase 6 Load Testing

Scope: `mitabl_enhancement_plan.md` -> **6.6 Load tests on ticket intake and admin lists**

## Pre-requisites

1. k6 installed (`https://k6.io/docs/get-started/installation/`)
2. Staging environment deployed with:
   - `backend-api` reachable
   - `ops-admin` reachable
   - Redis queue workers (Horizon) healthy
3. Test-only admin session cookie for Filament pages

## Scripts

- `support-intake-load-test.js`
  - Exercises `POST /api/support/ticket`
  - Supports optional `CAPTCHA_TOKEN` env var when reCAPTCHA validation is enabled in target env
  - Thresholds:
    - `http_req_failed < 2%`
    - `p95 < 750ms`
- `admin-list-load-test.js`
  - Exercises `/admin/policies` and `/admin/support-tickets`
  - Requires `ADMIN_COOKIE`
  - Thresholds:
    - `http_req_failed < 1%`
    - `p95 < 900ms`

## Run Commands

```bash
# Support intake API load
k6 run deploy/load-tests/support-intake-load-test.js -e BASE_URL=https://staging.mitabl.com

# Support intake API load (when captcha is enabled)
k6 run deploy/load-tests/support-intake-load-test.js \
  -e BASE_URL=https://staging.mitabl.com \
  -e CAPTCHA_TOKEN="<valid-captcha-token>"

# Admin list load
k6 run deploy/load-tests/admin-list-load-test.js \
  -e BASE_URL=https://staging.mitabl.com \
  -e ADMIN_COOKIE="laravel_session=<session>; XSRF-TOKEN=<token>"
```

## Reporting

- Save k6 summary output and threshold status.
- Capture p50/p95/p99 and failure rate.
- Attach artifacts to Phase 6 validation report.
