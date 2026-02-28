# API Key / Secret Rotation Runbook

## Scope
This runbook covers operational rotation for platform-level API keys and secrets used by the backend API, queue workers, Filament ops-admin, and website integrations.

## Triggers
- Scheduled quarterly rotation.
- Credential leak suspicion or confirmed exposure.
- Vendor-directed credential rollover.
- Personnel offboarding impacting shared secret access.

## Rotation workflow
1. **Prepare**
   - Open an incident/change ticket and assign an owner + approver.
   - Identify all dependent services and environment scopes (`dev`, `staging`, `prod`).
   - Confirm rollback window and communication channel.
2. **Generate replacement credentials**
   - Create new API key/secret pair from provider console.
   - Prefer overlap mode (old and new valid concurrently) where provider allows.
3. **Store and distribute securely**
   - Save replacement values in the secret manager (not in git).
   - Update deployment references for each environment.
4. **Deploy incrementally**
   - Roll out to `dev`, then `staging`, then `prod`.
   - Restart PHP-FPM/queue workers/Horizon after env refresh.
5. **Validate**
   - Run health checks: `/api/health/ready` and `php artisan platform:health:synthetic`.
   - Confirm queue processing and integration logs show no auth failures.
6. **Deactivate old credential**
   - Revoke old key/secret after production verification.
7. **Audit evidence**
   - Capture ticket ID, rotated providers, affected envs, and completion time.

## Minimum validation checklist
- No `401`/`403` spikes in outbound integration logs.
- No failed jobs caused by auth/signature errors.
- Stripe/FCM/SMTP dependent flows continue to pass health checks.
- Platform setting `incident.degraded_mode` remains disabled unless an incident is active.

## Rollback
- Re-enable previous key in provider console (if still available).
- Revert secret manager references.
- Redeploy and restart workers.
- Mark rotation as failed and keep incident mode active until stabilization.
