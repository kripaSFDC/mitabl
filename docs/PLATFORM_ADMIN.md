# PLATFORM_ADMIN Guide

This document describes the current Mitabl admin panel as implemented in the codebase.

Admin panel base path:

- `/admin`

Primary navigation groups:

- `Customer Support`
- `Operations`
- `Platform`

## 1. Access model

Platform Admin runs on the `admin` guard and uses a separate admin login and password reset flow from end-user accounts.

Primary roles seen in the codebase:

- `super_admin`
- `platform_admin`
- `operations`
- `customer_service`
- `finance_readonly`

Primary permission domains used by the admin panel:

- `dashboard.view`
- `support_ticket.view`
- `support_tickets.*`
- `payments.*`
- `platform_settings.view`
- `platform_settings.edit`
- `queue_ops.view`
- `queue_ops.manage`
- `health.view`
- `integration_logs.view`
- `integration_logs.manage`
- `iam.manage`
- `audit_logs.view`
- `policy_changes.publish`

High-risk areas such as platform settings and policy publishing apply additional controls:

- role/permission checks
- current-password step-up verification
- change reason enforcement for risky changes
- two-person approval for high-risk setting changes
- audit logging

## 2. Dashboard

The default admin landing page is the Filament dashboard. It exposes the following widgets.

### 2.1 Operational Snapshot

Visible when user has:

- `dashboard.view`

Metrics shown:

- `Foodies`
- `Cooks`
- `Active kitchens`
- `Orders today`
- `Revenue this month`

### 2.2 Live Operations

Visible when user has:

- `dashboard.view`

Metrics shown:

- pending certificate approvals
- open support tickets
- SLA breach risk
- queue failed jobs
- queue latency snapshot

Polling:

- auto-refresh every `30s`

### 2.3 Integration Health

Visible when user has:

- `dashboard.view`

Dependency statuses shown:

- `Mail`
- `Storage`
- `FCM`
- `Stripe`

Polling:

- auto-refresh every `30s`

### 2.4 CRM Queue Stats

Visible when user has:

- `dashboard.view`

Metrics shown:

- queue depth
- first-response SLA breaches
- resolution SLA breaches
- reopened ticket rate for last 30 days

### 2.5 Support Ticket Aging Buckets

Visible when user has:

- `dashboard.view`

Chart buckets:

- `0-4h`
- `4-24h`
- `1-3d`
- `>3d`

### 2.6 SLA Health

Visible when user has:

- `dashboard.view`

Metrics shown:

- open active tickets
- first-response breached
- resolution breached
- SLA at risk in next `30m`

Polling:

- auto-refresh every `30s`

### 2.7 System Health Summary

Visible when user has:

- `health.view`

Metrics shown:

- healthy checks count
- overall health aggregation
- failed jobs count

Polling:

- auto-refresh every `30s`

### 2.8 Orders / Day

Visible when user has:

- `dashboard.view`

Chart window:

- last `30` days

### 2.9 Registrations / Day

Visible when user has:

- `dashboard.view`

Chart window:

- last `30` days

## 3. Custom admin pages

These are the non-resource operational pages currently registered in the admin panel.

## 3.1 CRM Agent Workspace

Navigation:

- `Customer Support -> CRM Agent Workspace`

Access:

- `support_ticket.view`

Purpose:

- ticket triage
- template-assisted replies
- related-ticket review

Data shown:

- queue of up to `50` active tickets
- selected ticket summary:
  - `id`
  - `ticket_number`
  - `subject`
  - `status`
  - `priority`
  - `category`
  - `requester_email`
  - `assignee`
  - `updated_at`
- ticket timeline:
  - sender
  - message
  - internal note flag
  - created timestamp
- recommended macros from active templates
- related tickets with similarity scoring and resolution summary

Operator inputs and actions:

- select a ticket
- choose `macroTemplateId`
- apply macro to reply draft
- edit `replyMessage`
- send reply
- refresh workspace

Template selection logic:

- only active templates are considered
- channel is filtered to `support`, `support_ticket`, or null
- top `5` recommended macros are shown

## 3.2 Platform Settings

Navigation:

- `Platform -> Platform Settings`

Access:

- view: `platform_settings.view` and role `super_admin` or `platform_admin`
- edit: `platform_settings.edit` and role `super_admin` or `platform_admin`

Purpose:

- runtime configuration without deployment
- integration credential management
- operational policy tuning

Editable fields on the page:

- repeater row `id`
- setting `key`
- setting `value_type`
- setting `description`
- one of:
  - `value_boolean`
  - `value_integer`
  - `value_string`
  - `value_json`
