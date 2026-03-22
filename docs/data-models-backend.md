# mitabl Backend — Data Models

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** backend

---

## Database: MySQL 8.0

---

## Core Marketplace Models

### User (`users`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | Auto-increment |
| role_id | bigint FK → roles | 1=Admin, 2=Restaurant, 3=Foodie |
| first_name | string | |
| last_name | string | |
| email | string | Unique |
| password | string | Bcrypt hashed |
| email_verified | boolean | Default false |
| phone | string | Nullable |
| address | text | Nullable |
| avatar | string | Nullable, image path |
| description | text | Nullable |
| device_token | string | FCM token, nullable |
| suspended | boolean | Default false |
| suspension_reason | string | Nullable |
| suspended_at | datetime | Nullable |
| suspended_by | bigint FK → admin_users | Nullable |
| deleted_at | datetime | Soft delete |
| timestamps | | created_at, updated_at |

**Relationships:** hasOne(Mikitchn), hasOne(NotifyDisable), hasMany(Order), hasMany(Review), hasMany(Card), hasMany(StripeBankAccount), hasOne(StripeAccount:customer), hasOne(StripeAccount:vendor), belongsTo(Role), hasMany(SupportTicket), hasOne(UserAuthToken)

**Key Methods:** is_superAdmin(), is_restaurant(), is_customer()

---

### Mikitchn (`mikitchns`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | bigint FK → users | Kitchen owner |
| name | string | Kitchen name |
| address | string | |
| no_of_seats | integer | |
| timings | text | Legacy JSON timings |
| phone | string | |
| dine_in | boolean | |
| take_away | boolean | |
| description | text | |
| latitude | float | |
| longitude | float | |
| status | integer | 0=inactive, 1=active |
| open | boolean | Currently open |
| timestamps | | |

**Relationships:** belongsTo(User), hasMany(Foods), hasMany(Timing), hasMany(Image), hasMany(Review), hasOne(Certificate), hasMany(Order)

**Static Methods:** closest($lat, $lng) — Haversine distance calculation

---

### Foods (`foods`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| restaurant_id | bigint FK → mikitchns | |
| food_name | string | |
| cookingstyle | string | |
| specialDiet | string | |
| price | decimal(8,2) | |
| description | text | |
| pictures | text | Legacy, now uses images table |
| status | integer | 0=inactive, 1=active |
| timestamps | | |

---

### Order (`orders`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| mikitchn_id | bigint FK | |
| user_id | bigint FK | Customer |
| dine_in | boolean | |
| take_away | boolean | |
| persons | integer | |
| delivery_date | date | |
| delivery_time_from | datetime | |
| delivery_time_to | datetime | |
| message | text | |
| item_total_price | decimal(8,2) | |
| promo_code | bigint FK → promo_codes | Nullable |
| taxes | decimal(8,2) | |
| total_price | decimal(8,2) | |
| discounted_amount | decimal(8,2) | |
| status | integer | Default 2. 0=legacy_cancelled, 1=completed, 2=requested, 3=confirmed, 4=cancelled |
| paid | boolean | Default 0 |
| paymentmethod_id | string | |
| refund_percentage | integer | Default 0 |
| timestamps | | |

**Relationships:** hasMany(OrderData), belongsTo(User), belongsTo(Mikitchn), belongsTo(PromoCode), hasOne(Review), hasOne(Payment), hasOne(CancelReason), hasOne(CompletedOrder), hasMany(Refund)

---

### OrderData (`order_data`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| order_id | bigint FK → orders | |
| food_id | bigint FK → foods | |
| quantity | integer | |
| price | decimal(8,2) | Unit price |

---

## Payment Models

### Payment (`payments`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| order_id | bigint FK | Unique index |
| payment_id | string | Stripe payment ID |
| card_id | string | |
| amount | decimal(8,2) | |
| status | string | |
| confirm | boolean | Default 0 |
| confirm_date_time | datetime | |

### StripeAccount (`stripe_accounts`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | bigint | Unique composite with account_type |
| account_id | string | Stripe account ID |
| account_type | string | 'customer' or 'vendor' |

### Refund (`refunds`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| order_id | bigint FK | |
| user_id | bigint FK | |
| percentage | integer | |
| amount | decimal(8,2) | |
| balance_trans | string | Stripe balance transaction |
| refund_date | date | |
| reciept_no | string | Stripe refund ID |
| status | string | |

---

## Admin Models

