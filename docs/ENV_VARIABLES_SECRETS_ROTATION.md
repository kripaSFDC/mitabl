# Environment Variables & Secrets Rotation Runbook

## Active Environment Variable Inventory

Total active env variables: **171**.

> Keep `backend/.env.example` and deployment env templates under `deploy/environments/` in sync with this list.

- `ABLY_KEY`
- `APP_DEBUG`
- `APP_ENV`
- `APP_FAKER_LOCALE`
- `APP_FALLBACK_LOCALE`
- `APP_KEY`
- `APP_LOCALE`
- `APP_MAINTENANCE_DRIVER`
- `APP_MAINTENANCE_STORE`
- `APP_NAME`
- `APP_PREVIOUS_KEYS`
- `APP_SERVICE`
- `APP_URL`
- `ASSET_URL`
- `AUTH_GUARD`
- `AUTH_MODEL`
- `AUTH_PASSWORD_BROKER`
- `AUTH_PASSWORD_RESET_TOKEN_TABLE`
- `AUTH_PASSWORD_TIMEOUT`
- `AWS_ACCESS_KEY_ID`
- `AWS_BUCKET`
- `AWS_DEFAULT_REGION`
- `AWS_ENDPOINT`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_URL`
- `AWS_USE_PATH_STYLE_ENDPOINT`
- `BCRYPT_ROUNDS`
- `BEANSTALKD_QUEUE`
- `BEANSTALKD_QUEUE_HOST`
- `BEANSTALKD_QUEUE_RETRY_AFTER`
- `BROADCAST_DRIVER`
- `CACHE_DRIVER`
- `CACHE_PREFIX`
- `CACHE_STORE`
- `DATABASE_URL`
- `DB_CACHE_CONNECTION`
- `DB_CACHE_LOCK_CONNECTION`
- `DB_CACHE_LOCK_TABLE`
- `DB_CACHE_TABLE`
- `DB_CHARSET`
- `DB_COLLATION`
- `DB_CONNECTION`
- `DB_DATABASE`
- `DB_ENCRYPT`
- `DB_FOREIGN_KEYS`
- `DB_HOST`
- `DB_PASSWORD`
- `DB_PORT`
- `DB_QUEUE`
- `DB_QUEUE_CONNECTION`
- `DB_QUEUE_RETRY_AFTER`
- `DB_QUEUE_TABLE`
- `DB_SOCKET`
- `DB_SSLMODE`
- `DB_TRUST_SERVER_CERTIFICATE`
- `DB_URL`
- `DB_USERNAME`
- `DYNAMODB_CACHE_TABLE`
- `DYNAMODB_ENDPOINT`
- `FILESYSTEM_DISK`
- `FILESYSTEM_DRIVER`
- `HORIZON_DOMAIN`
- `HORIZON_PATH`
- `HORIZON_PREFIX`
- `JWT_ALGO`
- `JWT_BLACKLIST_ENABLED`
- `JWT_BLACKLIST_GRACE_PERIOD`
- `JWT_LEEWAY`
- `JWT_PASSPHRASE`
- `JWT_PRIVATE_KEY`
- `JWT_PUBLIC_KEY`
- `JWT_REFRESH_TTL`
- `JWT_SECRET`
- `JWT_TTL`
- `L5_FORMAT_TO_USE_FOR_DOCS`
- `L5_SWAGGER_BASE_PATH`
- `L5_SWAGGER_CONST_HOST`
- `L5_SWAGGER_GENERATE_ALWAYS`
- `L5_SWAGGER_GENERATE_YAML_COPY`
- `L5_SWAGGER_OPERATIONS_SORT`
- `L5_SWAGGER_UI_ASSETS_PATH`
- `L5_SWAGGER_UI_DOC_EXPANSION`
- `L5_SWAGGER_UI_FILTERS`
- `L5_SWAGGER_UI_PERSIST_AUTHORIZATION`
- `L5_SWAGGER_USE_ABSOLUTE_PATH`
- `LOG_CHANNEL`
- `LOG_DAILY_DAYS`
- `LOG_DEPRECATIONS_CHANNEL`
- `LOG_DEPRECATIONS_TRACE`
- `LOG_LEVEL`
- `LOG_PAPERTRAIL_HANDLER`
- `LOG_SLACK_EMOJI`
- `LOG_SLACK_USERNAME`
- `LOG_SLACK_WEBHOOK_URL`
- `LOG_STACK`
- `LOG_STDERR_FORMATTER`
- `LOG_SYSLOG_FACILITY`
- `MAILGUN_DOMAIN`
- `MAILGUN_ENDPOINT`
- `MAILGUN_SECRET`
- `MAIL_EHLO_DOMAIN`
- `MAIL_ENCRYPTION`
- `MAIL_FROM_ADDRESS`
- `MAIL_FROM_NAME`
- `MAIL_HOST`
- `MAIL_LOG_CHANNEL`
- `MAIL_MAILER`
- `MAIL_PASSWORD`
- `MAIL_PORT`
- `MAIL_SCHEME`
- `MAIL_SENDMAIL_PATH`
- `MAIL_URL`
- `MAIL_USERNAME`
- `MEMCACHED_HOST`
- `MEMCACHED_PASSWORD`
- `MEMCACHED_PERSISTENT_ID`
- `MEMCACHED_PORT`
- `MEMCACHED_USERNAME`
- `MYSQL_ATTR_SSL_CA`
- `PAPERTRAIL_PORT`
- `PAPERTRAIL_URL`
- `PERMISSION_CACHE_STORE`
- `POSTMARK_API_KEY`
- `POSTMARK_MESSAGE_STREAM_ID`
- `POSTMARK_TOKEN`
- `PUSHER_APP_CLUSTER`
- `PUSHER_APP_ID`
- `PUSHER_APP_KEY`
- `PUSHER_APP_SECRET`
- `QUEUE_CONNECTION`
- `QUEUE_FAILED_DRIVER`
- `REDIS_BACKOFF_ALGORITHM`
- `REDIS_BACKOFF_BASE`
- `REDIS_BACKOFF_CAP`
- `REDIS_CACHE_CONNECTION`
- `REDIS_CACHE_DB`
- `REDIS_CACHE_LOCK_CONNECTION`
- `REDIS_CLIENT`
- `REDIS_CLUSTER`
- `REDIS_DB`
- `REDIS_HOST`
- `REDIS_MAX_RETRIES`
- `REDIS_PASSWORD`
- `REDIS_PERSISTENT`
- `REDIS_PORT`
- `REDIS_PREFIX`
- `REDIS_QUEUE`
- `REDIS_QUEUE_CONNECTION`
- `REDIS_QUEUE_RETRY_AFTER`
- `REDIS_URL`
- `REDIS_USERNAME`
- `RESEND_API_KEY`
- `SANCTUM_STATEFUL_DOMAINS`
- `SESSION_CONNECTION`
- `SESSION_COOKIE`
- `SESSION_DOMAIN`
- `SESSION_DRIVER`
- `SESSION_ENCRYPT`
- `SESSION_HTTP_ONLY`
- `SESSION_PARTITIONED_COOKIE`
- `SESSION_PATH`
- `SESSION_SAME_SITE`
- `SESSION_SECURE_COOKIE`
- `SESSION_STORE`
- `SESSION_TABLE`
- `SLACK_BOT_USER_DEFAULT_CHANNEL`
- `SLACK_BOT_USER_OAUTH_TOKEN`
- `SQS_PREFIX`
- `SQS_QUEUE`
- `SQS_SUFFIX`
- `VIEW_COMPILED_PATH`




-----



# Secrets Rotation Runbook

This runbook covers operational rotation for platform-level API keys and secrets used by the backend API, backend-admin surface (`/admin`), and website integrations.

## Triggers

* Scheduled quarterly rotation.
* Credential leak suspicion or confirmed exposure.
* Vendor-directed credential rollover.
* Personnel offboarding impacting shared secret access.

## Rotation workflow

1. **Prepare**
   * Open an incident/change ticket and assign an owner + approver.
   * Identify all dependent services and environment scopes (`dev`, `staging`, `prod`).
   * Confirm rollback window and communication channel.
2. **Generate replacement credentials**
   * Create new API key/secret pair from provider console.
   * Prefer overlap mode (old and new valid concurrently) where provider allows.
3. **Store and distribute securely**
   * Save replacement values in the secret manager (not in git).
   * Update deployment references for each environment.
4. **Deploy incrementally**
   * Roll out to `dev`, then `staging`, then `prod`.
   * Restart PHP-FPM/queue workers/Horizon after env refresh.
5. **Validate**
   * Run health checks: `/api/health/ready` and `php artisan platform:health:synthetic`.
   * Confirm queue processing and integration logs show no auth failures.
6. **Deactivate old credential**
   * Revoke old key/secret after production verification.
7. **Audit evidence**
   * Capture ticket ID, rotated providers, affected envs, and completion time.

## Minimum validation checklist

* No `401`/`403` spikes in outbound integration logs.
* No failed jobs caused by auth/signature errors.
* Stripe/FCM/SMTP dependent flows continue to pass health checks.
* Platform setting `incident.degraded_mode` remains disabled unless an incident is active.

## Rollback

* Re-enable previous key in provider console (if still available).
* Revert secret manager references.
* Redeploy and restart workers.
* Mark rotation as failed and keep incident mode active until stabilization.
