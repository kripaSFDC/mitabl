# Migration Notes

## Pre-registration migrations

This repository intentionally retains historical pre-registration migrations:

- `2026_02_28_000009_create_pre_registrations_table.php`
- `2026_02_28_000018_add_pre_registration_contact_preferences.php`
- `2026_03_01_000021_retire_pre_registrations.php`

Governance decision: **retain full migration history** for auditability and deterministic replay of historical schema evolution.

Current product status: pre-registration intake is active and backed by the `pre_registrations` table (Module 7 in `mitabl_enhancement_plan.md`). The `2026_03_01_000021_retire_pre_registrations.php` migration is intentionally a no-op to preserve ordering while keeping the feature enabled.
