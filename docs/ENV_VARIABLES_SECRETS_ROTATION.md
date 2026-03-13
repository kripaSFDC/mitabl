# Environment Variables, Secret Rotation, and Platform-Admin Migration Plan

This document was re-audited against the current repository code and deployment assets.

## 1) Audit scope and source of truth

Audit commands used:

- `rg -n "env\(['\"]([A-Z0-9_]+)['\"]" backend --pcre2`
- `rg -n "getenv\(|\$_ENV\[['\"][A-Z0-9_]+['\"]\]|\$_SERVER\[['\"][A-Z0-9_]+['\"]\]" backend deploy docker-compose.yml`
- `rg -n "^[A-Z][A-Z0-9_]*=" backend/.env.example deploy/environments/dev/backend-api.env deploy/environments/staging/backend-api.env deploy/environments/prod/backend-api.env`
- `rg -n "DB_ROOT_PASSWORD|MYSQL_ROOT_PASSWORD" deploy/docker-compose.prod.contabo.yml docker-compose.yml docs/deployment.md docs/Deployment.md`

Env sources currently present and relevant:

- `backend/.env.example` (local/default backend template)
- `deploy/environments/dev/backend-api.env`
- `deploy/environments/staging/backend-api.env`
- `deploy/environments/prod/backend-api.env`
- host/runtime shell `.env` (not committed) used by production compose for `DB_ROOT_PASSWORD`
- `backend/phpunit.xml` (test-only server env overrides)

> Removed obsolete references from this doc:
> - `backend/.env.test` (does not exist)
> - root `.env.example` (does not exist)

---

## 2) Canonical environment variable inventory (with descriptions)

Status legend:

- **Active**: consumed by application/deploy logic now
- **Template-only**: appears in templates and may be consumed when corresponding feature is enabled
- **Test-only**: used for tests only

### A. Core app and API behavior

| Variable | Status | Description |
|---|---|---|
| `APP_NAME` | Active | Application display name; used in config/log labels and defaults. |
| `APP_ENV` | Active | Runtime environment (`local`, `staging`, `production`, `testing`). |
| `APP_DEBUG` | Active | Enables/disables debug mode. |
| `APP_URL` | Active | Canonical backend URL used in links and some notification flows. |
| `APP_SERVICE` | Active | Service identifier used by app service provider logic. |
| `APP_KEY` | Active/Secret | Laravel encryption/signing key. |
| `ASSET_URL` | Active | Optional asset base URL override. |
| `APP_VERSION_MINIMUM` | Active | Minimum supported app version served by app-version endpoint. |
| `APP_VERSION_LATEST` | Active | Latest app version shown to clients. |
| `APP_VERSION_IOS_URL` | Active | iOS app store URL returned for update prompts. |
| `APP_VERSION_ANDROID_URL` | Active | Android store URL returned for update prompts. |

### B. Authentication and security

| Variable | Status | Description |
|---|---|---|
| `JWT_SECRET` | Active/Secret | HMAC secret for JWT signing in current setup. |
| `JWT_TTL` | Active | Access token TTL (minutes). |
| `JWT_REFRESH_TTL` | Active | Refresh token TTL (minutes). |
| `JWT_PUBLIC_KEY` | Template-only/Secret | Optional asymmetric JWT public key path/content. |
| `JWT_PRIVATE_KEY` | Template-only/Secret | Optional asymmetric JWT private key path/content. |
| `JWT_PASSPHRASE` | Template-only/Secret | Passphrase for JWT private key. |
| `JWT_ALGO` | Template-only | JWT algorithm override. |
| `JWT_LEEWAY` | Template-only | JWT validation leeway (seconds). |
| `JWT_BLACKLIST_ENABLED` | Template-only | Enables JWT blacklist behavior. |
| `JWT_BLACKLIST_GRACE_PERIOD` | Template-only | Grace period for blacklisting. |
| `BCRYPT_ROUNDS` | Active | Password hashing cost factor. |
| `SANCTUM_STATEFUL_DOMAINS` | Template-only | Sanctum stateful domains for cookie auth contexts. |

### C. OTP and session behavior

