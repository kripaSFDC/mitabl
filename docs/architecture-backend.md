# mitabl Backend — Architecture Document

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** backend | **Type:** Laravel 12 API + Filament Admin

---

## Executive Summary

The backend is a Laravel 12 application serving as the primary API for the mitabl food marketplace platform. It handles authentication, kitchen/menu management, order lifecycle, payment processing (Stripe), push notifications (Firebase), and a comprehensive CRM/support ticket system. A Filament 3 admin panel provides operations management with RBAC across 5 admin roles and 42 granular permissions.

---

## Technology Stack

| Category | Technology | Version | Justification |
|----------|-----------|---------|---------------|
| Language | PHP | 8.2 | Modern PHP with typed properties, enums, fibers |
| Framework | Laravel | 12.1 | Full-stack framework with ORM, queue, events, scheduler |
| Database | MySQL | 8.0 | Relational store for transactional marketplace data |
| Cache & Queue | Redis | 7.2 | Session-less caching, Horizon queue backend |
| Queue Dashboard | Laravel Horizon | 5.45 | Real-time queue monitoring, supervisor config |
| Admin Panel | Filament | 3.0 | Rapid admin UI with RBAC integration |
| API Authentication | tymon/jwt-auth | 2.2 | Stateless JWT for mobile API |
| Admin Auth | Laravel Session | (built-in) | Separate `admin` guard with session-based auth |
| Authorization | spatie/laravel-permission | 6.7 | Role-based access control for admin panel |
| Payments | stripe/stripe-php | 8.1 | Payment intents, checkout sessions, transfers, refunds |
| API Documentation | L5 Swagger | 10.1 | OpenAPI spec generation |
| Auditing | owen-it/laravel-auditing | 14.0 | Model change tracking |
| Favorites | overtrue/laravel-favorite | 5.3 | Polymorphic favorite/unfavorite |
| HTTP Client | Guzzle | 7.0.1 | External API calls |
| Testing | PHPUnit | 11.5 | Unit + feature test framework |

---

## Architecture Pattern

**Layered Architecture with Service Layer:**

```
┌─────────────────────────────────────────────────────┐
│                    Mobile App / Website               │
├─────────────────────────────────────────────────────┤
│               Routes (api.php / web.php)              │
├─────────────────────────────────────────────────────┤
│              Middleware Chain                          │
│  (CORS → Throttle → Auth:API → Role → ApiUserActive)│
├─────────────────────────────────────────────────────┤
│               Controllers                             │
│  (Validate → Delegate to Service → Return Resource)  │
├─────────────────────────────────────────────────────┤
│               Services (Business Logic)               │
│  (OrderService, PaymentService, DiscoveryService,    │
│   SupportTicketService, AuthService, etc.)           │
├─────────────────────────────────────────────────────┤
│               Eloquent Models + Observers            │
│  (30+ models with relationships, scopes, events)     │
├─────────────────────────────────────────────────────┤
│               MySQL 8.0 + Redis 7.2                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│               Filament Admin Panel                    │
│  (Resources, Pages, Widgets — separate admin guard)  │
├─────────────────────────────────────────────────────┤
│               Same Service Layer                      │
├─────────────────────────────────────────────────────┤
│               Same Models + Database                  │
└─────────────────────────────────────────────────────┘
```

---

## Authentication & Authorization

### API Authentication (Mobile)
- **Method:** JWT via `tymon/jwt-auth`
- **Flow:** Email/password → JWT token → Bearer header on all requests
- **Token Storage:** `UserAuthToken` model (single-session enforcement)
- **Refresh:** `POST /api/token/refresh` within refresh TTL
- **OTP:** 6-digit hashed OTP with 10-min expiry, 5 attempts, 15-min lockout

### Admin Authentication
- **Method:** Session-based via `admin` guard
- **Model:** `AdminUser` (separate from API `User`)
- **Step-Up Auth:** 15-minute re-authentication window for sensitive operations
- **Panel Access:** `canAccessPanel()` requires `is_active` flag

### RBAC (Admin Panel)
- **Roles (5):** super_admin, platform_admin, operations, customer_service, finance_readonly
- **Permissions (42):** Granular permissions mapped to Filament resources/pages
- **Implementation:** spatie/laravel-permission with `admin_` prefixed tables

### Security Hardening
- Admin identities (role_id=1) blocked from API authentication
- Suspended users blocked at middleware level
- Rate limiting on all public endpoints (login: 10/min, OTP: 5/min, etc.)
- Immutable audit trail for all admin mutations
- PII redaction in CRM communications
- Malware scanning on support ticket attachments

---

## API Surface

### Route Groups
| Group | Middleware | Endpoint Count | Description |
|-------|-----------|---------------|-------------|
| Health | `api` | 4 | Liveness, readiness, startup probes |
| Public | `api` + throttle | 12 | Auth, support tickets, pre-registration |
| Authenticated V2 | `auth:api` + `api.user.active` | 15 | Profile, discovery, payments, account |
| Customer Role | + `customer` | 1 | Customer-specific profile |
| Restaurant Role | + `restaurant` | 14 | Kitchen, menu, orders, dashboard |
| Deprecated | `api` | 5 | 410 Gone / 405 sunset responses |
| Web | `web` | 2 | Password reset form |

### Key API Modules
1. **Identity & Account** — Login, register, OTP, password reset, profile, role switching, device tokens
2. **Kitchen Management** — Create/edit kitchen, certificates, timings, open/close, dashboard
3. **Menu & Discovery** — Food CRUD, filtered/nearest/top-rated/recommended search with caching
4. **Orders** — Create order, status updates, booking views, customer/cook order lists
5. **Payments** — Card management, payment intents, checkout sessions, vendor transfers, refunds
6. **Support/CRM** — Ticket creation (with spam detection), replies, SLA management
7. **Notifications & Reviews** — FCM push, bi-directional review flows

