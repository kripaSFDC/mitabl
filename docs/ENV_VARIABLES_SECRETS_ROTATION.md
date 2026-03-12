# Environment Variables and Secrets Rotation

This document is limited to what the current codebase actually uses.

## Source of Truth

These files are the env sources currently present in the repo:

- `backend/.env.example`: local backend defaults.
- `backend/.env.test`: PHPUnit/test defaults.
- `deploy/environments/dev/backend-api.env`: Docker dev runtime.
- `deploy/environments/staging/backend-api.env`: staging runtime template.
- `deploy/environments/prod/backend-api.env`: production runtime template.
- `.env.example`: root-level compose variable source for `DB_ROOT_PASSWORD`.

The backend container startup flow is implemented in `backend/start-server.sh`. Production compose wiring is in `deploy/docker-compose.prod.contabo.yml`. Local Docker wiring is in `docker-compose.yml`.

## Variables Actively Configured in This Repo

These are the variables currently populated in one or more committed env templates and consumed by the running stack.

### Core application

- `APP_NAME`
- `APP_ENV`
- `APP_DEBUG`
- `APP_URL`
- `APP_SERVICE`
- `APP_KEY`

### JWT auth

- `JWT_SECRET`
- `JWT_TTL`
- `JWT_REFRESH_TTL`

### Database