| Variable | Status | Description |
|---|---|---|
| `OTP_EXPIRE_MINUTES` | Active | OTP expiration duration. |
| `OTP_MAX_ATTEMPTS` | Active | Max OTP attempts before lock. |
| `OTP_LOCK_MINUTES` | Active | OTP lockout period. |
| `OTP_MAIL_SUBJECT` | Active | Subject line for OTP email notifications. |
| `SESSION_DRIVER` | Active | Laravel session driver. |
| `SESSION_CONNECTION` | Template-only | Session backend connection name. |
| `SESSION_STORE` | Template-only | Named session store. |
| `SESSION_COOKIE` | Template-only | Session cookie name override. |
| `SESSION_DOMAIN` | Template-only | Cookie domain setting. |
| `SESSION_SECURE_COOKIE` | Template-only | Force secure session cookie flag. |

### D. Database, cache, queue, and Redis

| Variable | Status | Description |
|---|---|---|
| `DB_CONNECTION` | Active | Default DB connection type. |
| `DB_HOST` | Active | DB host. |
| `DB_PORT` | Active | DB port. |
| `DB_DATABASE` | Active | DB name/path. |
| `DB_USERNAME` | Active | DB user. |
| `DB_PASSWORD` | Active/Secret | DB user password for app connection. |
| `DB_ROOT_PASSWORD` | Active/Secret (deploy) | MySQL root password injected into compose for DB container bootstrap. |
| `DATABASE_URL` | Template-only | DSN-style database URL alternative. |
| `DB_FOREIGN_KEYS` | Template-only | SQLite foreign key toggle. |
| `DB_SOCKET` | Template-only | DB UNIX socket path. |
| `MYSQL_ATTR_SSL_CA` | Template-only | MySQL SSL CA cert path. |
| `CACHE_DRIVER` | Active | Cache backend driver. |
| `CACHE_PREFIX` | Template-only | Cache key prefix override. |
| `QUEUE_CONNECTION` | Active | Queue backend driver. |
| `QUEUE_FAILED_DRIVER` | Template-only | Failed-job backend driver. |
| `REDIS_CLIENT` | Template-only | Redis client implementation. |
| `REDIS_URL` | Template-only | Redis URL alternative. |
| `REDIS_HOST` | Active | Redis host. |
| `REDIS_PASSWORD` | Active | Redis password (if set). |
| `REDIS_PORT` | Active | Redis port. |
| `REDIS_DB` | Template-only | Redis DB index for default connection. |
| `REDIS_CACHE_DB` | Template-only | Redis DB index for cache connection. |
| `REDIS_CLUSTER` | Template-only | Redis clustering mode. |
| `REDIS_PREFIX` | Template-only | Redis key prefix. |
| `REDIS_QUEUE` | Template-only | Redis queue name. |
| `SQS_PREFIX` | Template-only | SQS queue URL prefix. |
| `SQS_QUEUE` | Template-only | SQS queue name. |
| `SQS_SUFFIX` | Template-only | SQS queue suffix. |
| `PERMISSION_CACHE_STORE` | Active | Spatie permissions cache store selector. |
| `HORIZON_DOMAIN` | Template-only | Horizon UI domain override. |
| `HORIZON_PATH` | Active | Horizon UI path. |
| `HORIZON_PREFIX` | Active | Horizon Redis key prefix. |

### E. Storage, mail, and third-party integrations

