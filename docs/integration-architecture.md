# mitabl — Integration Architecture

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive

---

## Overview

The mitabl platform is a monorepo with 3 application parts that communicate through defined integration points. The mobile app is the primary client, the backend is the central API server, and the website has minimal integration (contact form only).

---

## Integration Map

```
┌──────────────────┐     REST/JSON + JWT      ┌──────────────────────┐
│                  │ ◄──────────────────────── │                      │
│   Mobile App     │                           │   Backend API        │
│   (Flutter)      │ ────────────────────────► │   (Laravel 12)       │
│                  │     ~30 API endpoints      │                      │
└──────────────────┘                           │  ┌────────────────┐  │
                                               │  │ Filament Admin │  │
┌──────────────────┐     POST /api/support/    │  │ (Server-side)  │  │
│   Website        │ ────────────────────────► │  └────────────────┘  │
│   (Static HTML)  │     ticket (AJAX)         │                      │
└──────────────────┘                           └──────────┬───────────┘
                                                          │
                               ┌──────────────────────────┼──────────────────┐
                               │                          │                  │
                               ▼                          ▼                  ▼
                        ┌─────────────┐           ┌──────────────┐   ┌─────────────┐
                        │ Stripe API  │           │ Firebase FCM │   │ SMTP (Mail) │
                        │ (Payments)  │           │ (Push Notif) │   │ (Email)     │
                        └─────────────┘           └──────────────┘   └─────────────┘
```

---

## Integration Points

### 1. Mobile App → Backend API

| Aspect | Detail |
|--------|--------|
| **Protocol** | HTTPS REST/JSON |
| **Authentication** | JWT Bearer Token |
| **Base URL** | Configured in `assets/cfg/configuration.json` |
| **Endpoint Count** | ~50 endpoints across public, authenticated, and role-gated groups |
| **Request Timeout** | 15 seconds |
| **Token Refresh** | Automatic 401 → refresh → retry via AuthAwareHttpClient |
| **Offline Handling** | ConnectivityService checks before every request |
| **Multipart Support** | Image uploads for kitchen, food, avatar |

**Data Flow:**
- Discovery: App → `GET /v2/discovery/*` → Backend (DiscoveryService with Haversine + caching) → JSON response
- Orders: App → `POST /v2/updateorderstatus` → Backend (OrderService → Payment events → Stripe)
- Auth: App → `POST /login` → Backend (JWT issued) → App stores in FlutterSecureStorage

---

### 2. Website → Backend API

| Aspect | Detail |
|--------|--------|
| **Protocol** | HTTPS POST (AJAX) |
| **Authentication** | None (public endpoint) |
| **Endpoint** | `POST /api/support/ticket` |
| **Rate Limit** | 4/min per email, 30/hr per IP |
| **Spam Prevention** | Honeypot field, client-side deduplicate guard |

**Data Flow:**
- Contact form → AJAX POST with name, email, subject, description → Backend creates SupportTicket → Returns ticket_number

---

### 3. Backend → Stripe API

| Aspect | Detail |
|--------|--------|
| **Protocol** | HTTPS (stripe-php SDK) |
| **Direction** | Backend → Stripe (outbound) + Stripe → Backend (webhooks) |
| **Currency** | AUD |
| **Country** | AU |
| **Operations** | Customer creation, payment intents, checkout sessions, card management, vendor transfers (with commission), refunds (with idempotency) |
| **Webhook** | `POST /api/stripe/webhook` handles payment_intent.succeeded/failed/canceled, charge.refunded |

**Commission Model:**
- First 5 orders: 0% commission
- Orders 6-50: 10% commission
- Orders 51-200: 15% commission
- Orders 200+: 20% (or 25% if rating < 3.5)

---

### 4. Backend → Firebase FCM

| Aspect | Detail |
|--------|--------|
| **Protocol** | FCM HTTP API |
| **Direction** | Backend → Firebase → Mobile Device |
| **Trigger** | Model observers (OrderObserver, ReviewObserver, MikitchnObserver, CertificateObserver) |
| **Device Token** | Stored in `users.device_token`, updated via `POST /v2/account/device-token` |

**Notification Types:**
- Order status changes (requested, confirmed, completed, cancelled)
- New reviews received
- Kitchen activation
- Certificate approval/rejection

---

### 5. Backend → SMTP (Email)

| Aspect | Detail |
|--------|--------|
| **Protocol** | SMTP via Laravel Mail |
| **Templates** | 10 Mailable classes |
| **Queue** | CRM emails queued to `crm-communications` Redis queue |
| **PII Redaction** | PiiRedactionService strips emails, phones, card numbers from CRM communications |

**Email Types:**
- OTP verification, welcome, password reset, account deletion
- Order invoice, refund invoice
- Kitchen activation, certificate approval/rejection
- Support ticket acknowledgement, reply, SLA escalation

---

## Shared Data Contracts

### User Identity
- Mobile app stores user as `UserModel` (id, name, role, roleId, accessToken)
- Backend `User` model is the source of truth
- Role IDs: 1=Admin (API-blocked), 2=Restaurant/Cook, 3=Foodie/Customer

### Kitchen/Restaurant
- Mobile app models: `GetCookProfileModel.Kitchen`, `NearByRestaurantsList`, `RecommendedResturant`
- Backend source: `Mikitchn` model with Restaurant API Resource transform

### Orders
- Mobile app model: `Bookings` (with nested Mikitchn, Customer, Items)
- Backend source: `Order` model with Order API Resource transform
- Status codes: 0=legacy_cancelled, 1=completed, 2=requested, 3=confirmed, 4=cancelled

### Images
- Upload: Multipart POST from mobile app
- Storage: `public/Images/{kitchen|food|user}/` paths
- Access: `{image_base_url}/{path}` from mobile app

---

## Environment-Specific Integration

| Environment | Backend URL | Stripe | Firebase | Email |
|-------------|-----------|--------|----------|-------|
| Development | http://localhost:8000 | Test keys | Optional | Log driver |
| Staging | TBD | Test keys | Optional | SMTP |
| Production | https://mitabl.com | Live keys | Live | SMTP |
