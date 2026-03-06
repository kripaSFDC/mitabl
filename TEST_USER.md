# Test Users (Seeded Personas)

This file lists users created by `php artisan db:seed` via `DatabaseSeeder`.

## Admin Portal Login

- URL: `http://localhost:8000/admin/login`

## Seeded Persona Accounts

All seeded admin personas currently use this password in `local`/`testing`:

- Password: `password`

Accounts:

1. Platform Super Admin
   - Email: `super.admin@example.test`
   - Role: `super_admin`
2. Platform Admin
   - Email: `platform.admin@example.test`
   - Role: `platform_admin`
3. CRM Operations Admin
   - Email: `operations@example.test`
   - Role: `operations`
4. CRM Customer Service Admin
   - Email: `customer.service@example.test`
   - Role: `customer_service`
5. CRM Finance Readonly Admin
   - Email: `finance.readonly@example.test`
   - Role: `finance_readonly`
6. Default Platform Admin
   - Email: `admin@example.com`
   - Role: `super_admin`

## Notes

- These users are seeded only in `local` or `testing` environments.
- `AdminRbacTestUsersSeeder` does not overwrite existing users by default.
- There are currently no seeded end-user personas (for example foodie/cook mobile users) in `DatabaseSeeder`.

---

## **Production:**

Here’s the current admin user table with passwords you set during seeding:

| Email                         | Role             | Password            |
| ----------------------------- | ---------------- | ------------------- |
| admin@mitabl.com              | super_admin      | Str0ngAdminPass2026 |
| super.admin@example.test      | super_admin      | TestAdmin2026A1     |
| platform.admin@example.test   | platform_admin   | TestAdmin2026A1     |
| operations@example.test       | operations       | TestAdmin2026A1     |
| customer.service@example.test | customer_service | TestAdmin2026A1     |
| finance.readonly@example.test | finance_readonly | TestAdmin2026A1     |
