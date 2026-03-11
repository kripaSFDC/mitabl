# PLATFORM_ADMIN Guide

## 1. Purpose

The Mitabl Platform Admin is the operational control plane for runtime governance, health operations, queue management, policy lifecycle controls, compliance logging, and cross-domain admin workflows.

This guide is intended for:
- **Super Admins**
- **Platform Admins**
- **Operations Leads**
- **Security / Compliance / Audit stakeholders**

It documents capabilities available in the current codebase and explains how to safely operate the platform in production-like environments.

---

## 2. Access Model and Authorization

### 2.1 Guard and boundary model
- Platform Admin runs on the **admin guard**.
- Admin auth and password reset broker are isolated from end-user auth.
- Filament panel path is `/admin`.

### 2.2 Roles
Primary admin roles:
- `super_admin`
- `platform_admin`
- `operations`
- `customer_service`
- `finance_readonly`

### 2.3 Permission domains
Permissions are split by operational surface, including:
- Dashboard visibility (`dashboard.view`)
- Support operations (`support_tickets.*`)
- Payments controls (`payments.*`)
- Platform runtime settings (`platform_settings.*`)
- Queue operations (`queue_ops.*`)
- Health observability (`health.view`)
- Integration observability (`integration_logs.view`)
- IAM security administration (`iam.manage`)
- Audit access (`audit_logs.view`)

### 2.4 High-risk controls
For sensitive writes (for example platform settings and policy actions), the system applies explicit guardrails such as:
- current password verification for sensitive actions
- high-risk key detection
- mandatory change reason requirements for risky changes
- audit event generation for save / approval / activation events

---

## 3. Navigation Architecture

Platform Admin navigation is grouped into:
- **Operations**
- **Customer Support**
- **Platform**

Within these groups, users access resources (CRUD-style entities), pages (operational consoles), and dashboard widgets (live/statistical telemetry).

---

## 4. Core Platform Pages

## 4.1 Platform Settings Page
**Purpose:** runtime controls without code deployment.

### What it does
- Displays settings via a repeatable form grid.
- Supports value types:
  - `string`
  - `integer`
  - `boolean`
  - `json`
- Loads defaults from `PlatformSettingRegistry` and overlays persisted values.
- Captures change reason and approval workflow metadata.

### Approval and lifecycle behavior
- validates duplicates and key normalization
- computes retained/deleted keys based on persisted rows
- supports pending approvals and activation workflow
- emits audit logs for:
  - validate
  - save
  - approve
  - activate

### Runtime-sensitive keys managed here
This now includes integration credentials that were previously env-driven:
- `integrations.google_maps.api_key`
- `integrations.fcm.server_key`

These are mapped at runtime into config and can be changed without app container restart.

---

## 4.2 System Health Page
**Purpose:** at-a-glance runtime health and readiness.

### Checks include
- database connectivity
- queue configuration/processing checks
- mail configuration check
- support ticket intake route and throttle checks
- storage read/write probe
- FCM configuration check
- Stripe configuration check
- scheduler heartbeat checks
- degraded mode awareness

### Operational use
- use before/after sensitive config changes
- use during incidents to confirm dependency posture
- pair with synthetic health command (`platform:health:synthetic`)

---

## 4.3 Queue Ops Page
**Purpose:** operational queue intervention.

### Typical actions
- retry failed jobs
- requeue jobs
- inspect queue backlog/failure posture

### Recommended usage
- always capture reason for manual intervention
- perform queue actions in small batches for blast-radius control
- verify downstream integration health after replay/retry operations

---

## 4.4 Security Admin Page
**Purpose:** IAM-adjacent security governance tasks.

### Typical outputs
- dormant admin visibility
- active admin totals and role composition signals
- IAM manager candidate visibility

### Governance use-cases
- quarterly access reviews
- least-privilege validation
- dormant account deactivation campaigns

---

## 4.5 Integration Logs Page
**Purpose:** operational observability for integration events.

### Capabilities
- list latest integration events
- inspect template, recipient, status, response metadata
- manually replay selected failed support integration events

### Controls
- page visibility gated by `integration_logs.view`
- replay action further permission-gated
- all manual replay actions should be tracked in audit context

---

