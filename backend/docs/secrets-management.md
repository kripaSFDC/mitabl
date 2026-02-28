# API Key, Secret Rotation, and Environment Inventory Runbook

This document is the authoritative Platform Admin + Security Admin reference for secret rotation and **all environment variables referenced in the codebase**.

## Secret Rotation Runbook

### Rotation Policy
- Critical secrets: rotate every 90 days.
- High-risk integrations (payments/auth): rotate every 60 days.
- Emergency compromise: immediate revoke + replace.

### Standard Procedure
1. Prepare change ticket + approver.
2. Generate replacement secret.
3. Deploy safely (staging then production).
4. Validate health checks and key flows (ticket intake, mail, queue, storage).
5. Cut over and revoke prior secret.
6. Record audit evidence.

### Emergency Procedure
1. Enable incident degraded mode if needed.
2. Revoke compromised secret.
3. Redeploy replacement and verify integrations.
4. Bulk-retry failed jobs where safe.
5. Record incident/postmortem references.

## Environment Variable Inventory

> Coverage rule: every `env(...)` variable discovered under `backend/**/*.php` is listed below with default and runtime function.

### Admin Portal

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `ADMIN_BRAND_LOGO_URL` | `—` | Filament admin panel path/branding and default admin bootstrap credentials. Example source: `app/Providers/Filament/AdminPanelProvider.php`. |
| `ADMIN_DEFAULT_EMAIL` | `''` | Filament admin panel path/branding and default admin bootstrap credentials. Example source: `database/seeders/AdminUserSeeder.php`. |
| `ADMIN_DEFAULT_NAME` | `'Platform Admin'` | Filament admin panel path/branding and default admin bootstrap credentials. Example source: `database/seeders/AdminUserSeeder.php`. |
| `ADMIN_DEFAULT_PASSWORD` | `''` | Filament admin panel path/branding and default admin bootstrap credentials. Example source: `database/seeders/AdminUserSeeder.php`. |
| `ADMIN_PANEL_PATH` | `'admin'` | Filament admin panel path/branding and default admin bootstrap credentials. Example source: `app/Providers/Filament/AdminPanelProvider.php`. |
| `AUTH_GUARD` | `'web'` | Authentication guard/model/password broker and permission cache behavior. Example source: `myproject/config/auth.php`. |
| `AUTH_MODEL` | `App\Models\User::class` | Authentication guard/model/password broker and permission cache behavior. Example source: `myproject/config/auth.php`. |
| `AUTH_PASSWORD_BROKER` | `'users'` | Authentication guard/model/password broker and permission cache behavior. Example source: `myproject/config/auth.php`. |
| `AUTH_PASSWORD_RESET_TOKEN_TABLE` | `'password_reset_tokens'` | Authentication guard/model/password broker and permission cache behavior. Example source: `myproject/config/auth.php`. |
| `AUTH_PASSWORD_TIMEOUT` | `10800` | Authentication guard/model/password broker and permission cache behavior. Example source: `myproject/config/auth.php`. |
| `PERMISSION_CACHE_STORE` | `—` | Authentication guard/model/password broker and permission cache behavior. Example source: `config/permission.php`. |

### Application Core

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `APP_DEBUG` | `false` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `config/app.php, myproject/config/app.php`. |
| `APP_ENV` | `'production'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `config/app.php, myproject/config/app.php`. |
| `APP_FAKER_LOCALE` | `'en_US'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_FALLBACK_LOCALE` | `'en'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_KEY` | `—` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `config/app.php, myproject/config/app.php`. |
| `APP_LOCALE` | `'en'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_MAINTENANCE_DRIVER` | `'file'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_MAINTENANCE_STORE` | `'database'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_NAME` | `'Laravel'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `app/Listeners/LogNotification.php, config/app.php`. |
| `APP_PREVIOUS_KEYS` | `''` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `myproject/config/app.php`. |
| `APP_SERVICE` | `'backend-api'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `app/Providers/AppServiceProvider.php`. |
| `APP_URL` | `'http://localhost'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `app/Mail/ResetPassword.php, app/Notifications/MailResetPasswordNotification.php`. |
| `ASSET_URL` | `null` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `config/app.php`. |
| `VIEW_COMPILED_PATH` | `realpath(storage_path('framework/views'` | Core app identity, runtime mode, URL, localization, or framework runtime behavior. Example source: `config/view.php`. |