- `change_reason`
- `current_password`

Supported value types:

- `boolean`
- `integer`
- `string`
- `json`

What operators can do:

- create settings
- update settings
- delete settings by removing rows
- submit high-risk changes for approval
- approve validated high-risk requests
- activate approved high-risk requests
- review pending approvals

High-risk workflow behavior:

- duplicate keys are blocked
- keys are normalized and compared case-insensitively
- high-risk settings require `change_reason`
- high-risk settings require password step-up verification
- high-risk settings require `policy_changes.publish`
- requester cannot approve their own high-risk request
- high-risk changes follow `validated -> approved -> activated`

Settings that are restricted to `super_admin` for change, approval, and activation:

- all `otp.*`
- all `email.*`
- all `integrations.google_maps.*`
- all `stripe.*`
- all `payment.*`

Current platform-managed setting families available through this page:

- onboarding:
  - `onboarding.enabled`
  - `onboarding.require_identity_verification`
- maintenance and incident control:
  - `maintenance.read_only_mode`
  - `incident.degraded_mode`
- synthetic operations:
  - `operations.synthetic_checks_enabled`
- support duplicate detection:
  - `support.duplicate_window_minutes`
  - `support.duplicate_lock_ttl_seconds`
  - `support.duplicate_lock_wait_seconds`
- support lifecycle:
  - `support.reopen_window_hours`
  - `support.honeypot_field`
- support SLA policy:
  - `support.sla.default.first_response_minutes`
  - `support.sla.default.resolution_minutes`
  - `support.sla.low.first_response_minutes`
  - `support.sla.low.resolution_minutes`
  - `support.sla.normal.first_response_minutes`
  - `support.sla.normal.resolution_minutes`
  - `support.sla.high.first_response_minutes`
  - `support.sla.high.resolution_minutes`
  - `support.sla.urgent.first_response_minutes`
  - `support.sla.urgent.resolution_minutes`
- admin/session security:
  - `admin.security.reauth_minutes`
  - `session.lifetime_minutes`
  - `session.expire_on_close`
- OTP:
  - `otp.expire_minutes`
  - `otp.max_attempts`
  - `otp.lock_minutes`
  - `otp.mail_subject`
- Stripe:
  - `stripe.secret_key`
  - `stripe.publishable_key`
  - `stripe.client_id`
  - `stripe.redirect_uri`
  - `stripe.dashboard_base_url`
  - `stripe.webhook_signing_secret`
  - `stripe.currency`
  - `stripe.connected_account_country`
- integrations:
  - `integrations.google_maps.api_key`
  - `integrations.fcm.server_key`
- email:
  - `email.mailer`
  - `email.smtp.host`
  - `email.smtp.port`
  - `email.smtp.encryption`
  - `email.smtp.username`
  - `email.smtp.password`
  - `email.from.address`
  - `email.from.name`

Runtime mapping behavior:

- saved values are pushed into Laravel runtime config via `PlatformRuntimeConfigService`
- relative Stripe redirect URIs such as `/api/stripe/callback` are expanded using `APP_URL`

Recommended usage:

1. capture baseline in `System Health`
2. update the setting
3. approve and activate if high-risk
4. re-run health checks
5. test the affected business flow

## 3.3 System Health

Navigation:

- `Platform -> System Health`

Access:

- `health.view`

Purpose:

- current dependency and runtime posture

Page action:

- `refreshChecks()`

Summary fields returned by the health service:

- `overall`
- `failing_checks`
- `checks`

Checks currently executed:

- `database`
- `redis`
- `queue`
- `queue_processing`
- `mail`
- `ticket_intake`
- `storage`
- `fcm`
- `stripe`
- `scheduler`
- `degraded_mode`

Key conditions checked:

- database connectivity and latency
- Redis reachability
- queue connection validity
- failed jobs and backlog pressure
- SMTP/mailer configuration presence
- support ticket route and throttle presence
- storage read/write access
- FCM key presence
- Stripe secret/webhook/currency presence
- scheduler heartbeat freshness
- degraded-mode flag status

Recommended usage:

- before and after changing Platform Settings
- during incidents
- after queue or integration replays

## 3.4 Queue Operations

Navigation:

- `Platform -> Queue Operations`

Access:

- view: `queue_ops.view`
- manage actions: `queue_ops.manage`

Purpose:

- inspect queue backlog and failed jobs
- perform manual queue recovery actions

Page state and metrics shown:

- `failedJobs` list, latest `100`
- `queueMetrics`
- `canManageQueue`

Fields shown for each failed job:

