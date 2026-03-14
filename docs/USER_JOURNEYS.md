# User Journeys (100% Codebase-Matched Audit)

This document is a **route + controller + mobile-client** audit of miCook and miFoodi journeys in the current repository.

## Source of truth used for this document

- API route wiring: `backend/routes/api.php`
- Journey behavior and business rules:
  - `backend/app/Http/Controllers/Api/User/UserController.php`
  - `backend/app/Http/Controllers/Api/User/Concerns/HandlesUserAuthentication.php`
  - `backend/app/Http/Controllers/Api/V2/AccountController.php`
  - `backend/app/Services/AccountProfileService.php`
  - `backend/app/Http/Controllers/Api/MikitchnController.php`
  - `backend/app/Http/Controllers/Api/FoodsController.php`
  - `backend/app/Http/Controllers/Api/OrderController.php`
  - `backend/app/Http/Controllers/Api/V2/DiscoveryController.php`
  - `backend/app/Http/Controllers/Api/V2/AccountFoodieController.php`
  - `backend/app/Http/Controllers/Api/V2/PaymentsController.php`
  - `backend/app/Http/Controllers/Api/SupportTicketController.php`
- Mobile wiring (actual calls from app): `mobile-app/lib/repos/*.dart`

---

## 1) Platform roles and scope boundaries

- Mobile-authenticated roles are enforced as:
  - **miCook**: `role_id=2`
  - **miFoodi**: `role_id=3`
- Admin identity roles are blocked from mobile API login flow and directed to admin web authentication.
- Most app workflows run via authenticated `/api/v2/*` endpoints with `auth:api` + `api.user.active` middleware.

---

## 2) Common journey foundation (both personas)

## 2.1 Authentication lifecycle

1. Login: `POST /api/login`
2. Token refresh: `POST /api/token/refresh`
3. Register: `POST /api/register`
4. Verify OTP: `POST /api/verifyOtp`
5. Resend OTP: `POST /api/resendotp`
6. Reset password: `POST /api/password/reset`
7. Logout (v2): `POST /api/v2/logout`

### Auth behavior details implemented

- Login rejects suspended users and non-mobile roles.
- Unverified email users are OTP-driven.
- Token refresh path exists and is used by mobile session handling.

## 2.2 Account/profile/security operations

Authenticated v2:

- `GET /api/v2/account/profile`
- `PUT /api/v2/account/profile`
- `POST /api/v2/editprofile` (legacy multipart update path still wired and used in mobile)
- `POST /api/v2/account/password/change`
- `POST /api/v2/account/device-token`
- `POST /api/v2/account/notifications/toggle`
- `POST /api/v2/account/notification-preferences`
- `GET /api/v2/mob-contact`
- `GET /api/v2/account/mobile-contact`

## 2.3 Support ticket operations (public + authenticated)

- `POST /api/support/ticket` (create)
- `GET /api/support/ticket/{id}` (read)
- `POST /api/support/ticket/{id}/reply` (reply)

Access is allowed by authenticated ownership or `X-Ticket-Token` header.

---

## 3) miCook end-to-end journey (role_id=2)

## 3.1 Become a cook (role transition + onboarding)

1. Switch role: `POST /api/v2/account/switch-role` with `role_id=2`.
2. Start onboarding: `POST /api/v2/account/roles/cook/activate` (alias: `POST /api/v2/account/onboarding/cook/start`).
3. Complete vendor account step: `POST /api/v2/account/onboarding/cook/vendor-account`.

### Onboarding state model implemented

- API returns `role_transition` with:
  - `state`
  - `missing` checklist items
  - `onboarding_required`
  - `next_required_step`
  - `checklist` (`vendor_account`, `kitchen_profile`, `certificate`, `payout_setup`)
- Cook membership status is managed between `onboarding` and `active` based on checklist completion.

## 3.2 Kitchen setup and management

Restaurant middleware routes under `/api/v2`:

- `POST /api/v2/mikitchn/store` (create kitchen)
- `POST /api/v2/mikitchn/editkitchen` (update kitchen)
- `POST /api/v2/deleteimage` (delete kitchen/food image)
- `GET /api/v2/getdashboarddata` (legacy cook dashboard endpoint)
- `GET /api/v2/account/dashboard` (account-scoped cook dashboard)

### Kitchen transaction details implemented

- Kitchen create fails if a kitchen already exists for the user.
- Kitchen update fails if no kitchen exists.
- `timings` must be valid JSON containing `days[]` entries.
- Latitude/longitude validation exists.
- Certificate fields (`abn`, `certificate_no`) are upserted when provided or already present.
- Discovery cache invalidation is triggered on kitchen save.

## 3.3 Menu/catalog lifecycle (cook)

- `GET /api/v2/mymenu`
- `GET /api/v2/getcookingstyles`
- `GET /api/v2/getspecialdiets`
- `POST /api/v2/food/add`
- `POST /api/v2/food/editfood`
- `POST /api/v2/food/status/{id}`
- `DELETE /api/v2/food/{id}`

### Menu transaction details implemented

- Create food requires pictures.
- Update food requires `food_id` and restaurant ownership.
- `specialDiet` is validated and persisted as encoded int array.
- Food status endpoint toggles active/inactive.

## 3.4 Incoming orders and fulfillment (cook)

- `GET /api/v2/kitchenorderrequest` (requested orders)
- `GET /api/v2/kitchenupcomingorders` (upcoming confirmed)
- `GET /api/v2/allorders` (all filtered historical states)
- `POST /api/v2/updateorderstatus` (state updates)

### Order status model used in code

- `0` legacy cancelled
- `1` completed
- `2` requested
- `3` confirmed
- `4` cancelled

### Fulfillment transaction behavior

