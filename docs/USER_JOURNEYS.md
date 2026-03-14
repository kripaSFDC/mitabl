# User Journeys (Codebase-Verified Deep Audit: miCook + miFoodi)

This document is a **detailed, implementation-matched journey specification** for miCook and miFoodi.
It is based on backend route wiring and current controller/service logic in this repository.

> **Strict interpretation rule used for this document**
> If behavior exists in a controller but no active route maps to it, that behavior is treated as **not client-available**.

---

## Source of truth audited

### API route and middleware wiring

- `backend/routes/api.php`

### Authentication, role, profile, onboarding

- `backend/app/Http/Controllers/Api/User/Concerns/HandlesUserAuthentication.php`
- `backend/app/Http/Controllers/Api/V2/AccountController.php`
- `backend/app/Services/AccountProfileService.php`

### Kitchen, menu, orders

- `backend/app/Http/Controllers/Api/MikitchnController.php`
- `backend/app/Http/Controllers/Api/FoodsController.php`
- `backend/app/Http/Controllers/Api/OrderController.php`
- `backend/app/Http/Controllers/Api/V2/AccountFoodieController.php`

### Discovery and payments

- `backend/app/Http/Controllers/Api/V2/DiscoveryController.php`
- `backend/app/Services/DiscoveryService.php`
- `backend/app/Http/Controllers/Api/V2/PaymentsController.php`

### Support flows

- `backend/app/Http/Controllers/Api/SupportTicketController.php`

### Mobile usage reality

- `mobile-app/lib/repos/*.dart`

---

## 1) Coverage verdict against requested checkpoints

## 1.1 miCook coverage

| Requested checkpoint | Status | Codebase reality |
|---|---|---|
| Registration | ✅ Implemented | Register + OTP + login fully route-wired. |
| Onboarding | ✅ Implemented | Role switch + cook onboarding start + cook vendor-account step route-wired. |
| Kitchen creation | ✅ Implemented | Create/update kitchen APIs route-wired and restaurant-gated. |
| Payments | ⚠️ Partial by design | Earnings are visible in dashboard; manual vendor transfer endpoint is forbidden (403). |
| Food catalog | ✅ Implemented | Add/edit/toggle/delete food and menu listing route-wired. |
| Order acceptance | ✅ Implemented | Requested/upcoming/all order list + status update route-wired. |

## 1.2 miFoodi coverage

| Requested checkpoint | Status | Codebase reality |
|---|---|---|
| Search miCook/miKitchn | ✅ Implemented as discovery/filter APIs | Nearest/top-rated/recommended/filtered/detail route-wired (no dedicated keyword endpoint). |
| Placing order | ❌ Not currently route-wired | `OrderController::store` exists but has no active API route registration. |
| Payment setup | ✅ Implemented | Cards + checkout-session APIs route-wired. |
| Payment execution | ✅ Implemented API-side | Intent create/confirm route-wired with foodie-role and ownership checks. |
| Location tracking | ❌ Not implemented as live tracking | No dedicated order-tracking endpoint; only geo distance in discovery/detail. |
| Historic orders | ✅ Implemented | Customer order history route with status/date filters route-wired. |

---

## 2) Platform roles, middleware boundaries, and route groups

### 2.1 Mobile roles

- miCook role: `role_id = 2`
- miFoodi role: `role_id = 3`

### 2.2 Auth/middleware boundaries in `/api/v2`

Most journey routes are under:

- middleware: `auth:api`
- middleware: `api.user.active`

Role-scoped route guards used inside v2:

- `restaurant` middleware for cook kitchen/menu/order operations
- `customer` middleware for foodie history/favorites operations

### 2.3 Legacy compatibility behavior retained

- Legacy mobile endpoints are mounted inside v2 via a shared registrar (`editprofile`, `mikitchn/*`, `food/*`, order list/status endpoints).
- This means mobile clients can still use legacy path names under `/api/v2/*` while migration continues.

---

## 3) Shared foundation journey (both personas)

## 3.1 Authentication lifecycle

Public routes:

1. `POST /api/login`
2. `POST /api/token/refresh`
3. `POST /api/register`
4. `POST /api/verifyOtp`
5. `POST /api/resendotp`
6. `POST /api/password/reset`

Authenticated route:

7. `POST /api/v2/logout`

### Auth behavior enforced by code

- Login blocks admin identity roles from mobile API usage.
- Login blocks suspended users.
- Mobile login only allows role ids 2/3.
- Unverified users are handled through OTP verification flow.
- Refresh token endpoint issues and persists replacement JWTs.

## 3.2 Profile, account, and preferences

Authenticated routes:

- `GET /api/v2/account/profile`
- `PUT /api/v2/account/profile`
- `POST /api/v2/editprofile` (legacy compatibility path)
- `POST /api/v2/account/password/change`
- `POST /api/v2/account/device-token`
- `POST /api/v2/account/notifications/toggle`
- `POST /api/v2/account/notification-preferences`
- `GET /api/v2/mob-contact`
- `GET /api/v2/account/mobile-contact`