| Variable | Status | Description |
|---|---|---|
| `FILESYSTEM_DRIVER` | Active | Default filesystem disk. |
| `AWS_ACCESS_KEY_ID` | Template-only/Secret | AWS access key for S3/cache/queue integrations. |
| `AWS_SECRET_ACCESS_KEY` | Template-only/Secret | AWS secret access key. |
| `AWS_DEFAULT_REGION` | Template-only | AWS region. |
| `AWS_BUCKET` | Template-only | S3 bucket name. |
| `AWS_URL` | Template-only | S3/custom storage URL. |
| `AWS_ENDPOINT` | Template-only | Custom S3-compatible endpoint. |
| `AWS_USE_PATH_STYLE_ENDPOINT` | Template-only | Path-style endpoint toggle. |
| `MAIL_MAILER` | Active | Mail transport driver. |
| `MAIL_HOST` | Active | SMTP host. |
| `MAIL_PORT` | Active | SMTP port. |
| `MAIL_USERNAME` | Active/Secret | SMTP username (if auth required). |
| `MAIL_PASSWORD` | Active/Secret | SMTP password. |
| `MAIL_ENCRYPTION` | Active | SMTP encryption mode (`tls`, etc.). |
| `MAIL_SENDMAIL_PATH` | Template-only | Sendmail binary path (sendmail mailer). |
| `MAIL_LOG_CHANNEL` | Template-only | Mail log channel for log mailer. |
| `MAIL_FROM_ADDRESS` | Active | Default outbound sender address. |
| `MAIL_FROM_NAME` | Active | Default outbound sender name. |
| `MAILGUN_DOMAIN` | Template-only | Mailgun domain. |
| `MAILGUN_SECRET` | Template-only/Secret | Mailgun API key. |
| `MAILGUN_ENDPOINT` | Template-only | Mailgun API endpoint override. |
| `POSTMARK_TOKEN` | Template-only/Secret | Postmark API token. |
| `STRIPE_SECRET_KEY` | Template-only/Secret | Stripe secret API key. |
| `STRIPE_PUBLISHABLE_KEY` | Template-only | Stripe publishable key. |
| `STRIPE_CLIENT_ID` | Template-only | Stripe Connect client ID. |
| `STRIPE_REDIRECT_URI` | Template-only | Stripe Connect callback URI. |
| `STRIPE_AUTHORIZATION_URI` | Template-only | Stripe authorization endpoint URI. |
| `STRIPE_WEBHOOK_SIGNING_SECRET` | Template-only/Secret | Stripe webhook signing secret. |
| `STRIPE_CURRENCY` | Template-only | Default Stripe currency code. |
| `STRIPE_CONNECTED_ACCOUNT_COUNTRY` | Template-only | Default connected-account country. |
| `STRIPE_DASHBOARD_BASE_URL` | Template-only | Base URL used for Stripe dashboard links. |
| `BROADCAST_DRIVER` | Template-only | Broadcast driver selector. |
| `PUSHER_APP_ID` | Template-only | Pusher app ID. |
| `PUSHER_APP_KEY` | Template-only | Pusher app key. |
| `PUSHER_APP_SECRET` | Template-only/Secret | Pusher app secret. |
| `PUSHER_APP_CLUSTER` | Template-only | Pusher cluster. |
| `ABLY_KEY` | Template-only/Secret | Ably API key. |

### F. Logging and diagnostics

| Variable | Status | Description |
|---|---|---|
| `LOG_CHANNEL` | Active | Default Laravel log channel. |
| `LOG_DEPRECATIONS_CHANNEL` | Template-only | Deprecation log channel. |
| `LOG_LEVEL` | Active | Global log level for multiple channels. |
| `LOG_SLACK_WEBHOOK_URL` | Template-only/Secret | Slack webhook URL for critical logs. |
| `LOG_STDERR_FORMATTER` | Template-only | Formatter override for stderr channel. |
| `PAPERTRAIL_URL` | Template-only | Papertrail endpoint host. |
| `PAPERTRAIL_PORT` | Template-only | Papertrail endpoint port. |

### G. Swagger and misc framework tuning