- Status updates are ownership-gated (cook’s kitchen or customer owning the order).
- Confirming order (`status=3`) attempts Stripe payment-intent confirmation and writes payment confirmation fields transactionally.
- Completing order (`status=1`) upserts completion timestamp in `completed_orders`.

## 3.5 Cook payments / earnings / payout touchpoints

- Dashboard earnings pulls vendor transfer totals if vendor Stripe account exists.
- `POST /api/v2/payments/vendor-transfer` currently returns **403 forbidden** for manual API use (reserved to admin automation).

---

## 4) miFoodi end-to-end journey (role_id=3)

## 4.1 Account role and profile

- Can switch role with `POST /api/v2/account/switch-role` (`role_id=3`) back to foodie context.
- Foodie profile uses same account endpoints:
  - `GET /api/v2/account/profile`
  - `PUT /api/v2/account/profile`

## 4.2 Discovery and kitchen exploration

- `GET /api/v2/discovery/filtered`
- `GET /api/v2/discovery/nearest`
- `GET /api/v2/discovery/top-rated`
- `GET /api/v2/discovery/recommended`
- `GET /api/v2/discovery/restaurants/{id}`

### Discovery behavior details

- Restaurant detail can compute distance when `lat/lon` are supplied and valid.
- Response includes `is_favourited`, certificate/gst context, images, timings, and cook summary details.

## 4.3 Favorites and personalization

Customer-only account routes:

- `GET /api/v2/account/favorites`
- `POST /api/v2/account/favorites/toggle`

Behavior:
- Favorites are paginated.
- Toggle returns current favorite flag.

## 4.4 Payments setup and payment history

Payments routes:

- `GET /api/v2/payments/cards`
- `POST /api/v2/payments/cards`
- `POST /api/v2/payments/checkout-session`
- `POST /api/v2/payments/intent`
- `POST /api/v2/payments/intent/confirm`

Customer history route:

- `GET /api/v2/account/payments/history`

### Payment transaction behavior details

- Customer Stripe account is auto-provisioned if missing.
- Add card requires `payment_method_id` starting `pm_`.
- Payment intent creation requires owned order (`order_id`) and foodie role.
- Payment intent confirm requires owned payment (`payment_id`) and foodie role.

## 4.5 Order history visibility (foodie)

- `GET /api/v2/account/orders`

Behavior:
- Supports `page`, `limit`, optional `status`, `from_date`, `to_date` filters.
- Status filtering is validated to allowed order states.

---

## 5) Mobile-app wiring reality vs backend availability

This section is critical for a true codebase match.

## 5.1 Backend endpoints actively called by mobile repositories

Called from `mobile-app/lib/repos/*`:

- Auth: `login`, `register`, `verifyOtp`, `password/reset`, `token/refresh`, `v2/logout`
- Cook: `v2/mikitchn/store`, `v2/mikitchn/editkitchen`, `v2/mymenu`, `v2/getcookingstyles`, `v2/getspecialdiets`, `v2/food/add`, `v2/food/editfood`, `v2/food/status/{id}`, `v2/kitchenorderrequest`, `v2/kitchenupcomingorders`, `v2/allorders`, `v2/updateorderstatus`
- Foodie: `v2/discovery/recommended`, `v2/discovery/top-rated`, `v2/discovery/nearest`, `v2/account/favorites`, `v2/account/favorites/toggle`, `v2/account/orders`, `v2/account/payments/history`, `v2/payments/cards`
- Shared/support: `v2/account/profile`, `v2/account/dashboard`, `v2/account/notification-preferences`, `v2/account/switch-role`, `v2/deleteimage`, `v2/editprofile`, `v2/mob-contact`, `support/ticket` create/get/reply, `app/version`

## 5.2 Backend capabilities present but not currently wired in mobile repos

Available in API routes but no direct call found in `mobile-app/lib/repos/*`:

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

## 5.3 Client call with no matching route in current `api.php`

- Mobile repository calls `v2/account/delete` (`DELETE` with POST fallback), but no `v2/account/delete` route is currently registered in `backend/routes/api.php`.

---

## 6) Journey gaps / constraints to avoid incorrect assumptions

- **Order creation route gap**: `OrderController::store` exists, but no active route maps to it in current `backend/routes/api.php`; therefore, “place new order” is **not route-wired in current API file**.
- **Live location tracking**: no dedicated live driver/order-tracking endpoint is registered in current `backend/routes/api.php`.
- **Manual vendor transfer by app user**: explicitly forbidden (`403`) via `v2/payments/vendor-transfer`.

---

## 7) Deprecated/compatibility endpoints relevant to journeys

- `GET /api/mobcontact` -> deprecated (`410`), points to `/api/v2/mob-contact`
- `GET /api/v1/mob-contact` -> sunset (`410`), points to `/api/v2/mob-contact`
- Method guard endpoints:
  - `GET /api/v1/food/status/{id}` -> `405` (must use POST)
  - `GET /api/v2/food/status/{id}` -> `405` (must use POST)
  - `GET /api/v2/payments/checkout-session` -> `405` (must use POST)

---

## 8) Consolidated E2E snapshots (strictly route-wired)

## 8.1 miCook E2E (current implementation)

Register/login/OTP -> switch to cook role -> optional cook onboarding start + vendor-account step -> create/edit kitchen -> manage food catalog -> handle incoming requests/upcoming/all orders -> update order status (requested/confirmed/completed/cancelled) -> monitor dashboard earnings.

## 8.2 miFoodi E2E (current implementation)

Register/login/OTP -> switch/keep foodie role -> discover kitchens (nearest/top-rated/recommended/filtered/detail) -> favorite/unfavorite kitchens -> view order history and payment history -> manage cards / checkout-intent APIs (backend-ready) -> use support ticket create/read/reply when needed.