### Database & Storage

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/cache.php, config/filesystems.php`. |
| `AWS_BUCKET` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/filesystems.php, myproject/config/filesystems.php`. |
| `AWS_DEFAULT_REGION` | `'us-east-1'` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/cache.php, config/filesystems.php`. |
| `AWS_ENDPOINT` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/filesystems.php, myproject/config/filesystems.php`. |
| `AWS_SECRET_ACCESS_KEY` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/cache.php, config/filesystems.php`. |
| `AWS_URL` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/filesystems.php, myproject/config/filesystems.php`. |
| `AWS_USE_PATH_STYLE_ENDPOINT` | `false` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/filesystems.php, myproject/config/filesystems.php`. |
| `DATABASE_URL` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php`. |
| `DB_CACHE_CONNECTION` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/cache.php`. |
| `DB_CACHE_LOCK_CONNECTION` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/cache.php`. |
| `DB_CACHE_LOCK_TABLE` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/cache.php`. |
| `DB_CACHE_TABLE` | `'cache'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/cache.php`. |
| `DB_CHARSET` | `'utf8mb4'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_COLLATION` | `'utf8mb4_unicode_ci'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_CONNECTION` | `'mysql'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, config/queue.php`. |
| `DB_DATABASE` | `database_path('database.sqlite'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_ENCRYPT` | `'yes'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_FOREIGN_KEYS` | `true` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_HOST` | `'127.0.0.1'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_PASSWORD` | `''` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_PORT` | `'3306'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_QUEUE` | `'default'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/queue.php`. |
| `DB_QUEUE_CONNECTION` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/queue.php`. |
| `DB_QUEUE_RETRY_AFTER` | `90` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/queue.php`. |
| `DB_QUEUE_TABLE` | `'jobs'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/queue.php`. |
| `DB_SOCKET` | `''` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DB_SSLMODE` | `'prefer'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_TRUST_SERVER_CERTIFICATE` | `'false'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_URL` | `—` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `myproject/config/database.php`. |
| `DB_USERNAME` | `'forge'` | Primary relational database connectivity, SSL/trust options, or DB queue/cache tables. Example source: `config/database.php, myproject/config/database.php`. |
| `DYNAMODB_CACHE_TABLE` | `'cache'` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/cache.php, myproject/config/cache.php`. |
| `DYNAMODB_ENDPOINT` | `—` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/cache.php, myproject/config/cache.php`. |
| `FILESYSTEM_DISK` | `'local'` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `myproject/config/filesystems.php`. |
| `FILESYSTEM_DRIVER` | `'local'` | Object storage/filesystem and DynamoDB cache backing configuration. Example source: `config/filesystems.php`. |

### Cache / Queue / Redis

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `BEANSTALKD_QUEUE` | `'default'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/queue.php`. |
| `BEANSTALKD_QUEUE_HOST` | `'localhost'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/queue.php`. |
| `BEANSTALKD_QUEUE_RETRY_AFTER` | `90` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/queue.php`. |
| `CACHE_DRIVER` | `env('APP_ENV'` | Cache backend driver/store selection and cache namespacing/prefix behavior. Example source: `config/cache.php, tests/Feature/HardeningRegressionTest.php`. |
| `CACHE_PREFIX` | `Str::slug(env('APP_NAME', 'laravel'` | Cache backend driver/store selection and cache namespacing/prefix behavior. Example source: `config/cache.php, myproject/config/cache.php`. |
| `CACHE_STORE` | `'database'` | Cache backend driver/store selection and cache namespacing/prefix behavior. Example source: `myproject/config/cache.php`. |
| `HORIZON_DOMAIN` | `—` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/horizon.php`. |
| `HORIZON_PATH` | `'horizon'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/horizon.php`. |
| `HORIZON_PREFIX` | `'mitabl_horizon:'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/horizon.php`. |
| `QUEUE_CONNECTION` | `env('APP_ENV'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |
| `QUEUE_FAILED_DRIVER` | `'database-uuids'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |
| `REDIS_BACKOFF_ALGORITHM` | `'decorrelated_jitter'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `REDIS_BACKOFF_BASE` | `100` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `REDIS_BACKOFF_CAP` | `1000` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `REDIS_CACHE_CONNECTION` | `'cache'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/cache.php`. |
| `REDIS_CACHE_DB` | `'1'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_CACHE_LOCK_CONNECTION` | `'default'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/cache.php`. |
| `REDIS_CLIENT` | `'phpredis'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_CLUSTER` | `'redis'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_DB` | `'0'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_HOST` | `'127.0.0.1'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_MAX_RETRIES` | `3` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `REDIS_PASSWORD` | `null` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_PERSISTENT` | `false` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `REDIS_PORT` | `'6379'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_PREFIX` | `Str::slug(env('APP_NAME', 'laravel'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_QUEUE` | `'default'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |
| `REDIS_QUEUE_CONNECTION` | `'default'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/queue.php`. |
| `REDIS_QUEUE_RETRY_AFTER` | `90` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/queue.php`. |
| `REDIS_URL` | `—` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/database.php, myproject/config/database.php`. |
| `REDIS_USERNAME` | `—` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `myproject/config/database.php`. |
| `SQS_PREFIX` | `'https://sqs.us-east-1.amazonaws.com/your-account-id'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |
| `SQS_QUEUE` | `'default'` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |
| `SQS_SUFFIX` | `—` | Queue transport, retries/backoff, Redis topology, and Horizon monitoring runtime behavior. Example source: `config/queue.php, myproject/config/queue.php`. |

### Session / Security

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `BCRYPT_ROUNDS` | `10` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/hashing.php`. |
| `SANCTUM_STATEFUL_DOMAINS` | `sprintf(         '%s%s',         'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',         env('APP_URL'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/sanctum.php`. |
| `SESSION_CONNECTION` | `null` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_COOKIE` | `Str::slug(env('APP_NAME', 'laravel'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_DOMAIN` | `null` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_DRIVER` | `'file'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_ENCRYPT` | `false` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_EXPIRE_ON_CLOSE` | `false` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_HTTP_ONLY` | `true` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_LIFETIME` | `120` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_PARTITIONED_COOKIE` | `false` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_PATH` | `'/'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_SAME_SITE` | `'lax'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |
| `SESSION_SECURE_COOKIE` | `—` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_STORE` | `null` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `config/session.php, myproject/config/session.php`. |
| `SESSION_TABLE` | `'sessions'` | Session lifecycle/cookie hardening, Sanctum stateful domains, and password hashing cost. Example source: `myproject/config/session.php`. |

### Authentication Tokens

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `JWT_ALGO` | `'HS256'` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_BLACKLIST_ENABLED` | `true` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_BLACKLIST_GRACE_PERIOD` | `0` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_LEEWAY` | `0` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_PASSPHRASE` | `—` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_PRIVATE_KEY` | `—` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_PUBLIC_KEY` | `—` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_REFRESH_TTL` | `20160` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_SECRET` | `—` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |
| `JWT_TTL` | `60` | JWT token signing algorithm/keys, TTL, refresh, blacklist, and leeway behavior. Example source: `config/jwt.php`. |

### Mail / Notifications / Broadcasting

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `ABLY_KEY` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `BROADCAST_DRIVER` | `'null'` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `MAILGUN_DOMAIN` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/services.php`. |
| `MAILGUN_ENDPOINT` | `'api.mailgun.net'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/services.php`. |
| `MAILGUN_SECRET` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/services.php`. |
| `MAIL_EHLO_DOMAIN` | `parse_url((string` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/mail.php`. |
| `MAIL_ENCRYPTION` | `'tls'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php`. |
| `MAIL_FROM_ADDRESS` | `'noreply@mitabl.com'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_FROM_NAME` | `'Example'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_HOST` | `'smtp.mailgun.org'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_LOG_CHANNEL` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_MAILER` | `'smtp'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_PASSWORD` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_PORT` | `587` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_SCHEME` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/mail.php`. |
| `MAIL_SENDMAIL_PATH` | `'/usr/sbin/sendmail -t -i'` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `MAIL_URL` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/mail.php`. |
| `MAIL_USERNAME` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/mail.php, myproject/config/mail.php`. |
| `PAPERTRAIL_PORT` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/logging.php, myproject/config/logging.php`. |
| `PAPERTRAIL_URL` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/logging.php, myproject/config/logging.php`. |
| `POSTMARK_API_KEY` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/services.php`. |
| `POSTMARK_MESSAGE_STREAM_ID` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/mail.php`. |
| `POSTMARK_TOKEN` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `config/services.php`. |
| `PUSHER_APP_CLUSTER` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `PUSHER_APP_ID` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `PUSHER_APP_KEY` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `PUSHER_APP_SECRET` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `config/broadcasting.php`. |
| `RESEND_API_KEY` | `—` | Outbound email provider credentials/transport and sender identity configuration. Example source: `myproject/config/services.php`. |
| `SLACK_BOT_USER_DEFAULT_CHANNEL` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `myproject/config/services.php`. |
| `SLACK_BOT_USER_OAUTH_TOKEN` | `—` | Realtime/event broadcasting and external log/alert transport endpoints. Example source: `myproject/config/services.php`. |

### Payments / Integrations

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `FCM_SERVER_KEY` | `''` | Mobile push, geocoding/maps, and bot-protection integration credentials. Example source: `app/Http/Controllers/Api/FcmController.php, app/Services/SystemHealthService.php`. |
| `GOOGLE_MAPS_API_KEY` | `—` | Mobile push, geocoding/maps, and bot-protection integration credentials. Example source: `config/services.php`. |
| `RECAPTCHA_SECRET` | `—` | Mobile push, geocoding/maps, and bot-protection integration credentials. Example source: `config/services.php`. |
| `RECAPTCHA_SITE_KEY` | `—` | Mobile push, geocoding/maps, and bot-protection integration credentials. Example source: `config/services.php`. |
| `STRIPE_CLIENT_ID` | `null` | Stripe API keys/OAuth/redirect/dashboard links for payments and onboarding. Example source: `config/stripe.php`. |
| `STRIPE_DASHBOARD_BASE_URL` | `'https://dashboard.stripe.com/payments'` | Stripe API keys/OAuth/redirect/dashboard links for payments and onboarding. Example source: `config/services.php`. |
| `STRIPE_PUBLISHABLE_KEY` | `null` | Stripe API keys/OAuth/redirect/dashboard links for payments and onboarding. Example source: `config/stripe.php`. |
| `STRIPE_REDIRECT_URI` | `null` | Stripe API keys/OAuth/redirect/dashboard links for payments and onboarding. Example source: `config/stripe.php`. |
| `STRIPE_SECRET_KEY` | `null` | Stripe API keys/OAuth/redirect/dashboard links for payments and onboarding. Example source: `config/stripe.php`. |

### Support & Operations

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `SUPPORT_ATTACHMENT_ALLOWED_MIME_TYPES` | `'image/jpeg,image/png,application/pdf,text/plain'` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ATTACHMENT_BLOCKED_EXTENSIONS` | `'exe,bat,cmd,com,scr,ps1,php,phar,phtml,js,vbs,jar,msi'` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ATTACHMENT_MAX_FILES` | `5` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ATTACHMENT_MAX_SIZE_KB` | `5120` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_DUPLICATE_WINDOW_MINUTES` | `10` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_HONEYPOT_FIELD` | `'website'` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_MOBCONTACT_ALIAS_REPLACEMENT_PATH` | `'/api/support/ticket'` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_MOBCONTACT_ALIAS_SUNSET` | `'2026-12-31'` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_PII_REDACTION_ENABLED` | `true` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_REOPEN_WINDOW_HOURS` | `72` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_ACCOUNT_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_DEFAULT_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_GENERAL_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_HIGH_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_ORDER_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_OTHER_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_PAYMENT_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_ROUTING_URGENT_ASSIGNEE_ID` | `—` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_FIRST_RESPONSE_MINUTES` | `60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_HIGH_FIRST_RESPONSE_MINUTES` | `30` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_HIGH_RESOLUTION_MINUTES` | `8 * 60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_LOW_FIRST_RESPONSE_MINUTES` | `120` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_LOW_RESOLUTION_MINUTES` | `48 * 60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_NORMAL_FIRST_RESPONSE_MINUTES` | `60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_NORMAL_RESOLUTION_MINUTES` | `24 * 60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_RESOLUTION_MINUTES` | `24 * 60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_URGENT_FIRST_RESPONSE_MINUTES` | `15` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |
| `SUPPORT_SLA_URGENT_RESOLUTION_MINUTES` | `4 * 60` | Support/ticketing SLA windows, intake controls, routing, attachment, and privacy policies. Example source: `config/support.php`. |

### Observability & Swagger

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `L5_FORMAT_TO_USE_FOR_DOCS` | `'json'` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_BASE_PATH` | `null` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_CONST_HOST` | `'http://my-default-host.com'` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_GENERATE_ALWAYS` | `false` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_GENERATE_YAML_COPY` | `false` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_OPERATIONS_SORT` | `null` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_UI_ASSETS_PATH` | `'vendor/swagger-api/swagger-ui/dist/'` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_UI_DOC_EXPANSION` | `'none'` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_UI_FILTERS` | `true` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_UI_PERSIST_AUTHORIZATION` | `false` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `L5_SWAGGER_USE_ABSOLUTE_PATH` | `true` | L5-Swagger documentation generation and UI exposure behavior. Example source: `config/l5-swagger.php`. |
| `LOG_CHANNEL` | `'stack'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `config/logging.php, myproject/config/logging.php`. |
| `LOG_DAILY_DAYS` | `14` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_DEPRECATIONS_CHANNEL` | `'null'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `config/logging.php, myproject/config/logging.php`. |
| `LOG_DEPRECATIONS_TRACE` | `false` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_LEVEL` | `'debug'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `config/logging.php, myproject/config/logging.php`. |
| `LOG_PAPERTRAIL_HANDLER` | `SyslogUdpHandler::class` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_SLACK_EMOJI` | `':boom:'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_SLACK_USERNAME` | `'Laravel Log'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_SLACK_WEBHOOK_URL` | `—` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `config/logging.php, myproject/config/logging.php`. |
| `LOG_STACK` | `'single'` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |
| `LOG_STDERR_FORMATTER` | `—` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `config/logging.php, myproject/config/logging.php`. |
| `LOG_SYSLOG_FACILITY` | `LOG_USER` | Application log channels, verbosity, retention, and external sink formatting settings. Example source: `myproject/config/logging.php`. |

### Other

| Variable | Default in code | Functionality / usage |
|---|---|---|
| `MEMCACHED_HOST` | `'127.0.0.1'` | Memcached host/auth/persistence settings for optional cache backend. Example source: `config/cache.php, myproject/config/cache.php`. |
| `MEMCACHED_PASSWORD` | `—` | Memcached host/auth/persistence settings for optional cache backend. Example source: `config/cache.php, myproject/config/cache.php`. |
| `MEMCACHED_PERSISTENT_ID` | `—` | Memcached host/auth/persistence settings for optional cache backend. Example source: `config/cache.php, myproject/config/cache.php`. |
| `MEMCACHED_PORT` | `11211` | Memcached host/auth/persistence settings for optional cache backend. Example source: `config/cache.php, myproject/config/cache.php`. |
| `MEMCACHED_USERNAME` | `—` | Memcached host/auth/persistence settings for optional cache backend. Example source: `config/cache.php, myproject/config/cache.php`. |
| `MYSQL_ATTR_SSL_CA` | `—` | Project/runtime environment variable used by framework or integration configuration. Example source: `config/database.php, myproject/config/database.php`. |
