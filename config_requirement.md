# Configuration Requirements

This project exposes integration/runtime configuration in **Platform Admin -> Platform Settings**.
For the keys in this document, changes are restricted to users with the `super_admin` role.

## 1) Map Integration (Google Maps)

Required to enable geocoding/location workflows:

- `integrations.google_maps.api_key`

Notes:

- Must be a valid Google Maps API key with geocoding access enabled.
- Runtime target: `services.google_maps.api_key`.

## 2) OTP Integration

Required to enable OTP verification flow:

- `otp.expire_minutes`
- `otp.max_attempts`
- `otp.lock_minutes`
- `otp.mail_subject`

Notes:

- OTP delivery currently uses email.
- Runtime targets:
  - `auth.otp.expire_minutes`
  - `auth.otp.max_attempts`
  - `auth.otp.lock_minutes`
  - `auth.otp.subject`

## 3) Stripe Integration

Required to enable payments and connected account operations:

- `stripe.secret_key`
- `stripe.publishable_key`
- `stripe.client_id`
- `stripe.redirect_uri`
- `stripe.currency`
- `stripe.connected_account_country`

Strongly recommended:

- `stripe.webhook_signing_secret`
- `stripe.dashboard_base_url`

Notes:

- Runtime targets:
  - `stripe.api_keys.secret_key`
  - `stripe.api_keys.publishable_key`
  - `stripe.client_id`
  - `stripe.redirect_uri`
  - `stripe.webhook_signing_secret`
  - `stripe.currency`
  - `stripe.connected_account_country`
  - `services.stripe.dashboard_base_url`

## 4) Email Integration (SMTP / Mailer)

Required for OTP and outbound transactional emails:

- `email.mailer` (typically `smtp`)
- `email.from.address`
- `email.from.name`

Required when `email.mailer = smtp`:

- `email.smtp.host`
- `email.smtp.port`
- `email.smtp.username`
- `email.smtp.password`
- `email.smtp.encryption` (`tls`, `ssl`, or empty)

Notes:

- Runtime targets:
  - `mail.default`
  - `mail.mailers.smtp.host`
  - `mail.mailers.smtp.port`
  - `mail.mailers.smtp.username`
  - `mail.mailers.smtp.password`
  - `mail.mailers.smtp.encryption`
  - `mail.from.address`
  - `mail.from.name`