## 3.3 Role switching and dual-persona readiness

- `POST /api/v2/account/switch-role`

Behavior highlights:

- Allowed target role ids: 2 or 3 only.
- Membership rows are auto-created if missing.
- Switching to cook ensures foodie membership/account readiness.
- Switching to foodie ensures customer Stripe account readiness.
- Response includes `role_transition` state and `onboarding_required` flag.

## 3.4 Support ticket journey (public + authenticated)

Routes:

- `POST /api/support/ticket`
- `GET /api/support/ticket/{id}`
- `POST /api/support/ticket/{id}/reply`

Behavior:

- Public access is possible using `X-Ticket-Token` on read/reply routes.
- Authenticated users can access their own tickets.
- Honeypot field check exists on intake route.
- Attachment handling and size validation are implemented.

---

## 4) miCook end-to-end journey (role_id=2)

## 4.1 Registration/login into mobile

Typical sequence:

1. `POST /api/register`
2. `POST /api/verifyOtp`
3. `POST /api/login`
4. (optional) `POST /api/token/refresh` during session renewal

## 4.2 Become a cook (role transition + onboarding)

Primary endpoints:

1. `POST /api/v2/account/switch-role` with `role_id=2`
2. `POST /api/v2/account/roles/cook/activate`
3. Alias also available: `POST /api/v2/account/onboarding/cook/start`
4. `POST /api/v2/account/onboarding/cook/vendor-account`

Onboarding model returned by backend:

- `state`
- `missing`
- `onboarding_required`
- `next_required_step`
- `checklist`
  - `vendor_account`
  - `kitchen_profile`
  - `certificate`
  - `payout_setup`

Membership status:

- Cook membership automatically transitions between onboarding/active based on effective checklist completion.

## 4.3 Kitchen creation and profile setup

Routes:

- `POST /api/v2/mikitchn/store`
- `POST /api/v2/mikitchn/editkitchen`
- `POST /api/v2/deleteimage`

Validation/business rules implemented:

- Create blocks if user already has kitchen (`409`).
- Update blocks if user has no kitchen (`404`).
- Required fields include kitchen identity/contact and `timings` string.
- `timings` must decode to JSON object containing `days` array.
- Geo fields validated (`lat` and `lng` range and pairing).
- Create requires images when no existing kitchen record.
- Certificate record is upserted when ABN/certificate context exists.
- Timing rows are normalized and upserted per day.
- Discovery cache invalidation runs after save.

## 4.4 Food catalog lifecycle

Routes:

- `GET /api/v2/mymenu`
- `GET /api/v2/getcookingstyles`
- `GET /api/v2/getspecialdiets`
- `POST /api/v2/food/add`
- `POST /api/v2/food/editfood`
- `POST /api/v2/food/status/{id}`
- `DELETE /api/v2/food/{id}`

Validation/business rules implemented:

- Create requires `food_name`, `cookingstyle`, `specialDiet[]`, `price`, and pictures.
- Edit requires `food_id` and ownership in the current cook kitchen.
- `specialDiet` is persisted as encoded integer array.
- Status endpoint toggles active/inactive state.

## 4.5 Incoming orders and fulfillment

Routes:

- `GET /api/v2/kitchenorderrequest`
- `GET /api/v2/kitchenupcomingorders`
- `GET /api/v2/allorders`
- `POST /api/v2/updateorderstatus`

Order state model in use:

- `0` legacy cancelled
- `1` completed
- `2` requested
- `3` confirmed
- `4` cancelled

Fulfillment behavior:

- Status update validates allowed states.
- Legacy cancelled (`0`) is normalized to cancelled (`4`) when updating.
- Update is ownership-gated (order owner or owning cook kitchen).
- Confirm (`3`) triggers payment intent confirmation and transactional payment/order updates.
- Complete (`1`) writes/upserts completion timestamp in `completed_orders`.

## 4.6 Cook dashboard, earnings, and payout touchpoints

Routes:

- `GET /api/v2/getdashboarddata` (legacy compatibility endpoint)
- `GET /api/v2/account/dashboard`
- `POST /api/v2/payments/vendor-transfer`

Behavior:

- Dashboard returns `total_earning`, `n_bookings`, `n_upcoming_bookings`.
- Earnings are derived from vendor transfer totals when vendor account exists.
- Manual vendor transfer endpoint is intentionally blocked (`403`) for app users.

---

## 5) miFoodi end-to-end journey (role_id=3)

## 5.1 Registration/login into foodie context

Typical sequence:

1. `POST /api/register` (role defaults to foodie if omitted)
2. `POST /api/verifyOtp`
3. `POST /api/login`
4. (optional) `POST /api/v2/account/switch-role` with `role_id=3`

## 5.2 Discover and explore kitchens

Routes:

- `GET /api/v2/discovery/filtered`
- `GET /api/v2/discovery/nearest`
- `GET /api/v2/discovery/top-rated`
- `GET /api/v2/discovery/recommended`
- `GET /api/v2/discovery/restaurants/{id}`

Discovery implementation details:

