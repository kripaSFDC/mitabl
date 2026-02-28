# API Key and Secret Rotation Runbook

This runbook is used by Platform Admin and Security Admin users for scheduled and emergency secret rotation.

## Scope
- Third-party API keys (Stripe, FCM, SMTP, CRM providers).
- Internal service credentials (queue/redis/database where applicable).
- Admin portal machine-to-machine tokens.

## Rotation Policy
- **Critical secrets**: rotate every 90 days.
- **High-risk integrations** (payments/auth): rotate every 60 days.
- **Emergency rotation**: immediate when compromise is suspected.

## Standard Rotation Procedure
1. **Prepare**
   - Open incident/change ticket and assign owner + approver.
   - Identify dependent services and rollback owner.
2. **Generate new secret**
   - Create new secret in provider console or vault.
   - Keep old secret active during overlap window.
3. **Deploy safely**
   - Update environment variable / secret manager entry.
   - Deploy to non-production first, then production.
4. **Validate**
   - Run platform health checks and integration dashboards.
   - Confirm key user flows: ticket intake, email dispatch, queue processing, storage IO.
5. **Cut over**
   - Disable old secret after successful verification.
6. **Audit**
   - Record change summary, approver, and activation time in admin audit logs.

## Emergency Compromise Workflow
1. Enable incident degraded mode if blast radius requires traffic reduction.
2. Revoke compromised secret immediately.
3. Issue replacement secret and redeploy.
4. Review integration errors and retry failed jobs in Queue Ops.
5. Publish incident update and postmortem link in incident setting annotation.

## Rollback
- If failures occur after cutover:
  - Re-enable previous secret (if still valid) during recovery window.
  - Revert config and redeploy.
  - Keep incident mode enabled until service health is restored.

## Evidence Checklist
- Ticket ID
- Before/after secret version reference (never raw secret)
- Approver identity
- Validation command outputs or dashboard screenshots
- Time old credential was revoked