### AdminUser (`admin_users`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | string | |
| email | string | Unique |
| password | string | Bcrypt |
| is_active | boolean | |
| last_login_at | datetime | |
| remember_token | string | |

### AdminActionLog (`admin_action_logs`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| admin_user_id | bigint FK | |
| action | string | |
| method | string | HTTP method |
| path | string | Request path |
| route_name | string | |
| status_code | integer | |
| ip_address | string | |
| user_agent | string | |
| correlation_id | string | |
| metadata | json | |
| request_payload | json | Sanitized (passwords/tokens redacted) |
| created_at | datetime | Immutable — update/delete throw LogicException |

---

## CRM Models

### SupportTicket (`support_tickets`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| ticket_number | string | Unique, auto-generated |
| user_id | bigint FK | Nullable (for anonymous) |
| requester_name | string | |
| requester_email | string | |
| requester_phone | string | Nullable |
| subject | string | |
| description | text | |
| source | enum | mobile_app, website, admin |
| category | enum | order_dispute, payment, account, general, other |
| priority | enum | low, normal, high, urgent |
| status | enum | open, in_progress, pending_user, resolved, closed, spam |
| assigned_to | bigint FK → admin_users | Nullable |
| order_id | bigint FK | Nullable |
| mikitchn_id | bigint FK | Nullable |
| first_response_due_at | datetime | SLA deadline |
| first_responded_at | datetime | |
| resolution_due_at | datetime | SLA deadline |
| resolved_at | datetime | |
| closed_at | datetime | |
| requester_token | string | Unique, for anonymous access |
| intake_fingerprint | string | Duplicate detection |
| spam_score | integer | 0-100 |
| spam_detected_at | datetime | |
| merged_into_id | bigint FK | Self-referencing |
| split_from_id | bigint FK | Self-referencing |
| timestamps | | |

**SLA Deadlines by Priority:**
- Urgent: First response 15min, Resolution 4hr
- High: First response 30min, Resolution 8hr
- Normal: First response 60min, Resolution 24hr
- Low: First response 120min, Resolution 48hr

---

## Platform Governance Models

### PlatformSetting (`platform_settings`)
| Column | Type | Notes |
|--------|------|-------|
| key | string | Unique, primary identifier |
| value | json | Setting value |
| value_type | string | Type hint |
| description | string | |
| version | integer | Optimistic locking |
| updated_by | bigint FK → admin_users | |

### Policy (`policies`)
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | string | |
| version | string | Semver |
| schema_version | string | |
| definition | json | Policy content |
| effective_at | datetime | Scheduled activation |
| active | boolean | |
| created_by | bigint FK | |
| published_by | bigint FK | |
| published_at | datetime | |

---

## Collaboration Models

### InternalNote (`internal_notes`) — Polymorphic
Attachable to: User, Mikitchn, Order, SupportTicket

### Tag (`tags`) — Polymorphic Many-to-Many
Taggable: User, Mikitchn, Order, SupportTicket via `taggables` pivot

### WatchSubscription (`watch_subscriptions`) — Polymorphic
Watchable: User, Mikitchn, Order, SupportTicket — AdminUser subscribes to changes

---

## Entity Relationship Diagram (Simplified)

```
User ─────┬──── hasOne ────── Mikitchn ──── hasMany ──── Foods
          │                      │                          │
          │                      ├──── hasMany ──── Timings │
          │                      ├──── hasMany ──── Images  │
          │                      ├──── hasOne ───── Certificate
          │                      └──── hasMany ──── Reviews ◄── User
          │
          ├──── hasMany ──── Orders ──┬── hasMany ── OrderData ── belongsTo ── Foods
          │                           ├── hasOne ─── Payment
          │                           ├── hasOne ─── CompletedOrder
          │                           ├── hasOne ─── CancelReason
          │                           ├── hasMany ── Refund
          │                           └── hasOne ─── Review
          │
          ├──── hasMany ──── SupportTickets ──┬── hasMany ── Messages
          │                                    ├── hasMany ── Attachments
          │                                    └── hasMany ── Events
          │
          ├──── hasOne ───── StripeAccount (customer)
          ├──── hasOne ───── StripeAccount (vendor)
          ├──── hasMany ──── Cards
          └──── hasMany ──── StripeBankAccounts

AdminUser ──┬── hasMany ── AdminActionLogs
            ├── assigned ── SupportTickets
            ├── created ── Policies, Templates, PlatformSettings
            └── authored ── InternalNotes
```