- `id`
- `connection`
- `queue`
- `failed_at`
- `attempts`
- truncated `exception`

Queue metrics shown:

- `pending_jobs`
- `failed_jobs`
- `oldest_pending_age_minutes`
- `poison_jobs`
- `dead_letter_risk`

Page actions:

- refresh
- retry one job
- requeue one job
- discard one job
- retry all failed jobs

Implementation note:

- `retryJob` and `requeueJob` both call `queue:retry`
- discard uses `queue:forget`

Recommended usage:

- inspect exception type and attempts before replay
- avoid mass retry until upstream dependency is healthy
- review `dead_letter_risk` and `poison_jobs` before `retryAll`

## 3.5 Integration Logs

Navigation:

- `Platform -> Integration Logs`

Access:

- view: `integration_logs.view`
- replay failed items: `integration_logs.manage`

Purpose:

- inspect outbound communication/integration events
- manually replay supported failed CRM communications

Data shown:

- latest `200` logs

Fields shown per log:

- `id`
- `channel`
- `template`
- `recipient`
- `status`
- `response_status`
- `error_body`
- `retry_attempts`
- `created_at`

Page actions:

- refresh
- replay failed log

Replay support currently exists only for:

- `support_ticket_acknowledged`
- `support_ticket_reply`

Replay restrictions:

- only logs with status `failed` or `error`
- log must resolve to a support ticket
- unsupported templates are rejected

Recommended usage:

- inspect `template`, `status`, and `response_status` first
- replay only after the external provider issue is fixed
- confirm downstream ticket communication after replay

## 3.6 Security Admin

Navigation:

- `Platform -> Security Admin`

Access:

- `iam.manage`
- role `super_admin` or `platform_admin`

Purpose:

- admin access posture review
- dormant-account review
- session/security policy visibility

Sections shown:

- `sessionPolicy`
- `accessReview`
- `dormantAdmins`

Session policy values shown:

- `lifetime_minutes`
- `expire_on_close`
- `step_up_reauth_minutes`
- `dormant_threshold_days`

Access review values shown:

- `admins_total`
- `admins_active`
- `iam_manager_candidates`
- `dormant_active_admins`
- `defined_roles`
- `rotation_runbook`

Dormant admin list fields:

- `id`
- `name`
- `email`
- `last_login_at`

Notes:

- this page is visibility/reporting oriented
- it does not directly change users or roles
- admin/session policy values displayed here come from runtime config and Platform Settings

## 4. Resource surfaces

These are resource-based screens discovered by Filament. They are part of the admin panel even though they are not custom `Page` classes.

### 4.1 Customer Support group

Resources present:

- `Support Inbox`
- `Orders`
- `Mikitchn`
- `Micooks`
- `Mifoodies`
- `Certificates`
- `PreRegistrations`

### 4.2 Operations group

Resources present:

- `Platform Users`
- `Promo Codes`
- `Payments`

### 4.3 Platform group

Resources present:

- `Policies`
- `Templates`
- `Admin Action Logs`

Operational note:

- if the admin team wants this guide expanded further, the next level of detail would be a per-resource matrix of visible columns, filters, and actions for each CRUD page

## 5. Runtime configuration flow

Runtime settings apply in this sequence:

1. operator updates `Platform Settings`
2. high-risk changes may enter approval workflow
3. `PlatformRuntimeConfigService` maps platform keys to Laravel config paths
4. runtime-dependent features read those values from config

Examples of runtime mappings:

- `integrations.google_maps.api_key` -> `services.google_maps.api_key`
- `integrations.fcm.server_key` -> `services.fcm.server_key`
- `stripe.secret_key` -> `stripe.api_keys.secret_key`
- `stripe.publishable_key` -> `stripe.api_keys.publishable_key`
- `email.smtp.host` -> `mail.mailers.smtp.host`
- `otp.expire_minutes` -> `auth.otp.expire_minutes`

## 6. Recommended operating procedure

For settings, payments, or integration changes:

1. verify access level and change ownership
2. capture current posture in Dashboard and `System Health`
3. make the change in `Platform Settings`
4. complete approval/activation if required
5. validate the dependency from `System Health`
6. validate the actual business workflow
7. review `Integration Logs` or `Queue Operations` if the change affected async processing
8. confirm the audit trail exists in `Admin Action Logs`

## 7. Runbook references

- `docs/config_requirement.md`
- `docs/ENV_VARIABLES_SECRETS_ROTATION.md`
- synthetic health command: `php artisan platform:health:synthetic`
- policy activation scheduler command: `php artisan platform:policies:activate-due`