---

## Data Architecture

### Core Tables (40+ migrations)

**Marketplace:** users, roles, mikitchns, foods, cooking_styles, special_diets, timings, images, certificates, favorites, reviews

**Orders:** orders, order_data, promo_codes, completed_orders, cancel_reasons

**Payments:** payments, stripe_accounts, cards, stripe_bank_accounts, transfers, refunds

**Admin:** admin_users, admin_password_resets, admin_roles, admin_permissions (spatie tables with admin_ prefix), admin_action_logs

**CRM:** support_tickets (30+ columns), support_ticket_messages, support_ticket_attachments, support_ticket_events, crm_communication_logs

**Platform:** platform_settings, platform_setting_change_requests, policies, policy_change_log, templates, pre_registrations

**Collaboration:** internal_notes, tags, taggables, watch_subscriptions

### Key Relationships
- User → hasOne Mikitchn (cook's kitchen)
- Mikitchn → hasMany Foods, Timings, Reviews, Orders, Images
- Order → belongsTo User, Mikitchn; hasMany OrderData, Refunds
- SupportTicket → hasMany Messages, Attachments, Events; belongsTo User, AdminUser (assignee)

---

## Service Layer

| Service | Responsibility | Lines |
|---------|---------------|-------|
| SupportTicketService | Full CRM lifecycle (create, reply, merge, split, SLA, spam detection) | ~985 |
| PaymentService | Stripe integration (cards, intents, checkout, transfers, refunds) | ~500 |
| DiscoveryService | Restaurant search with caching, geolocation, filters | ~300 |
| OrderService | Order creation with price validation, promo codes, first-order discounts | ~200 |
| AuthService | OTP generation, hashing, email dispatch | ~100 |
| AccountProfileService | Profile updates, role switching, device tokens, notifications | ~200 |
| SystemHealthService | 11 health checks (DB, Redis, queue, scheduler, mail, Stripe, etc.) | ~200 |
| PlatformRuntimeConfigService | DB-to-config overlay for 50+ runtime settings | ~200 |
| AdminPaymentRefundService | Full refund with double-spend protection and audit | ~150 |
| CrmCommunicationService | Queued emails with PII redaction and delivery tracking | ~100 |
| AdminAuditLogService | Immutable audit logging with payload sanitization | ~100 |

---

## Event-Driven Architecture

### Events → Listeners
| Event | Listener | Queue | Action |
|-------|----------|-------|--------|
| CancelOrderRefund | CancelOrderRefundListener | Yes | Calculates refund (full/50%), transfers to vendor if <12hr cancel |
| MakeOrderPaymentToVendor | MakeOrderPaymentToVendorListener | Yes | Transfers payment with tiered commission (0-25%) |
| NotificationSent | LogNotification | Yes | Sends FCM push notification |
| MessageSent | MarkCrmCommunicationDelivered | No | Updates CRM log status to 'sent' |

### Observers (6)
- **OrderObserver** — Push notifications on status change, invoice email on completion
- **MikitchnObserver** — Activation notification, discovery cache invalidation
- **ReviewObserver** — Push notification, cache invalidation
- **UserObserver** — Welcome email on verification, deletion email
- **FoodsObserver** — Discovery cache invalidation
- **CertificateObserver** — Discovery cache invalidation

### Queued Jobs
- **ProcessSupportTicketSlaEscalationJob** — SLA breach processing (queue: crm-escalations)
- **SendCertificateReviewOutcomeJob** — Certificate approval/rejection emails (5 retries, idempotent)

### Scheduled Commands
| Command | Schedule | Purpose |
|---------|----------|---------|
| orderpayment:cron | Hourly | Process vendor payouts for 24hr+ completed orders |
| support:sla:scan | Every 5 min | Scan for SLA breaches, dispatch escalation jobs |
| platform:health:synthetic | Every 5 min | Run health checks, update scheduler heartbeat |
| platform:policies:activate-due | Every minute | Activate scheduled policy versions |

---

## Admin Panel (Filament 3)

### Resources (12)
UserResource, MicookResource, MifoodieResource, MikitchnResource, OrderResource, PaymentResource, CertificateResource, SupportTicketResource, PreRegistrationResource, PromoCodeResource, PolicyResource, TemplateResource, AdminActionLogResource

### Pages (7)
AdminLogin, CrmAgentWorkspacePage, IntegrationLogsPage, PlatformSettingsPage, QueueOpsPage, SecurityAdminPage, SystemHealthPage

### Widgets (9)
CrmAgingBucketsChart, CrmQueueStatsWidget, DashboardLiveOperationsWidget, DashboardOperationalSnapshotWidget, IntegrationHealthWidget, OrdersPerDayChartWidget, RegistrationsPerDayChartWidget, SlaHealthWidget, SystemHealthSummaryWidget

---

## Testing Strategy

| Type | Count | Coverage |
|------|-------|---------|
| Feature Tests | 33 files | Admin panel, API contracts, certificates, financial, hardening, permissions, CRM E2E |
| Unit Tests | 13 files | Services (Auth, Payment, CRM, Health, Config), middleware, models |
| Coverage Threshold | 80% | Enforced via `scripts/check-coverage.php` in CI |

---

## Deployment Architecture

- **Container:** PHP 8.2-FPM + Nginx in single container (port 8000)
- **Queue Worker:** Separate container running Laravel Horizon
- **Scheduler:** Separate container running `schedule:work`
- **Database:** MySQL 8.0 container
- **Cache/Queue:** Redis 7.2-alpine container
- **Production Host:** Contabo VPS with host-level Nginx (SSL via Let's Encrypt)
