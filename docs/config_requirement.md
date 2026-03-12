# Production Configuration Requirements

This document is the production runbook for third-party and runtime configuration used by Mitabl.

The current model is:

- Infrastructure and core app env values are set in `deploy/environments/prod/backend-api.env`.
- Integration credentials and runtime business settings are managed in `Admin -> Platform -> Platform Settings`.
- Old direct env keys such as `GOOGLE_MAPS_API_KEY`, `STRIPE_SECRET_KEY`, and `MAIL_HOST` are not the primary production control plane for this project anymore when Platform Settings is available.

## 1. Access and location

Production operators configure these values from:

- Admin URL: `https://<your-domain>/admin`
- Page: `Platform -> Platform Settings`

Changes to payment, mail, and API credentials should be restricted to:

- `super_admin`
- `platform_admin`

Before changing any production setting:

1. Confirm `APP_URL` is correct in `deploy/environments/prod/backend-api.env`.
2. Open `Admin -> Platform -> System Health` and capture the current status.
3. Prepare the provider-side values first, then update Platform Settings.

## 2. Base production prerequisites

These are required outside Platform Settings and must exist before the integrations below will work correctly:

- `APP_URL`
  - File: `deploy/environments/prod/backend-api.env`
  - Purpose: used to build absolute callback URLs such as Stripe redirect callback when the stored value is `/api/stripe/callback`
- `APP_ENV=production`
- `APP_KEY`
- `JWT_SECRET`
- database and Redis connection values
- queue worker and scheduler running in production

If `APP_URL` is wrong, Stripe OAuth callbacks and admin links can be wrong even if the Platform Settings values are correct.

## 3. Required production settings

## 3.1 Email / SMTP

Purpose:

- OTP delivery
- transactional outbound email

Where to configure in Mitabl:

- `Admin -> Platform -> Platform Settings`

Required Platform Settings keys:

- `email.mailer`
- `email.from.address`
- `email.from.name`

Required when `email.mailer = smtp`:

- `email.smtp.host`
- `email.smtp.port`
- `email.smtp.username`
- `email.smtp.password`
- `email.smtp.encryption`

Typical provider source:

- your SMTP provider admin console
- examples: Microsoft 365 admin/mail settings, Google Workspace SMTP relay settings, SendGrid SMTP settings, Mailgun SMTP credentials, Postmark SMTP credentials

What to collect from the provider admin page:

1. SMTP host
2. SMTP port
3. SMTP username
4. SMTP password or app password
5. encryption type: `tls`, `ssl`, or none
6. approved sender email address
7. approved sender display name

Mitabl value mapping:

- provider SMTP host -> `email.smtp.host`
- provider SMTP port -> `email.smtp.port`
- provider username -> `email.smtp.username`
- provider password -> `email.smtp.password`
- provider TLS/SSL mode -> `email.smtp.encryption`
- sender mailbox -> `email.from.address`
- sender display name -> `email.from.name`
- chosen transport -> `email.mailer` = `smtp`

Recommended production values:

- `email.mailer = smtp`
- `email.smtp.port = 587` with `tls` unless your provider explicitly requires something else
- `email.from.address` should be a real domain mailbox such as `noreply@your-domain`

Validation after save:

1. Open `Admin -> Platform -> System Health`.
2. Confirm the `Mail` check is `ok`.
3. Test an OTP flow from the mobile app or API.
4. Confirm the sender address is accepted by the provider and messages are not rejected as unauthenticated.

## 3.2 Stripe

Purpose:

- payment processing
- Stripe Connect account linking
- webhook-driven payment state updates

Where to configure in Mitabl:

- `Admin -> Platform -> Platform Settings`

Required Platform Settings keys:

- `stripe.secret_key`
- `stripe.publishable_key`
- `stripe.client_id`
- `stripe.redirect_uri`
- `stripe.webhook_signing_secret`
- `stripe.currency`
- `stripe.connected_account_country`

Recommended Platform Settings key:

- `stripe.dashboard_base_url`

Stripe admin pages to use:

1. Stripe Dashboard -> Developers -> API keys
   - source for `stripe.secret_key`
   - source for `stripe.publishable_key`
2. Stripe Dashboard -> Connect settings / application settings
   - source for `stripe.client_id`
   - source for redirect URI registration
3. Stripe Dashboard -> Developers -> Webhooks
   - source for `stripe.webhook_signing_secret`
   - endpoint to register: `https://<your-domain>/api/stripe/webhook`

What to configure in Stripe first:

1. Create or select the production API keys.
2. Register the production OAuth redirect URL.
3. Create a webhook endpoint for `https://<your-domain>/api/stripe/webhook`.
4. Subscribe the endpoint to the events used by the app:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `charge.refunded`
5. Copy the webhook signing secret from Stripe.

Mitabl value mapping:

- Stripe secret key -> `stripe.secret_key`
- Stripe publishable key -> `stripe.publishable_key`
- Stripe Connect client ID -> `stripe.client_id`
- registered callback URL -> `stripe.redirect_uri`
- webhook signing secret -> `stripe.webhook_signing_secret`
- business settlement currency such as `usd` or `aud` -> `stripe.currency`
- connected account country such as `US` or `AU` -> `stripe.connected_account_country`
- Stripe dashboard payment base URL -> `stripe.dashboard_base_url`

Notes:

