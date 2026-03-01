# Load Testing

Scope: Admin/CRM list page performance validation.

## Pre-requisites

1. k6 installed (`https://k6.io/docs/get-started/installation/`)
2. Staging environment deployed with:
   - `ops-admin` reachable
   - Redis queue workers (Horizon) healthy
3. Test-only admin session cookie for Filament pages

## Scripts

- `admin-list-load-test.js`
  - Exercises `/admin/policies` and `/admin/support-tickets`
  - Requires `ADMIN_COOKIE`
  - Thresholds:
    - `http_req_failed < 1%`
    - `p95 < 900ms`

## Run Commands

```bash
k6 run deploy/load-tests/admin-list-load-test.js \
  -e BASE_URL=https://staging.mitabl.com \
  -e ADMIN_COOKIE="laravel_session=<session>; XSRF-TOKEN=<token>"
```

## Reporting

- Save k6 summary output and threshold status.
- Capture p50/p95/p99 and failure rate.
