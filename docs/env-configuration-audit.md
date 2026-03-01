# Environment Configuration Audit

This audit summarizes two outcomes:

1. **Unused / obsolete environment variables removed** from checked-in `.env` templates.
2. **Recommended candidates for dynamic admin-managed settings** (instead of deploy-time `.env` values).

## 1) Removed obsolete variables

The following variables were present in `.env` templates but have no runtime references in application code/config:

- `SALESFORCE_AUTH_HEADER`
- `SALESFORCE_BASE_URL`
- `SALESFORCE_API_VERSION`
- `SALESFORCE_CLIENT_ID`
- `SALESFORCE_CLIENT_SECRET`
- `SALESFORCE_USERNAME`
- `SALESFORCE_PASSWORD`
- `SALESFORCE_SECURITY_TOKEN`
- `SUPPORT_MOBCONTACT_ALIAS_SUNSET`
- `SUPPORT_MOBCONTACT_ALIAS_REPLACEMENT_PATH`
- `ADMIN_IP_ALLOWLIST`
- `ADMIN_REQUIRE_MFA`
- `BROADCAST_CONNECTION` (legacy naming in `backend/myproject/.env.example`)
- `VITE_APP_NAME` (unused in this repository)

## 2) Candidate env values to move to admin portal

The platform already exposes admin-facing settings surfaces (for example `PlatformSettingsPage` and `SecurityAdminPage`). The following env-backed values are strong candidates to migrate into DB-backed/admin-managed settings for live operations tuning.

### High-value operational candidates

- `SUPPORT_DUPLICATE_WINDOW_MINUTES`
- `SUPPORT_REOPEN_WINDOW_HOURS`
- `SUPPORT_HONEYPOT_FIELD`
- `SUPPORT_SLA_FIRST_RESPONSE_MINUTES`
- `SUPPORT_SLA_RESOLUTION_MINUTES`
- `SUPPORT_SLA_LOW_FIRST_RESPONSE_MINUTES`
- `SUPPORT_SLA_LOW_RESOLUTION_MINUTES`
- `SUPPORT_SLA_NORMAL_FIRST_RESPONSE_MINUTES`
- `SUPPORT_SLA_NORMAL_RESOLUTION_MINUTES`
- `SUPPORT_SLA_HIGH_FIRST_RESPONSE_MINUTES`
- `SUPPORT_SLA_HIGH_RESOLUTION_MINUTES`
- `SUPPORT_SLA_URGENT_FIRST_RESPONSE_MINUTES`
- `SUPPORT_SLA_URGENT_RESOLUTION_MINUTES`

**Why:** These are business policy/SLA knobs and are frequently adjusted by operations teams.

### Security / policy candidates

- `ADMIN_REAUTH_MINUTES`
- `SESSION_LIFETIME`
- `SESSION_EXPIRE_ON_CLOSE`

**Why:** Security posture often needs controlled, audited runtime adjustments by authorized admins.

### Integration behavior (non-secret) candidates

- `STRIPE_DASHBOARD_BASE_URL`
- `STRIPE_REDIRECT_URI`

**Why:** These are endpoint/policy values (not secret keys) and can reasonably be changed without redeploys in controlled environments.

## Keep as environment secrets / infrastructure

The following classes should remain env/secret manager managed (not admin-editable in UI):

- Cryptographic and auth secrets (`APP_KEY`, `JWT_SECRET`, OAuth client secrets, API secret keys)
- Database/queue/cache infrastructure endpoints and credentials (`DB_*`, `REDIS_*`, `AWS_*` credential material)
- Mail/third-party secret credentials (`MAIL_*` passwords/API keys, webhook tokens)

These values are deployment/security-bound and should continue to be managed by infrastructure secret stores.
