# mitabl Admin Panel — Plan, Design & Architecture

## What is Filament PHP?
Filament is a Laravel admin panel framework — think of it as the "missing backend UI" for any Laravel app. It installs into your existing Laravel project via Composer and builds a fully reactive web admin interface by reading your Eloquent models directly. There is no separate React/Vue app to build, no separate API layer, no separate hosting. It uses Livewire (PHP-driven reactive components) and Alpine.js, so the team writes PHP, not JavaScript.

For mitabl specifically: every feature Salesforce is currently doing — certificate review, user lookup, support tickets — maps directly to Filament's primitives (a Resource is a CRUD manager for one model, an Action is a button with a form modal, a Widget is a dashboard card). The entire admin panel shares the same MySQL database and the same User, Mikitchn, Certificate, Order models the mobile API already uses.

Filament is a **first-party Laravel admin panel and CRUD framework** built on top of [Livewire](https://livewire.laravel.com/) and [Alpine.js](https://alpinejs.dev/). It generates reactive, real-time admin UIs entirely in PHP — no separate JavaScript build step, no React or Vue app to maintain.

Key characteristics relevant to mitabl:

| Property | Detail |
|---|---|
| **Lives inside `backend/`** | Installed via Composer into the same Laravel app — same models, same DB, same queues. Zero new infrastructure. |
| **Eloquent-native** | Every existing model (`User`, `Mikitchn`, `Certificate`, `Order`, `Payment`, etc.) is used directly — no data duplication, no API layer between the admin UI and the database. |
| **Reactive without writing JS** | Forms, tables, filters, modals, and notifications all update in real time via Livewire WebSocket polling — without a React/Vue SPA. |
| **Role & permission aware** | First-class integration with `spatie/laravel-permission` for multi-role admin access (Super Admin, Operations, Customer Service). |
| **Ships a design system** | Tailwind-based UI with a configurable theme — mitabl colours can be applied in minutes. |
| **Extensible** | Custom pages, widgets, actions, and charts can be built as plain PHP classes in `app/Filament/`. |

**Why it fits mitabl specifically:** The entire feature set needed to replace Salesforce (certificate approvals, user management, order oversight, support tickets) maps 1:1 to Filament's built-in primitives — Resources, Actions, Infolists, and Widgets. The team already knows Laravel and PHP. There is no new language, no new hosting tier, no integration contract to maintain.

---

## Current State — What Salesforce Does (and What Dies With It)

| SF Capability | Current implementation | Status after this plan |
|---|---|---|
| Kitchen certificate approval | `PUT /api/kitchen/{id}/certificate` called from SF UI | Replaced by Filament `CertificateResource` with Approve/Reject action |
| User lookup (mifoodi details) | `GET /api/sales/mifoodi` called from SF | Replaced by Filament `UserResource` with search/filter |
| Pre-registration lead capture | `POST /api/preregister` → SF Lead | Replaced by local `pre_registrations` table + Filament resource |
| Contact/support case creation | `POST /api/mobcontact` → SF Case | Replaced by local `support_tickets` table + Filament resource |
| Kitchen profile sync (Account) | `KitchenVerifiedToSales` listener → SF Account | Listener removed; no CRM sync needed — data lives in own DB |
| SF Account CRM ID storage | `sales_kitchens` table | Table dropped after migration |
| SF OAuth token management | `WebApiToCurlController::getAccToken()` | Removed entirely |

---

## Architecture Overview

### Where the Admin Panel Lives

The admin panel is **not a separate application**. It is a route group mounted inside `backend/` at `/admin`:

```
backend/
├── app/
│   ├── Filament/                  ← all admin panel code lives here
│   │   ├── Resources/             ← one class per entity (CRUD)
│   │   ├── Pages/                 ← custom full-page views (Dashboard)
│   │   └── Widgets/               ← dashboard stat cards & charts
│   ├── Http/
│   │   └── Controllers/Api/       ← existing mobile API (unchanged)
│   └── Models/                    ← shared by both API and admin panel
├── database/
│   └── migrations/                ← new migrations added (see below)
└── routes/
    ├── api.php                    ← mobile API routes (unchanged)
    └── web.php                    ← admin panel mounts here via Filament
```

### Request Flow — Two Parallel Entry Points

```
Mobile App (Flutter)                   Admin Browser (Operations team / CS team)
      │                                              │
      │  JWT Bearer token                            │  Session cookie (email + password)
      ▼                                              ▼
routes/api.php                              routes/web.php (/admin/*)
      │                                              │
Laravel Middleware (JwtMiddleware)         Filament Auth middleware
      │                                              │
Http/Controllers/Api/*                     Filament Resources & Pages
      │                                              │
      └───────────────────┬──────────────────────────┘
                          │
                   Eloquent Models
                          │
                       MySQL DB
```

The two entry points share the same database and models. The admin panel does **not** call the mobile API — it reads and writes the database directly via Eloquent, which is faster and avoids self-calling architecture.

### Admin User Roles (New)

A separate admin role system is needed. The existing `roles` table controls mobile user roles (Foodie=3, Cook=2). Admin roles use `spatie/laravel-permission` as a separate permission layer:

| Admin Role | Capabilities |
|---|---|
| `super_admin` | Full access to all resources; create/manage admin accounts; system settings |
| `operations` | Certificate approvals; kitchen management; promo code management; view financials |
| `customer_service` | Support tickets; order dispute handling; user lookup; read-only on financials |

---

## Feature Modules

### Module 1 — Dashboard (Home)

**Purpose:** Real-time platform health at a glance on login.

**Widgets:**

| Widget | Data source | Refresh |
|---|---|---|
| Total registered users (Foodies / Cooks) | `users` table grouped by `role_id` | On load |
| Active kitchens | `mikitchns` WHERE `status=1` | On load |
| Pending certificate approvals | `certificates` WHERE `status=0` | Real-time (Livewire polling, 30s) |
| Open support tickets | `support_tickets` WHERE `status IN (open, in_progress)` | Real-time polling |
| Orders today | `orders` WHERE `delivery_date = today` | On load |
| Revenue this month | `payments` JOIN `orders` WHERE `confirm=1` | On load |
| Chart: Orders per day (last 30 days) | `orders` GROUP BY `delivery_date` | On load |
| Chart: New user registrations (last 30 days) | `users` GROUP BY `created_at` | On load |

---

### Module 2 — Kitchen Certificate Management (replaces SF approval flow)

This is the most critical piece currently owned by Salesforce.

**Resource:** `CertificateResource`

**Table columns:** Kitchen name, cook name, phone, ABN, certificate number, upload date, document (link to view/download), current status (badge: Pending / Approved / Rejected), action buttons.

**Filters:** Status (Pending / Approved / Rejected), date range of submission.

**Actions per row:**
- **Approve** — sets `certificates.status = 1`, fires `MikitchnObserver` which sends activation email + FCM push to cook. Requires confirmation modal.
- **Reject** — sets `certificates.status = 2` (new), opens a modal requiring a rejection reason text, sends a `CertificateRejected` email to the cook.
- **View Document** — opens the certificate file (PDF/image) in a slide-over panel without leaving the page.

**New certificate status values (migration needed):**

```
0 = Pending review
1 = Approved
2 = Rejected
```

(Currently only 0/1 exist — rejected certificates are not tracked. The new status adds a proper rejection state.)

**New fields needed on `certificates` table (migration):**

```php
$table->text('rejection_reason')->nullable();
$table->timestamp('reviewed_at')->nullable();
$table->integer('reviewed_by')->nullable(); // admin user ID
```

**Automatic email on rejection:**  New `CertificateRejected` Mailable class — sends the cook an email with the rejection reason and instructions to re-upload.

**Removes:** `SalesForceController::changecertificateStatus()`, the `salesforce` middleware-protected route, `SalesKitchen` model, `KitchenVerifiedToSales` listener, `KitchenVerified` event dispatch (for SF sync only — the event itself can be removed if no other listener needs it), `sales_kitchens` table.

---

### Module 3 — User Management

**Resource:** `UserResource`

**Table columns:** ID, full name, email, phone, role (Foodie / Cook / Both), email verified, account created date, total orders, account status, actions.

**Filters:** Role, verification status, date range, search by name/email/phone.

**Actions per row / record page:**
- View full profile (read-only infolist)
- Edit profile fields (admin override — for corrections)
- Suspend / Unsuspend account (sets a new `suspended` flag on `users`)
- Delete account (with confirmation modal and cascading soft-delete)
- View all orders for this user
- View kitchen profile (if cook)
- View support tickets raised by this user

**Replaces:** `SalesForceController::mifoodiDetails()` endpoint — the operations team no longer needs to call an API to look up a user.

**New field needed on `users` table (migration):**

```php
$table->boolean('suspended')->default(false);
$table->text('suspension_reason')->nullable();
$table->timestamp('suspended_at')->nullable();
```

---

### Module 4 — Kitchen Management

**Resource:** `MikitchnResource`

**Table columns:** ID, kitchen name, cook name, suburb/city, status (Active/Inactive/Pending), rating (avg), total orders, certificate status, dine-in, take-away, creation date.

**Filters:** Status, certificate status, suburb/city, dine-in/take-away.

**Actions per row / record page:**
- View full kitchen profile including all images (slide-over gallery)
- View full menu (list of food items with price and availability)
- View all orders
- View all reviews
- Activate / Deactivate kitchen (`mikitchns.status`)
- Edit kitchen details (admin override)

**Sub-panel on record page:** embedded `CertificateResource` infolist for the kitchen's certificate, including the Approve/Reject action — so the operations team can review and approve from the kitchen's own record page without navigating to a separate certificate list.

---

### Module 5 — Order Management

**Resource:** `OrderResource`

**Table columns:** Order ID (T-/D- prefix), kitchen name, customer name, order date, delivery date, order type (dine-in/takeaway), total, status (badge), paid flag, refund status.

**Order status values (existing):**

```
1 = Completed
2 = Requested (pending kitchen acceptance)
3 = Confirmed (kitchen accepted, payment authorised)
4 = Cancelled  ← need to confirm correct integer in code
```

**Filters:** Status, date range, kitchen, order type, paid/unpaid.

**Actions per row / record page:**
- View full order details (items, quantities, prices, promo code applied, taxes, GST)
- View associated payment record (Stripe payment intent ID, amount, confirmation timestamp)
- View cancel reason (if cancelled)
- Initiate full refund (calls existing `UserController::refundFullAmount()` via a service layer)
- Manually mark as completed (admin override for disputes)

---

### Module 6 — Support Ticket Management (replaces SF Cases)

This is a new module — no equivalent exists in the current codebase. Currently contact form messages go to Salesforce as `Case` objects. This replaces that with a native help-desk-style ticket system.

**New table: `support_tickets`**

```php
Schema::create('support_tickets', function (Blueprint $table) {
    $table->id();
    $table->string('ticket_number')->unique();   // auto-generated: TKT-000001
    $table->integer('user_id')->nullable();       // null for anonymous/pre-auth
    $table->string('requester_name');
    $table->string('requester_email');
    $table->string('requester_phone')->nullable();
    $table->string('subject');
    $table->text('description');
    $table->string('source');                     // 'mobile_app', 'website', 'admin'
    $table->string('category');                   // 'order_dispute', 'payment', 'account', 'general', 'other'
    $table->string('priority')->default('normal'); // 'low', 'normal', 'high', 'urgent'
    $table->string('status')->default('open');     // 'open', 'in_progress', 'pending_user', 'resolved', 'closed'
    $table->integer('assigned_to')->nullable();    // admin user ID
    $table->integer('order_id')->nullable();       // linked order if applicable
    $table->integer('mikitchn_id')->nullable();    // linked kitchen if applicable
    $table->timestamp('resolved_at')->nullable();
    $table->timestamps();
});
```

**New table: `support_ticket_messages`** (thread/replies)

```php
Schema::create('support_ticket_messages', function (Blueprint $table) {
    $table->id();
    $table->integer('ticket_id');
    $table->string('sender_type');    // 'user', 'admin'
    $table->integer('sender_id');
    $table->text('message');
    $table->string('attachment')->nullable();
    $table->timestamps();
});
```

**Resource:** `SupportTicketResource`

**Table columns:** Ticket number, requester, category, subject, priority (badge), status (badge), assigned agent, created date, last updated.

**Filters:** Status, priority, category, assigned agent, date range, source.

**Record page:**
- Full ticket thread view — admin types a reply, user receives it by email
- Assign ticket to an agent (dropdown of `customer_service` role admins)
- Change status, priority, category
- Link to associated order (opens order detail slide-over)
- Link to associated user profile
- Resolve / Close with resolution note

**API changes (mobile app):**

Current `POST /api/mobcontact` → SF Case is replaced with:

```
POST /api/support/ticket
Body: { subject, description, category, order_id (opt) }
Auth: optional JWT (anonymous allowed)
```

Creates a row in `support_tickets`, auto-generates ticket number, sends a confirmation email to the requester with their ticket number.

Existing `website/routes/web.php` contact form posts to `/api/mobcontact`. This route is replaced with a redirect to the new endpoint.

---

### Module 7 — Pre-Registration / Lead Management (replaces SF Leads)

**New table: `pre_registrations`**

```php
Schema::create('pre_registrations', function (Blueprint $table) {
    $table->id();
    $table->string('first_name');
    $table->string('last_name');
    $table->string('email')->nullable();
    $table->string('phone')->nullable();
    $table->string('city')->nullable();
    $table->string('interested_as');   // 'cook', 'foodie', 'both'
    $table->string('source');          // 'website', 'referral'
    $table->string('status')->default('new'); // 'new', 'contacted', 'converted', 'disqualified'
    $table->text('notes')->nullable();
    $table->integer('followed_up_by')->nullable();
    $table->timestamp('followed_up_at')->nullable();
    $table->timestamps();
});
```

**Resource:** `PreRegistrationResource`

**Table columns:** Name, email, phone, city, interested as, source, status, submitted date.

**Filters:** Status, interested-as, city, date range.

**Actions:** Mark as contacted (with note), mark as converted (optionally link to created user account), mark as disqualified.

**API changes:** `POST /api/preregister` inserts into `pre_registrations` instead of calling SF. Sends a welcome/acknowledgement email to the registrant.

---

### Module 8 — Promo Code Management

**Resource:** `PromoCodeResource` (reads existing `promo_codes` table)

**Table columns:** Code, discount type, discount value, expiry date, usage count, active.

**Actions:** Create new promo code, deactivate, view which orders used a code.

---

### Module 9 — Financial Overview (Read-Only)

**Resource:** `PaymentResource`

**Table columns:** Order ID, kitchen, customer, amount, payment intent ID, confirmed, confirmation date, refund status.

**Filters:** Confirmed/unconfirmed, date range, kitchen.

**Read-only actions:** View Stripe payment intent (external link to Stripe dashboard), view associated refund.

**Note:** No payment mutations happen in the admin panel — all actual Stripe mutations continue through the existing mobile API service layer. The admin panel gives visibility and the ability to trigger a full refund (calling the existing `refundFullAmount` controller method through a dedicated admin-only API endpoint).

---

## Database Migrations Required

| Migration | Purpose |
|---|---|
| `add_rejected_fields_to_certificates` | Add `rejection_reason`, `reviewed_at`, `reviewed_by`, update status enum to include `2` (rejected) |
| `add_suspended_to_users` | Add `suspended`, `suspension_reason`, `suspended_at` |
| `create_support_tickets` | New table (see schema above) |
| `create_support_ticket_messages` | New threaded messages table |
| `create_pre_registrations` | Replaces SF Lead — new local table |
| `drop_sales_kitchens` | Remove the SF Account ID mapping table (run after SF cutover) |
| `create_admin_users` | Filament uses session auth; create a separate `admin_users` table OR add an `is_admin` scope to the existing `users` table with a new role (`role_id=1` = admin, already in `roles` table — confirm value) |

> **Note on admin authentication:** Filament's default panel authenticates against an Eloquent model. The cleanest approach for mitabl is to create a separate `AdminUser` model backed by its own table, completely decoupled from the mobile app's `User` model. This prevents any risk of an admin-level session token being accepted by the mobile JWT middleware.

---

## New / Modified Code Components

### New Filament Resources

```
app/Filament/Resources/
├── CertificateResource.php        + Pages/ (List, View)
├── UserResource.php               + Pages/ (List, View, Edit)
├── MikitchnResource.php           + Pages/ (List, View, Edit)
├── OrderResource.php              + Pages/ (List, View)
├── SupportTicketResource.php      + Pages/ (List, View, Edit)
├── PreRegistrationResource.php    + Pages/ (List, View, Edit)
├── PaymentResource.php            + Pages/ (List, View)
└── PromoCodeResource.php          + Pages/ (List, Create, Edit)
```

### New Filament Widgets (Dashboard)

```
app/Filament/Widgets/
├── PlatformStatsOverview.php      # stat cards row
├── OrdersPerDayChart.php          # line chart
├── NewUsersChart.php              # bar chart
├── PendingCertificatesWidget.php  # alert widget
└── OpenTicketsWidget.php          # alert widget
```

### New Filament Pages

```
app/Filament/Pages/
└── Dashboard.php                  # custom dashboard (overrides default)
```

### New Models

```
app/Models/
├── AdminUser.php                  # Filament auth model
├── SupportTicket.php              # with hasMany SupportTicketMessages
├── SupportTicketMessage.php       # belongs to SupportTicket
└── PreRegistration.php
```

### New Mailables

```
app/Mail/
├── CertificateRejected.php        # cook email on cert rejection
├── SupportTicketConfirmation.php  # auto-reply to user when ticket opened
├── SupportTicketReply.php         # sends agent reply to user by email
└── PreRegistrationAcknowledgement.php
```

### New / Modified API Endpoints

| Method | Route | Change |
|---|---|---|
| `POST` | `/api/support/ticket` | **New** — creates support ticket (replaces `/api/mobcontact`) |
| `GET` | `/api/support/ticket/{id}` | **New** — user checks status of own ticket |
| `POST` | `/api/preregister` | **Modified** — writes to `pre_registrations` table instead of SF |
| `POST` | `/api/mobcontact` | **Removed** (or redirect alias to `/api/support/ticket`) |
| `PUT` | `/api/kitchen/{id}/certificate` | **Removed** (SF inbound — no longer needed) |
| `GET` | `/api/sales/mifoodi` | **Removed** (SF inbound — no longer needed) |

### Code to Delete (SF removal)

```
app/Events/KitchenVerified.php                    ← delete (if no other listener)
app/Listeners/KitchenVerifiedToSales.php          ← delete
app/Http/Controllers/Api/Sales/                   ← delete entire directory
app/Http/Middleware/SalesForce.php                ← delete
app/Models/SalesKitchen.php                       ← delete
app/Http/Controllers/Api/WebApiToCurlController.php ← remove getAccToken(), preRegister(), mobContact()
app/Providers/EventServiceProvider.php            ← remove KitchenVerified binding
app/Http/Kernel.php                               ← remove 'salesforce' middleware alias
routes/api.php                                    ← remove salesforce route group
```

### Env Variables to Remove

```
SALES_AUTH=
SF_CLIENT_ID=
SF_CLIENT_SECRET=
SF_USERNAME=
SF_PASSWORD=
```

---

## Implementation Tasks

### Phase 1 — Foundation (Week 1)

| # | Task | Notes |
|---|---|---|
| 1.1 | `composer require filament/filament:"^3.0"` in `backend/` | Installs Filament + Livewire |
| 1.2 | `php artisan filament:install --panels` | Scaffolds panel provider at `/admin` |
| 1.3 | Create `AdminUser` model + migration + seeder | Separate from mobile `User` model |
| 1.4 | Install `spatie/laravel-permission` and define `super_admin`, `operations`, `customer_service` roles | Role-gate all Filament resources |
| 1.5 | Configure Filament theme (mitabl brand colours, logo) | In `AdminPanelProvider.php` |
| 1.6 | Write and run migration: `add_rejected_fields_to_certificates` | Adds status=2, rejection_reason, reviewed_at, reviewed_by |
| 1.7 | Write and run migration: `add_suspended_to_users` | Adds suspended, suspension_reason, suspended_at |
| 1.8 | Write and run migration: `create_support_tickets` + `create_support_ticket_messages` | New CRM tables |
| 1.9 | Write and run migration: `create_pre_registrations` | Replaces SF Lead |

### Phase 2 — Core Admin Resources (Weeks 2–3)

| # | Task | Notes |
|---|---|---|
| 2.1 | Build `CertificateResource` with Approve / Reject actions | Core SF replacement |
| 2.2 | Build `CertificateRejected` Mailable + Blade template | Sent on rejection |
| 2.3 | Build `UserResource` with search, filter, suspend/unsuspend | Replaces SF mifoodi lookup |
| 2.4 | Build `MikitchnResource` with embedded certificate infolist | Approve/reject from kitchen record |
| 2.5 | Build `OrderResource` (read-only + admin refund action) | Visibility into order lifecycle |
| 2.6 | Build `PromoCodeResource` (full CRUD) | Self-service promo management |

### Phase 3 — CRM Modules (Weeks 3–4)

| # | Task | Notes |
|---|---|---|
| 3.1 | Build `SupportTicket` + `SupportTicketMessage` models with relationships | |
| 3.2 | Build `SupportTicketResource` with full thread view, assignment, status management | |
| 3.3 | Build `SupportTicketConfirmation` + `SupportTicketReply` Mailables | |
| 3.4 | Build new `POST /api/support/ticket` API endpoint | Replaces `/api/mobcontact` |
| 3.5 | Build `GET /api/support/ticket/{id}` for user-facing status check | |
| 3.6 | Build `PreRegistration` model + `PreRegistrationResource` | |
| 3.7 | Modify `POST /api/preregister` to write to `pre_registrations` table | Removes SF Lead call |
| 3.8 | Build `PreRegistrationAcknowledgement` Mailable | Auto-reply to registrant |

### Phase 4 — Dashboard & Analytics (Week 4)

| # | Task | Notes |
|---|---|---|
| 4.1 | Build `PlatformStatsOverview` widget | Stat cards |
| 4.2 | Build `OrdersPerDayChart` widget | Line chart |
| 4.3 | Build `NewUsersChart` widget | Bar chart |
| 4.4 | Build `PendingCertificatesWidget` (alert-style) | Real-time polling badge |
| 4.5 | Build `OpenTicketsWidget` (alert-style) | Real-time polling badge |
| 4.6 | Assemble custom `Dashboard` page | |

### Phase 5 — SF Cutover & Cleanup (Week 5)

| # | Task | Notes |
|---|---|---|
| 5.1 | Test all Filament approval flows in staging | Parity check vs current SF flow |
| 5.2 | Remove `SalesForce` middleware, routes, controller | |
| 5.3 | Remove `KitchenVerified` event + `KitchenVerifiedToSales` listener | |
| 5.4 | Remove `WebApiToCurlController` SF methods | Keep class only if other proxy methods remain |
| 5.5 | Remove `SalesKitchen` model | |
| 5.6 | Run `drop_sales_kitchens` migration | |
| 5.7 | Remove SF env variables | |
| 5.8 | Update `POST /api/mobcontact` to redirect/deprecate | |
| 5.9 | Update website contact form to call `/api/support/ticket` | |
| 5.10 | Update mobile app contact form to call `/api/support/ticket` | Flutter change in `repos/` |

### Phase 6 — Hardening (Week 6)

| # | Task | Notes |
|---|---|---|
| 6.1 | Add Redis queue driver (`QUEUE_CONNECTION=redis`) | So Filament email sends & notifications are async |
| 6.2 | Add rate limiting to `/api/support/ticket` (prevent spam) | Laravel throttle middleware |
| 6.3 | Write PHPUnit feature tests for certificate approval/rejection flow | |
| 6.4 | Write PHPUnit feature tests for support ticket creation + reply flow | |
| 6.5 | Audit all Filament resource policies (ensure CS can't approve certs, only ops can) | Filament `canAccess()` + Spatie policies |
| 6.6 | Set up Filament audit log (optional: `tightenco/auditable` or `owen-it/laravel-auditing`) | Tracks who approved which certificate + when |

---

## Dependency Summary

```
# New Composer packages
composer require filament/filament:"^3.0"
composer require spatie/laravel-permission
composer require livewire/livewire:"^3.0"   # pulled automatically by Filament

# Optional but strongly recommended
composer require owen-it/laravel-auditing   # audit trail (who approved what)
```

No new hosting infrastructure is required. The admin panel runs on the same PHP-FPM / web server as the existing API. Livewire uses standard HTTP polling — no WebSocket server needed.

---

## Security Considerations

| Risk | Mitigation |
|---|---|
| Admin session and mobile JWT sharing the same auth guard | Separate `AdminUser` model with its own session guard — the mobile JWT middleware never touches admin sessions |
| Brute-force on `/admin/login` | Filament has built-in rate limiting on the login form; additionally apply Laravel's `throttle` middleware to the `/admin/*` route group |
| CS agent approving certificates (should be ops only) | Filament resource-level `canCreate()`, `canEdit()`, `canDelete()` gated by Spatie role checks |
| Sensitive data (Stripe keys, ABN, cert docs) visible to CS | `PaymentResource` hides raw Stripe secret keys; CS role denied access to `PaymentResource`; cert documents shown via signed temporary S3/storage URLs |
| Certificate document path enumeration | Documents served through a signed URL controller action, not direct public paths |