- Supports filtering with `cooking_styles`, `dine_in`, `take_away`.
- Geo-aware behavior uses `lat/lon` when valid.
- `nearest` requires valid coordinates; otherwise returns empty list.
- Responses include favorite annotation (`is_favourited`) for authenticated users.
- Restaurant detail includes certificate/gst/cook summary context.

Search precision note:

- There is no dedicated keyword text-search endpoint in current v2 routes.
- Search is currently list/filter/ranking based.

## 5.3 Favorites and personalization

Customer-only routes:

- `GET /api/v2/account/favorites`
- `POST /api/v2/account/favorites/toggle`

Behavior:

- Favorites listing is paginated.
- Toggle endpoint flips favorite state and returns current flag.

## 5.4 Order placement and payment flow reality

### Payment stack that exists and is route-wired

- `GET /api/v2/payments/cards`
- `POST /api/v2/payments/cards`
- `POST /api/v2/payments/checkout-session`
- `POST /api/v2/payments/intent`
- `POST /api/v2/payments/intent/confirm`

Payment behavior details:

- Customer Stripe account is auto-provisioned when missing.
- Add-card validates `payment_method_id` with `pm_` prefix.
- Create-intent requires foodie role and owned `order_id`.
- Confirm-intent requires foodie role and owned payment.

### Order creation gap (important)

- `OrderController::store` exists and validates full order payload, but no active route currently maps to it in `backend/routes/api.php`.
- Therefore, "place order" is **not currently route-available** despite existing controller logic.

## 5.5 History visibility

Customer-only routes:

- `GET /api/v2/account/orders`
- `GET /api/v2/account/payments/history`

Behavior:

- Both endpoints support pagination.
- Orders endpoint supports status/date filtering and status allow-list validation.
- Payment history supports status/date filtering and returns payment summaries.

## 5.6 Location tracking reality

- No dedicated real-time order tracking route exists in active API wiring.
- Current location support is limited to discovery/distance calculations.

---

## 6) Mobile app wiring vs backend capability matrix

## 6.1 Endpoints actively called from mobile repositories

Called in `mobile-app/lib/repos/*`:

- Auth: `login`, `register`, `verifyOtp`, `password/reset`, `token/refresh`, `v2/logout`
- Cook: `v2/mikitchn/store`, `v2/mikitchn/editkitchen`, `v2/mymenu`, `v2/getcookingstyles`, `v2/getspecialdiets`, `v2/food/add`, `v2/food/editfood`, `v2/food/status/{id}`, `v2/kitchenorderrequest`, `v2/kitchenupcomingorders`, `v2/allorders`, `v2/updateorderstatus`
- Foodie: `v2/discovery/recommended`, `v2/discovery/top-rated`, `v2/discovery/nearest`, `v2/account/favorites`, `v2/account/favorites/toggle`, `v2/account/orders`, `v2/account/payments/history`, `v2/payments/cards`
- Shared: `v2/account/profile`, `v2/account/dashboard`, `v2/account/notification-preferences`, `v2/account/switch-role`, `v2/deleteimage`, `v2/editprofile`, `v2/mob-contact`, `support/ticket` create/get/reply, `app/version`

## 6.2 Backend routes available but not currently called by mobile repos

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

## 6.3 Mobile call with no matching backend route

- Mobile repo calls `v2/account/delete` (delete account path), but this route is not currently registered in `backend/routes/api.php`.

---

## 7) Deprecated, sunset, and method-guard routes

- `GET /api/mobcontact` -> deprecated and returns `410`, directs to `/api/v2/mob-contact`
- `GET /api/v1/mob-contact` -> sunset endpoint returning `410`
- Method guard routes returning `405`:
  - `GET /api/v1/food/status/{id}` (must use POST)
  - `GET /api/v2/food/status/{id}` (must use POST)
  - `GET /api/v2/payments/checkout-session` (must use POST)

---

## 8) Consolidated end-to-end snapshots (strictly route-wired)

## 8.1 miCook current E2E

Register/login/OTP -> switch to cook role -> start/continue cook onboarding -> create/edit kitchen profile -> manage menu catalog -> review requested/upcoming/all orders -> accept/confirm/complete/cancel via status updates -> review dashboard earnings.

## 8.2 miFoodi current E2E

Register/login/OTP -> remain/switch to foodie role -> discover kitchens (nearest/top-rated/recommended/filtered/detail) -> favorite/unfavorite kitchens -> manage cards/payment setup -> view order/payment history -> create/read/reply support tickets.

> Note: direct order placement is blocked by missing route wiring for order creation.

---

## 9) Cleanup opportunities discovered during audit (no behavior changes made in this doc update)

1. Route gap: `OrderController::store` is implemented but unreachable due to missing route registration.
2. Client/backend mismatch: mobile calls `v2/account/delete` but backend does not expose it.
3. Maintainability cleanup candidates: typos and naming inconsistencies (`myUpcomingOrderss`, text typos like `Kitchecn`) can be normalized.
4. Optional product clarity: if keyword search or live tracking is expected, dedicated route contracts need to be added (currently absent).