- `DB_CONNECTION`
- `DB_HOST`
- `DB_PORT`
- `DB_DATABASE`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`

### Queue, cache, session, Redis

- `QUEUE_CONNECTION`
- `HORIZON_PREFIX`
- `CACHE_DRIVER`
- `SESSION_DRIVER`
- `REDIS_HOST`
- `REDIS_PASSWORD`
- `REDIS_PORT`

### Boot-time automation

- `RUN_MIGRATIONS_ON_BOOT`
- `RUN_SEEDERS_ON_BOOT`
- `RUN_PERMISSION_SEED_ON_BOOT`

### Production bootstrap admin

Used only by `Database\\Seeders\\AdminUserSeeder` in production, and only matters when `RUN_SEEDERS_ON_BOOT=true`.

- `ADMIN_BOOTSTRAP_EMAIL`
- `ADMIN_BOOTSTRAP_NAME`
- `ADMIN_BOOTSTRAP_PASSWORD`

## Variables Supported by Code But Not Populated in Deployment Templates

These variables are still live in the codebase, but they are not part of the committed `deploy/environments/*/backend-api.env` files today.

### Mail

- `MAIL_MAILER`
- `MAIL_HOST`
- `MAIL_PORT`
- `MAIL_USERNAME`
- `MAIL_PASSWORD`
- `MAIL_ENCRYPTION`
- `MAIL_SENDMAIL_PATH`
- `MAIL_LOG_CHANNEL`
- `MAIL_FROM_ADDRESS`
- `MAIL_FROM_NAME`
- `MAILGUN_DOMAIN`
- `MAILGUN_SECRET`
- `MAILGUN_ENDPOINT`
- `POSTMARK_TOKEN`

### Stripe

- `STRIPE_SECRET_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_CLIENT_ID`
- `STRIPE_REDIRECT_URI`
- `STRIPE_AUTHORIZATION_URI`
- `STRIPE_WEBHOOK_SIGNING_SECRET`
- `STRIPE_CURRENCY`
- `STRIPE_CONNECTED_ACCOUNT_COUNTRY`
- `STRIPE_DASHBOARD_BASE_URL`

### Session hardening

- `SESSION_CONNECTION`
- `SESSION_STORE`
- `SESSION_COOKIE`
- `SESSION_DOMAIN`
- `SESSION_SECURE_COOKIE`

### OTP behavior

- `OTP_EXPIRE_MINUTES`
- `OTP_MAX_ATTEMPTS`
- `OTP_LOCK_MINUTES`
- `OTP_MAIL_SUBJECT`

### Logging

- `LOG_CHANNEL`
- `LOG_DEPRECATIONS_CHANNEL`
- `LOG_LEVEL`
- `LOG_SLACK_WEBHOOK_URL`
- `LOG_STDERR_FORMATTER`
- `PAPERTRAIL_URL`
- `PAPERTRAIL_PORT`

### Storage and AWS-backed integrations

- `FILESYSTEM_DRIVER`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `AWS_BUCKET`
- `AWS_URL`
- `AWS_ENDPOINT`
- `AWS_USE_PATH_STYLE_ENDPOINT`

### Broadcasting

- `BROADCAST_DRIVER`
- `PUSHER_APP_ID`
- `PUSHER_APP_KEY`
- `PUSHER_APP_SECRET`
- `PUSHER_APP_CLUSTER`
- `ABLY_KEY`

### Redis, queue, cache, and database advanced options

- `DATABASE_URL`
- `DB_FOREIGN_KEYS`
- `DB_SOCKET`
- `MYSQL_ATTR_SSL_CA`
- `REDIS_CLIENT`
- `REDIS_URL`
- `REDIS_DB`
- `REDIS_CACHE_DB`
- `REDIS_CLUSTER`
- `REDIS_PREFIX`
- `REDIS_QUEUE`
- `CACHE_PREFIX`
- `QUEUE_FAILED_DRIVER`
- `SQS_PREFIX`
- `SQS_QUEUE`
- `SQS_SUFFIX`
- `HORIZON_DOMAIN`
- `HORIZON_PATH`
- `PERMISSION_CACHE_STORE`

### JWT advanced options

- `JWT_PUBLIC_KEY`
- `JWT_PRIVATE_KEY`
- `JWT_PASSPHRASE`
- `JWT_ALGO`
- `JWT_LEEWAY`
- `JWT_BLACKLIST_ENABLED`
- `JWT_BLACKLIST_GRACE_PERIOD`

### Swagger and misc Laravel config

- `ASSET_URL`
- `SANCTUM_STATEFUL_DOMAINS`
- `BCRYPT_ROUNDS`
- `VIEW_COMPILED_PATH`
- `MEMCACHED_PERSISTENT_ID`
- `MEMCACHED_USERNAME`
- `MEMCACHED_PASSWORD`
- `MEMCACHED_HOST`
- `MEMCACHED_PORT`
- `DYNAMODB_CACHE_TABLE`
- `DYNAMODB_ENDPOINT`
- `L5_SWAGGER_USE_ABSOLUTE_PATH`
- `L5_FORMAT_TO_USE_FOR_DOCS`
- `L5_SWAGGER_BASE_PATH`
- `L5_SWAGGER_UI_ASSETS_PATH`
- `L5_SWAGGER_GENERATE_ALWAYS`
- `L5_SWAGGER_GENERATE_YAML_COPY`
- `L5_SWAGGER_OPERATIONS_SORT`
- `L5_SWAGGER_UI_DOC_EXPANSION`
- `L5_SWAGGER_UI_FILTERS`
- `L5_SWAGGER_UI_PERSIST_AUTHORIZATION`
- `L5_SWAGGER_CONST_HOST`

## Secrets vs Non-Secrets

Treat these as secrets:

- `APP_KEY`
- `JWT_SECRET`
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`
- `ADMIN_BOOTSTRAP_PASSWORD`
- `MAIL_PASSWORD`
- `MAILGUN_SECRET`
- `POSTMARK_TOKEN`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SIGNING_SECRET`
- `AWS_SECRET_ACCESS_KEY`
- `PUSHER_APP_SECRET`
- `ABLY_KEY`
- `JWT_PRIVATE_KEY`
- `JWT_PASSPHRASE`

Usually not secrets:

- `APP_ENV`
- `APP_DEBUG`
- `APP_URL`
- `APP_SERVICE`
- `DB_HOST`
- `DB_PORT`
- `DB_DATABASE`
- `DB_USERNAME`
- `QUEUE_CONNECTION`
- `CACHE_DRIVER`
- `SESSION_DRIVER`
- `REDIS_HOST`
- `REDIS_PORT`

## Rotation Runbook

Use this workflow for any real secret currently used by the stack.

1. Identify the secret and every place it is set:
   - root compose `.env` / `.env.example` for `DB_ROOT_PASSWORD`
   - `deploy/environments/<env>/backend-api.env`
   - any external secret manager if one is used outside git
2. Generate the replacement value.
3. Update the target environment file or secret store.
4. Redeploy or restart the affected containers:
   - `backend`
   - `queue-worker`
   - `scheduler`
5. Validate:
   - `curl -fsS http://127.0.0.1:8000/api/health/live`
   - `curl -fsS http://127.0.0.1:8000/api/health/ready`
   - `php artisan platform:health:synthetic`
   - `php artisan horizon:status`
6. Revoke the old provider-side credential after the new one is confirmed healthy.

## Rotation Notes by Secret Type

### `APP_KEY`

- High impact.
- Rotating it invalidates Laravel encrypted payloads and can affect sessions and any data encrypted with the old key.
- Rotate only in a planned maintenance window.

### `JWT_SECRET`

- Rotating it invalidates existing JWTs.
- Expect API/mobile users to be forced to authenticate again.

### `DB_PASSWORD` and `DB_ROOT_PASSWORD`

- Change the database credential first in MySQL, then update compose/env configuration, then restart services.
- `DB_ROOT_PASSWORD` is only for the MySQL container itself.
- `DB_PASSWORD` is the backend application's database credential.

### `ADMIN_BOOTSTRAP_PASSWORD`

- This is not a standing runtime dependency.
- It is only consumed by `AdminUserSeeder` during production seeding.
- After first bootstrap, keep it unset unless you intentionally re-run bootstrap seeding.

### Provider secrets such as Stripe, mail, AWS, Pusher, Ably

- Rotate in the provider console first.
- Update the env value.
- Restart `backend` and `queue-worker` so web requests and async jobs pick up the new credential.

## What Was Removed From the Old Version

The previous version of this document listed a generic Laravel inventory of 171 variables and implied that all of them were active. That was not true for this repo. This version keeps only:

- variables committed in current env templates
- variables directly referenced by current code
- rotation steps that match the actual health checks and process model in this repository
