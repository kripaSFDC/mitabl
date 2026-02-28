# Phase 0 Implementation (0.1-0.7)

## 0.1 Repository boundaries
- `backend/` owns API and internal ops/admin runtime.
- `website/` remains the public marketing surface.
- `mobile-app/` remains end-user channel only.

## 0.2 Same-domain ingress routes
Implemented in `deploy/nginx/mitabl.phase0.conf`:
- `/` -> `marketing-web`
- `/api/*` -> `backend-api`
- `/admin/*` -> `ops-admin`

## 0.3 Runtime split
Implemented in `deploy/docker-compose.phase0.yml`:
- Shared backend artifact with two services:
  - `backend-api`
  - `ops-admin`
- Dedicated `queue-worker` and shared `redis`.

## 0.4 TLS and gateway hardening
Implemented in `deploy/nginx/mitabl.phase0.conf`:
- HTTP to HTTPS redirect.
- TLS certificate placeholders.
- HSTS header (`max-age=31536000; includeSubDomains`).
- `/admin/*` segmented with stricter controls.

## 0.5 Admin network controls
Implemented in `deploy/nginx/mitabl.phase0.conf` and `deploy/environments/ops-admin.env`:
- IP allowlist gating at ingress for `/admin/*`.
- `ADMIN_REQUIRE_MFA=true` runtime flag for policy enforcement.

## 0.6 Deployment environments
Implemented in `deploy/environments/`:
- `backend-api.env`
- `ops-admin.env`
- `marketing-web.env`

These files standardize parity for dev/staging/prod by using service-scoped env templates.

## 0.7 Secrets management plan
Implemented in `docs/secrets-management.md` and enforced by sanitized `.env.example`.
- No static secrets in source.
- All credentials loaded from environment/secret manager.
- Rotation and verification workflow documented.
