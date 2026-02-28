# Secrets Management Plan

## Scope
Applies to backend API, ops-admin, queue workers, and website runtime secrets.

## Rules
1. Do not commit plaintext tokens, API keys, OAuth secrets, or private keys.
2. `.env.example` contains placeholders only.
3. Deployments inject secrets from secret managers (AWS Secrets Manager, Azure Key Vault, or equivalent).
4. Runtime reads secrets via environment variables only.
5. Tenant-specific integration identifiers and URLs must not be hardcoded in committed templates or scripts.

## Required secret sets
- Stripe: `STRIPE_SECRET_KEY`, `STRIPE_CLIENT_ID`, `STRIPE_REDIRECT_URI`
- Auth and session: `APP_KEY`, `JWT_SECRET`
- FCM: `FCM_SERVER_KEY`
- Database and Redis credentials

## Rotation baseline
- Rotate leaked/legacy values immediately.
- Rotate Stripe credentials during cutover.
- Keep change ticket/audit reference for each rotation.

## Verification checklist
- `rg -n "sk_test_|pk_test_|client_secret" backend website --glob '!**/tests/**'` returns no hardcoded credentials.
- Production env references secrets from manager, not source-controlled files.
- CI variables masked and protected.
- CI secret scan gate passes in `.github/workflows/ci-cd.yml` (`secret-scan` job).
