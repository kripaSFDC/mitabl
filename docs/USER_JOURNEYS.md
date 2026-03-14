# User Journeys (Codebase-Verified: miCook + miFoodi)

This document is a **critical, code-verified journey map** for miCook and miFoodi.
It is intentionally strict: if a route is not wired in `backend/routes/api.php`, the journey step is treated as **not available to clients**.

## Source of truth audited

- API route wiring: `backend/routes/api.php`
- Auth + registration behavior:
  - `backend/app/Http/Controllers/Api/User/Concerns/HandlesUserAuthentication.php`
- Account + role switching + onboarding:
  - `backend/app/Http/Controllers/Api/V2/AccountController.php`
  - `backend/app/Services/AccountProfileService.php`
- Kitchen + menu + cook dashboard:
  - `backend/app/Http/Controllers/Api/MikitchnController.php`
  - `backend/app/Http/Controllers/Api/FoodsController.php`
- Orders:
  - `backend/app/Http/Controllers/Api/OrderController.php`
  - `backend/app/Http/Controllers/Api/V2/AccountFoodieController.php`
- Discovery:
  - `backend/app/Http/Controllers/Api/V2/DiscoveryController.php`
  - `backend/app/Services/DiscoveryService.php`
- Payments:
  - `backend/app/Http/Controllers/Api/V2/PaymentsController.php`
- Mobile app calls (effective usage):
  - `mobile-app/lib/repos/*.dart`

---

## 1) Coverage verdict against requested checkpoints

### 1.1 miCook checkpoints

| Requested checkpoint | Codebase status | Evidence |
|---|---|---|
| Registration | ✅ Implemented | `POST /api/register`, `POST /api/verifyOtp`, `POST /api/resendotp`, `POST /api/login` |
| Onboarding | ✅ Implemented (role transition + cook checklist) | `POST /api/v2/account/switch-role`, `POST /api/v2/account/roles/cook/activate`, `POST /api/v2/account/onboarding/cook/start`, `POST /api/v2/account/onboarding/cook/vendor-account` |
| Kitchen creation | ✅ Implemented | `POST /api/v2/mikitchn/store` (guarded by `restaurant` middleware) |
| Payments (cook side) | ⚠️ Partial | Dashboard earnings exist; manual vendor transfer API is intentionally forbidden (`403`) |
| Food catalog | ✅ Implemented | `GET /api/v2/mymenu`, `POST /api/v2/food/add`, `POST /api/v2/food/editfood`, `POST /api/v2/food/status/{id}`, `DELETE /api/v2/food/{id}` |
| Order acceptance / fulfillment | ✅ Implemented | `GET /api/v2/kitchenorderrequest`, `GET /api/v2/kitchenupcomingorders`, `GET /api/v2/allorders`, `POST /api/v2/updateorderstatus` |

### 1.2 miFoodi checkpoints

| Requested checkpoint | Codebase status | Evidence |
|---|---|---|
| Search miCook/miKitchn | ✅ Implemented as discovery lists/filters (not keyword text search) | `GET /api/v2/discovery/filtered`, `nearest`, `top-rated`, `recommended`, `restaurants/{id}` |
| Placing order | ❌ **Not route-wired** | `OrderController::store` exists but no active route maps to it in `backend/routes/api.php` |
| Payment setup | ✅ Implemented | `GET/POST /api/v2/payments/cards`, `POST /api/v2/payments/checkout-session` |
| Payment execution for order | ✅ Implemented API-side | `POST /api/v2/payments/intent`, `POST /api/v2/payments/intent/confirm` (foodie + ownership guarded) |
| Location tracking | ❌ No live tracking endpoint | No `/tracking`-style route is registered; only distance-aware discovery/detail responses |
| Historic orders | ✅ Implemented | `GET /api/v2/account/orders` with filters |

---

## 2) Shared authentication + account foundation

### 2.1 Auth lifecycle

Public routes:

1. `POST /api/login`
2. `POST /api/token/refresh`
3. `POST /api/register`
4. `POST /api/verifyOtp`
5. `POST /api/resendotp`
6. `POST /api/password/reset`