- `stripe.currency` must be a 3-letter lowercase ISO code.
- `stripe.connected_account_country` must be a 2-letter uppercase country code.
- If `stripe.redirect_uri` is stored as `/api/stripe/callback`, Mitabl prefixes it with `APP_URL` automatically. This only works if `APP_URL` is correct in production.
- Webhook processing will return `503` if `stripe.webhook_signing_secret` is empty.

Validation after save:

1. Open `Admin -> Platform -> System Health`.
2. Confirm the `Stripe` check is `ok`.
3. Verify the webhook endpoint exists in Stripe and is delivering successfully.
4. Test a payment in Stripe test mode outside production first, then validate the production account separately.
5. Test a Connect onboarding or callback flow if Connect is enabled for your deployment.

## 3.3 Google Maps API key

Purpose:

- geocoding
- address and location workflows

Where to configure in Mitabl:

- `Admin -> Platform -> Platform Settings`

Required Platform Settings key:

- `integrations.google_maps.api_key`

Google admin page to use:

- Google Cloud Console -> APIs & Services -> Credentials

What to configure in Google Cloud first:

1. Select the production Google Cloud project.
2. Enable the APIs required by your deployment, at minimum the geocoding-related API used by the app.
3. Create or select the production API key.
4. Apply API restrictions to the required Maps services.
5. Apply application restrictions where appropriate.

Mitabl value mapping:

- Google Maps API key -> `integrations.google_maps.api_key`

Validation after save:

1. Open `Admin -> Platform -> System Health`.
2. Run a location or address flow that uses geocoding.
3. Confirm there are no Google API authorization or quota errors.

## 3.4 OTP policy

Purpose:

- mobile authentication timing and lockout behavior

Where to configure in Mitabl:

- `Admin -> Platform -> Platform Settings`

Required Platform Settings keys:

- `otp.expire_minutes`
- `otp.max_attempts`
- `otp.lock_minutes`
- `otp.mail_subject`

Recommended production baseline:

- `otp.expire_minutes = 10`
- `otp.max_attempts = 5`
- `otp.lock_minutes = 15`

Validation after save:

1. Request an OTP.
2. Confirm the email subject matches `otp.mail_subject`.
3. Confirm expiry and lockout behavior match the configured values.

## 4. Current source of truth by setting

Use this table when the operator asks "where do I change this in production?"

| Setting | Change it in Mitabl | Source value comes from |
| --- | --- | --- |
| `email.mailer` | Platform Settings | internal decision |
| `email.smtp.host` | Platform Settings | SMTP provider admin page |
| `email.smtp.port` | Platform Settings | SMTP provider admin page |
| `email.smtp.username` | Platform Settings | SMTP provider admin page |
| `email.smtp.password` | Platform Settings | SMTP provider admin page |
| `email.smtp.encryption` | Platform Settings | SMTP provider admin page |
| `email.from.address` | Platform Settings | approved sender mailbox |
| `email.from.name` | Platform Settings | business sender name |
| `stripe.secret_key` | Platform Settings | Stripe Dashboard -> Developers -> API keys |
| `stripe.publishable_key` | Platform Settings | Stripe Dashboard -> Developers -> API keys |
| `stripe.client_id` | Platform Settings | Stripe Connect application settings |
| `stripe.redirect_uri` | Platform Settings | Stripe Connect application settings |
| `stripe.webhook_signing_secret` | Platform Settings | Stripe Dashboard -> Developers -> Webhooks |
| `stripe.currency` | Platform Settings | business/finance decision |
| `stripe.connected_account_country` | Platform Settings | business/legal onboarding country |
| `stripe.dashboard_base_url` | Platform Settings | Stripe dashboard URL pattern |
| `integrations.google_maps.api_key` | Platform Settings | Google Cloud Console -> APIs & Services -> Credentials |
| `otp.expire_minutes` | Platform Settings | internal security policy |
| `otp.max_attempts` | Platform Settings | internal security policy |
| `otp.lock_minutes` | Platform Settings | internal security policy |
| `otp.mail_subject` | Platform Settings | internal product/operations decision |
| `APP_URL` | `deploy/environments/prod/backend-api.env` | deployment environment |

## 5. Obsolete configuration guidance

Do not treat the following as the normal production update path for this project:

- editing Google Maps env keys directly on the server
- editing Stripe env keys directly on the server
- editing SMTP env keys directly on the server

Those values are runtime-managed through Platform Settings and mapped into application config at boot/runtime.

## 6. Production change procedure

Use this sequence for any payment, mail, or API key change:

1. Prepare the new value in the provider console first.
2. Confirm `APP_URL` and the production domain are correct.
3. Open `Admin -> Platform -> System Health` and capture baseline state.
4. Update the value in `Admin -> Platform -> Platform Settings`.
5. Save, approve, and activate the change if workflow approval is enabled.
6. Re-open `System Health` and confirm the affected check is healthy.
7. Test the exact user flow impacted by the change.
8. Record the change reason and provider-side reference in your change log.

## 7. Minimum production go-live checklist

Before go-live, confirm all of the following are configured:

- `APP_URL`
- SMTP settings and sender identity
- OTP settings
- Stripe API keys
- Stripe webhook endpoint and signing secret
- Stripe redirect URI
- Stripe currency and connected account country
- Google Maps API key
- queue worker and scheduler operational
- `Admin -> Platform -> System Health` shows healthy or only accepted warnings
