# Migration Notes

## Legacy pre-registration migrations

This repository intentionally retains historical pre-registration migrations:

- `2026_02_28_000009_create_pre_registrations_table.php`
- `2026_02_28_000018_add_pre_registration_contact_preferences.php`
- `2026_03_01_000021_retire_pre_registrations.php`

Governance decision: **retain full migration history** for auditability and deterministic replay of historical schema evolution.

Product status: pre-registration intake is **retired and unsupported**. The retirement migration drops pre-registration schema artifacts so they are not present in active runtime functionality for fresh environments.

Do not treat retained pre-registration migration files as active feature surface; current intake workflows are support-ticket based.