Authenticated v2:

7. `POST /api/v2/logout`

### 2.2 Enforced behavior

- Mobile login accepts only role `2` (miCook) or `3` (miFoodi).
- Admin identity roles are blocked from mobile authentication.
- Suspended users are blocked.
- Unverified users are OTP-driven.
- JWT refresh path is implemented and persists latest token.

### 2.3 Profile + account security

Authenticated `/api/v2` routes:

- `GET /api/v2/account/profile`
- `PUT /api/v2/account/profile`
- `POST /api/v2/editprofile` (legacy mobile compatibility path)
- `POST /api/v2/account/password/change`
- `POST /api/v2/account/device-token`
- `POST /api/v2/account/notifications/toggle`
- `POST /api/v2/account/notification-preferences`
- `GET /api/v2/mob-contact`
- `GET /api/v2/account/mobile-contact`

---

## 3) miCook journey (role_id=2)

## 3.1 Role transition + onboarding

1. `POST /api/v2/account/switch-role` with `role_id=2`
2. `POST /api/v2/account/roles/cook/activate` (alias: `.../onboarding/cook/start`)
3. `POST /api/v2/account/onboarding/cook/vendor-account`

Onboarding response contains:

- `role_transition.state`
- `role_transition.missing`
- `role_transition.onboarding_required`
- `role_transition.next_required_step`
- `role_transition.checklist` with:
  - `vendor_account`
  - `kitchen_profile`
  - `certificate`
  - `payout_setup`

Membership status for cook role is auto-managed between `onboarding` and `active`.

## 3.2 Kitchen creation and editing

- `POST /api/v2/mikitchn/store`
- `POST /api/v2/mikitchn/editkitchen`
- `POST /api/v2/deleteimage`

Behavior:

- Create blocks duplicate kitchen for same user (`409`).
- Update blocks when no kitchen exists (`404`).
- `timings` must be valid JSON containing `days` array.
- Geo validation exists for `lat`/`lng` ranges.
- Kitchen certificate (`abn`, `certificate_no`) is upserted.
- Discovery caches are invalidated after kitchen save.

## 3.3 Food catalog lifecycle

- `GET /api/v2/mymenu`
- `GET /api/v2/getcookingstyles`
- `GET /api/v2/getspecialdiets`
- `POST /api/v2/food/add`
- `POST /api/v2/food/editfood`
- `POST /api/v2/food/status/{id}`
- `DELETE /api/v2/food/{id}`

Behavior:

- Food create requires pictures.
- Food update requires `food_id` and restaurant ownership.
- `specialDiet` must be int array and is JSON-encoded for storage.
- Food status toggles active/inactive.

## 3.4 Incoming order acceptance + fulfillment

- `GET /api/v2/kitchenorderrequest` (`status=2` requested)
- `GET /api/v2/kitchenupcomingorders` (`status=3` confirmed + future date)
- `GET /api/v2/allorders`
- `POST /api/v2/updateorderstatus`

Order status values used:

- `0` legacy cancelled (normalized to `4` on update)
- `1` completed
- `2` requested
- `3` confirmed
- `4` cancelled

Behavior:

- Order updates are ownership-gated (order owner or owning cook’s kitchen).
- Confirming (`3`) confirms Stripe payment intent and updates payment/order in transaction.
- Completing (`1`) upserts completion timestamp in `completed_orders`.

## 3.5 Cook payments / earnings

- `GET /api/v2/account/dashboard` returns `total_earning`, `n_bookings`, `n_upcoming_bookings`.
- Earnings are calculated via Stripe transfer history only when cook vendor account exists.
- `POST /api/v2/payments/vendor-transfer` always returns forbidden (`403`) for app users.

---

## 4) miFoodi journey (role_id=3)

## 4.1 Discovery/search and exploration

- `GET /api/v2/discovery/filtered`
- `GET /api/v2/discovery/nearest`
- `GET /api/v2/discovery/top-rated`
- `GET /api/v2/discovery/recommended`
- `GET /api/v2/discovery/restaurants/{id}`

Important precision:

- Discovery supports filtering by `cooking_styles`, `dine_in`, `take_away`, and geo params (`lat/lon`).
- There is **no dedicated free-text keyword search endpoint** in current v2 routes.
- Restaurant detail includes favorite state, cook summary, certificate context, and can include distance when valid coordinates are supplied.

## 4.2 Favorites and personalization

Customer-only:

- `GET /api/v2/account/favorites`
- `POST /api/v2/account/favorites/toggle`

## 4.3 Order placement + payment

### What exists

- Payment setup: `GET/POST /api/v2/payments/cards`
- Checkout setup: `POST /api/v2/payments/checkout-session`
- Order payment intent: `POST /api/v2/payments/intent`
- Payment confirm: `POST /api/v2/payments/intent/confirm`

### What does **not** currently exist as route wiring

- No active API route for creating a new order (`OrderController::store` is implemented but not registered in `backend/routes/api.php`).

## 4.4 History views

Customer-only:

- `GET /api/v2/account/orders` (supports `page`, `limit`, `status`, `from_date`, `to_date`)
- `GET /api/v2/account/payments/history` (supports filters/pagination)

## 4.5 Location tracking

- No live order-tracking endpoint is route-wired.
- Current location capability is limited to discovery distance computation and restaurant-detail distance when `lat/lon` are provided.

---

## 5) Mobile app wiring reality (what app currently calls)

Called directly from `mobile-app/lib/repos/*`:

- Auth: `login`, `register`, `verifyOtp`, `password/reset`, `token/refresh`, `v2/logout`
- Cook: `v2/mikitchn/store`, `v2/mikitchn/editkitchen`, `v2/mymenu`, `v2/getcookingstyles`, `v2/getspecialdiets`, `v2/food/add`, `v2/food/editfood`, `v2/food/status/{id}`, `v2/kitchenorderrequest`, `v2/kitchenupcomingorders`, `v2/allorders`, `v2/updateorderstatus`
- Foodie: `v2/discovery/recommended`, `v2/discovery/top-rated`, `v2/discovery/nearest`, `v2/account/favorites`, `v2/account/favorites/toggle`, `v2/account/orders`, `v2/account/payments/history`, `v2/payments/cards`
- Shared: `v2/account/profile`, `v2/account/dashboard`, `v2/account/notification-preferences`, `v2/account/switch-role`, `v2/deleteimage`, `v2/editprofile`, `v2/mob-contact`, `support/ticket` create/get/reply, `app/version`

Available in backend but **not currently called** from repos:

- `POST /api/resendotp`
- `POST /api/v2/account/roles/cook/activate`
- `POST /api/v2/account/onboarding/cook/start`
- `POST /api/v2/account/onboarding/cook/vendor-account`
- `POST /api/v2/account/password/change`
- `POST /api/v2/account/device-token`
- `POST /api/v2/account/notifications/toggle`
- `GET /api/v2/discovery/filtered`
- `GET /api/v2/discovery/restaurants/{id}`
- `POST /api/v2/payments/cards`
- `POST /api/v2/payments/checkout-session`
- `POST /api/v2/payments/intent`
- `POST /api/v2/payments/intent/confirm`

Client call with no matching route:

- Mobile repo calls `v2/account/delete`, but no such route is currently registered.

---

## 6) Deprecated and compatibility endpoints

- `GET /api/mobcontact` -> `410` (use `/api/v2/mob-contact`)
- `GET /api/v1/mob-contact` -> `410` (sunset path)
- Method guards:
  - `GET /api/v1/food/status/{id}` -> `405` (`POST` required)
  - `GET /api/v2/food/status/{id}` -> `405` (`POST` required)
  - `GET /api/v2/payments/checkout-session` -> `405` (`POST` required)

---

## 7) Cleanup opportunities discovered during audit (not changed here)

- `OrderController::store` is implemented but unreachable due to missing route registration.
- Mobile still references `v2/account/delete` although backend route is absent.
- Naming/typo inconsistencies (`myUpcomingOrderss`, message typos like `Kitchecn`) can be cleaned for maintainability.