## 5. Resource Surfaces (Entity Management)

The Platform Admin includes resource-level management for core domains, including:
- Users
- Kitchens
- Certificates
- Orders
- Payments
- Promo Codes
- Support Tickets
- Policies
- Templates
- Admin Action Logs / Audit Logs

These resources provide operational CRUD/action workflows with role-specific guardrails and action-level permissions.

---

## 6. Dashboard and Operational Widgets

Dashboard widgets provide near-real-time and trend visibility. Current coverage includes:
- Operational snapshot counts
- Live operations status
- Integration health summary
- CRM queue stats
- CRM aging buckets chart
- SLA health
- System health summary
- Orders per day trend
- Registrations per day trend

Use dashboard snapshots for triage, then pivot into the relevant page/resource for action.

---

## 7. Runtime Configuration Flow (No-Restart Model)

## 7.1 How runtime settings apply
1. Admin updates setting in Platform Settings page.
2. Setting is saved/approved/activated per workflow.
3. `PlatformRuntimeConfigService` maps platform keys to Laravel config paths.
4. App boot applies runtime config from DB-backed settings.

## 7.2 Newly migrated integration credentials
The following values are now DB-managed through Platform Settings:
- `integrations.google_maps.api_key` -> `services.google_maps.api_key`
- `integrations.fcm.server_key` -> `services.fcm.server_key`

Google Maps runtime operations no longer depend on the `GOOGLE_MAPS_API_KEY` environment variable. The backend geocoding flow reads the key from Platform Settings via runtime config.

FCM runtime operations no longer depend on `FCM_SERVER_KEY`.

---

## 8. Recommended Change Management Process

When updating high-impact settings (payments, integrations, auth/session, maintenance):

1. **Plan**
   - define reason, risk, rollback
   - identify validation checks
2. **Pre-check**
   - open System Health page
   - capture baseline status
3. **Change**
   - update setting in Platform Settings
   - include clear change reason
4. **Approve/Activate**
   - complete approval steps where applicable
5. **Validate**
   - rerun health checks
   - test affected function paths (e.g. push delivery/geocoding/payments)
6. **Audit**
   - ensure audit trail is complete
   - attach incident/change ticket reference externally

---

## 9. Incident Response Playbook (Platform Admin-centric)

## 9.1 Integration outage
- Open Integration Logs page; identify failing template/channel/status trends.
- Validate health checks and external dependency status.
- Apply temporary mitigations in Platform Settings if needed.
- Replay failed events selectively after upstream restoration.

## 9.2 Queue degradation
- Open Queue Ops and System Health.
- Measure backlog and failed jobs.
- Retry/requeue safely in controlled batches.
- Confirm processing stabilization and integration success rates.

## 9.3 Security concern
- Open Security Admin for access posture checks.
- Review IAM manager accounts and dormant active admins.
- Apply access changes via governed IAM process.
- Preserve audit evidence.

---

## 10. Operational Hardening Checklist

- Keep only required permissions per role.
- Enforce password re-auth for sensitive operations.
- Require change reason for high-risk keys.
- Review audit logs regularly.
- Validate health before and after critical changes.
- Rotate integration secrets using controlled rollout.
- Prefer runtime settings over ad-hoc environment toggles for operational controls.

---

## 11. Data Governance and Audit Expectations

For enterprise governance, each sensitive platform change should have:
- who changed it
- what changed (key/value type + before/after where available)
- why it changed (change reason)
- when it changed
- who approved it (if approval flow involved)
- post-change validation evidence

Use Platform Admin audit events as the application-level source of truth, and pair them with external change tickets for compliance traceability.

---

## 12. Runbook References

- `docs/ENV_VARIABLES_SECRETS_ROTATION.md` – secret/env inventory and rotation guidance
- Platform synthetic health command: `php artisan platform:health:synthetic`
- Policy activation scheduler command: `php artisan platform:policies:activate-due`

---

## 13. Future Enhancements (Recommended)

- Role-specific approval matrix UI for high-risk settings.
- Built-in diff viewer for setting versions with rollback simulation.
- Stronger secret redaction/masking on integration keys in UI exports.
- Scheduled access review attestations with sign-off workflow.
- Integration replay safety policies (rate limiting / dry-run mode).