| Variable | Status | Description |
|---|---|---|
| `L5_SWAGGER_USE_ABSOLUTE_PATH` | Template-only | Swagger UI absolute-path behavior. |
| `L5_FORMAT_TO_USE_FOR_DOCS` | Template-only | Swagger docs output format. |
| `L5_SWAGGER_BASE_PATH` | Template-only | Swagger base path override. |
| `L5_SWAGGER_UI_ASSETS_PATH` | Template-only | Swagger UI assets location. |
| `L5_SWAGGER_GENERATE_ALWAYS` | Template-only | Regenerate docs on every request. |
| `L5_SWAGGER_GENERATE_YAML_COPY` | Template-only | Also emit YAML docs. |
| `L5_SWAGGER_OPERATIONS_SORT` | Template-only | Swagger operation sort order. |
| `L5_SWAGGER_UI_DOC_EXPANSION` | Template-only | Swagger UI expansion mode. |
| `L5_SWAGGER_UI_FILTERS` | Template-only | Enable Swagger UI filtering. |
| `L5_SWAGGER_UI_PERSIST_AUTHORIZATION` | Template-only | Persist auth in Swagger UI. |
| `L5_SWAGGER_CONST_HOST` | Template-only | Swagger host constant. |
| `VIEW_COMPILED_PATH` | Template-only | Custom compiled blade view path. |
| `MEMCACHED_PERSISTENT_ID` | Template-only | Memcached persistent ID. |
| `MEMCACHED_USERNAME` | Template-only/Secret | Memcached SASL username. |
| `MEMCACHED_PASSWORD` | Template-only/Secret | Memcached SASL password. |
| `MEMCACHED_HOST` | Template-only | Memcached host. |
| `MEMCACHED_PORT` | Template-only | Memcached port. |
| `DYNAMODB_CACHE_TABLE` | Template-only | DynamoDB table for cache store. |
| `DYNAMODB_ENDPOINT` | Template-only | DynamoDB endpoint override. |

### H. Boot-time automation and one-time bootstrap

| Variable | Status | Description |
|---|---|---|
| `RUN_MIGRATIONS_ON_BOOT` | Active | If `true`, run migrations in container boot script. |
| `RUN_SEEDERS_ON_BOOT` | Active | If `true`, run default seeders at boot. |
| `RUN_PERMISSION_SEED_ON_BOOT` | Active | If `true`, run role/permission seeder on boot. |
| `ADMIN_BOOTSTRAP_EMAIL` | Active (conditional) | Initial admin email used by production seeder. |
| `ADMIN_BOOTSTRAP_NAME` | Active (conditional) | Initial admin name used by production seeder. |
| `ADMIN_BOOTSTRAP_PASSWORD` | Active (conditional, Secret) | Initial admin password used by production seeder. |

### I. Test-only env variables

| Variable | Status | Description |
|---|---|---|
| `TELESCOPE_ENABLED` | Test-only/Obsolete candidate | Present in `phpunit.xml` test server vars, but no current code references found. |

---

### J. Runtime/system-provided variables (not operator-managed env templates)

| Variable | Status | Description |
|---|---|---|
| `APP_BASE_PATH` | Runtime/internal | Optional bootstrap override read in `bootstrap/app.php`; normally unset and defaults to project root. |
| `REQUEST_URI` | Runtime/internal | Web server request path from `$_SERVER`; not a deploy-time environment variable. |

---

## 3) Secrets classification and rotation tiers

### Tier 0 (critical/high-impact)

- `APP_KEY`
- `JWT_SECRET` (or `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY` + `JWT_PASSPHRASE` in asymmetric mode)
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`

### Tier 1 (integration credentials)

- `MAIL_PASSWORD`, `MAILGUN_SECRET`, `POSTMARK_TOKEN`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SIGNING_SECRET`
- `AWS_SECRET_ACCESS_KEY`
- `PUSHER_APP_SECRET`, `ABLY_KEY`
- `LOG_SLACK_WEBHOOK_URL`

### Tier 2 (sensitive but lower blast radius)

- `ADMIN_BOOTSTRAP_PASSWORD` (bootstrap-only; should not be kept long-lived)
- `MAIL_USERNAME`, `MEMCACHED_USERNAME`, `MEMCACHED_PASSWORD`

---

## 4) Updated secret rotation runbook

1. **Prepare**
   - Identify target secret and all set points (env templates, CI/CD, runtime secret manager, host shell `.env` for `DB_ROOT_PASSWORD`).
   - Confirm rollback path.
2. **Generate**
   - Produce strong replacement using approved secret tooling.
3. **Dual-control update (recommended)**
   - For provider-backed credentials (Stripe/mail/AWS), create new credential first and keep old one active during cutover.
4. **Deploy changes**
   - Update secret store/env injection and redeploy/restart affected services:
     - `backend`
     - `queue-worker`
     - `scheduler`
   - If config is cached in runtime images, run `php artisan config:clear` (or rebuild cache) before health verification.
5. **Validate**
   - `curl -fsS http://127.0.0.1:8000/api/health/live`
   - `curl -fsS http://127.0.0.1:8000/api/health/ready`
   - `php artisan platform:health:synthetic`
   - `php artisan horizon:status`
   - Execute one integration-specific smoke test (mail send, Stripe webhook signature verify, S3 write, etc.).
6. **Revoke old secret**
   - Disable/revoke old credential only after validation.
7. **Audit evidence**
   - Record ticket/change ID, actor, timestamp, impacted services, and validation artifacts.

### Rotation caveats by secret

- `APP_KEY`: rotation invalidates encrypted payloads/sessions; schedule maintenance window.
- `JWT_SECRET`: rotation invalidates active JWT sessions; communicate forced re-auth.
- `DB_PASSWORD`/`DB_ROOT_PASSWORD`: rotate DB-side credential and runtime env atomically.
- `ADMIN_BOOTSTRAP_PASSWORD`: keep unset except during deliberate bootstrap seeding.

---

## 5) Recommendation: envs that should move to platform-admin configurable controls

These values are safe/high-value to move from deployment env into DB-backed platform settings with audited admin controls:

### Strong candidates (move first)

- **App version policy:** `APP_VERSION_MINIMUM`, `APP_VERSION_LATEST`, `APP_VERSION_IOS_URL`, `APP_VERSION_ANDROID_URL`
  - Why: product/ops tuning; frequent updates; no redeploy needed.
- **OTP policy:** `OTP_EXPIRE_MINUTES`, `OTP_MAX_ATTEMPTS`, `OTP_LOCK_MINUTES`, `OTP_MAIL_SUBJECT`
  - Why: risk/fraud tuning driven by support/security ops.
- **Operational toggles currently in env:** `RUN_MIGRATIONS_ON_BOOT`, `RUN_SEEDERS_ON_BOOT`, `RUN_PERMISSION_SEED_ON_BOOT`
  - Why: should become explicit runbook actions or protected admin operations, not static env flips.
- **Horizon/UI knobs:** `HORIZON_PATH` (possibly), queue policy defaults like `REDIS_QUEUE`
  - Why: operational ergonomics; can be guarded behind advanced settings.
- **Observability knobs:** `LOG_LEVEL` (bounded enum), selected `LOG_CHANNEL` profiles
  - Why: incident response often needs temporary verbosity changes.

### Conditional candidates (move only with guardrails)

- **Mail sender identity:** `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`
- **Session policy:** `SESSION_DOMAIN`, `SESSION_SECURE_COOKIE`
- **API docs behavior:** `L5_SWAGGER_*` values for non-prod admin environments

### Keep as environment secrets (do **not** move to plain admin settings)

- `APP_KEY`, JWT signing keys/secrets, DB credentials, Stripe/AWS/mail provider secrets, webhook secrets.

If credentials are editable in admin, they must use secret-vault references and never be stored plaintext in app DB.

---

## 6) Additional platform-admin capability improvements

1. **Typed settings registry**
   - Enforce schema per setting (`string`, `int`, `bool`, enum, URL) + min/max validation.
2. **Secret reference model**
   - Store `secret_ref` (e.g., vault path), not raw secret values.
3. **Change workflow for risky settings**
   - Two-person approval + reason code + optional expiry for temporary overrides.
4. **Dry-run / simulation mode**
   - Show affected services/components before applying a setting.
5. **Scoped rollout support**
   - Apply settings by environment (`staging` first, then `prod`) and by service.
6. **Audit trail hardening**
   - Immutable append-only audit entries with diff snapshots and actor identity.
7. **Runtime health coupling**
   - Block “apply” completion unless health checks stay green for configurable soak time.
8. **Config drift detection**
   - Compare effective runtime config vs desired platform settings and alert on drift.
9. **Emergency rollback shortcut**
   - One-click revert to last known-good setting bundle.
10. **Policy bundles/templates**
   - Presets for OTP/security/logging profiles (normal / incident / hardened).

---

## 7) Obsolete/cleanup items found during review

- `backend/.env.test` reference is obsolete (file absent).
- root `.env.example` reference is obsolete (file absent).
- `TELESCOPE_ENABLED` appears only in `phpunit.xml` and has no active code usage; safe to remove from tests unless planned for future use.
