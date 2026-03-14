# User Journeys (Codebase-Aligned)

This document outlines practical end-to-end journeys currently implemented across the Mitabl backend (`backend/routes/api.php`), mobile app architecture (`docs/MOBILE_APP.md`), and platform summary (`README.md`).

## 1) miCook journey (cook/operator side)

### 1.1 Registration and login
1. Create account (`POST /api/register`).
2. Verify OTP (`POST /api/verifyOtp`) and optionally resend (`POST /api/resendotp`).
3. Login and obtain API token (`POST /api/login`), then use authenticated v2 APIs.

### 1.2 Role transition into cook onboarding
1. From authenticated account area, switch role (`POST /api/v2/account/switch-role`, `role_id=2`).
2. Start cook onboarding (`POST /api/v2/account/roles/cook/activate` or alias `POST /api/v2/account/onboarding/cook/start`).
3. Complete vendor-account onboarding step (`POST /api/v2/account/onboarding/cook/vendor-account`) when required.
4. If onboarding is incomplete, mobile should continue progressive steps using `role_transition` payload instead of blocking the whole flow.

### 1.3 Kitchen creation and profile setup
1. Create miKitchen (`POST /api/v2/mikitchn/store`).
2. Edit kitchen profile/details (`POST /api/v2/mikitchn/editkitchen`).
3. Delete kitchen image if needed (`POST /api/v2/deleteimage`).
4. View cook dashboard snapshot (`GET /api/v2/account/dashboard` and `GET /api/v2/getdashboarddata`).

### 1.4 Food catalog/menu management
1. View own menu (`GET /api/v2/mymenu`).
2. Add food item (`POST /api/v2/food/add`).
3. Edit food item (`POST /api/v2/food/editfood`).
4. Toggle item active/inactive status (`POST /api/v2/food/status/{id}`).
5. Delete item (`DELETE /api/v2/food/{id}`).

### 1.5 Order acceptance and fulfillment
1. See incoming requests (`GET /api/v2/kitchenorderrequest`).
2. See upcoming orders (`GET /api/v2/kitchenupcomingorders`).
3. See all kitchen orders (`GET /api/v2/allorders`).
4. Accept/decline/progress order status (`POST /api/v2/updateorderstatus`).

### 1.6 Payment and payout touchpoints for cook
1. Customer checkout/intent confirms payment collection on order side.
2. Vendor transfer endpoint supports payout flow (`POST /api/v2/payments/vendor-transfer`) as part of payment operations.

---

## 2) miFoodi journey (customer side)

### 2.1 Registration and account bootstrap
1. Register (`POST /api/register`).
2. OTP verify (`POST /api/verifyOtp`) and login (`POST /api/login`).
3. Access profile (`GET /api/v2/account/profile`) and update profile (`PUT /api/v2/account/profile`).

### 2.2 Discovery/search for miCook/miKitchen
1. Browse nearest kitchens (`GET /api/v2/discovery/nearest`).
2. Browse top-rated kitchens (`GET /api/v2/discovery/top-rated`).
3. Browse recommended kitchens (`GET /api/v2/discovery/recommended`).
4. Filter kitchens/foods (`GET /api/v2/discovery/filtered`).
5. Open kitchen details (`GET /api/v2/discovery/restaurants/{id}`).

### 2.3 Favorites and personalization
1. Fetch favorites (`GET /api/v2/account/favorites`).
2. Toggle favorite kitchens (`POST /api/v2/account/favorites/toggle`).

### 2.4 Payment setup and checkout
1. List saved cards (`GET /api/v2/payments/cards`).
2. Add card (`POST /api/v2/payments/cards`).
3. Create checkout session (`POST /api/v2/payments/checkout-session`) or payment intent (`POST /api/v2/payments/intent`).
4. Confirm intent when required (`POST /api/v2/payments/intent/confirm`).

### 2.5 Orders and tracking lifecycle
1. Place orders via authenticated order APIs (`customer` feature set in backend and mobile order modules).
2. Retrieve order history (`GET /api/v2/account/orders`).
3. Retrieve payment history (`GET /api/v2/account/payments/history`).
4. Receive push/notification updates during order progression (mobile app + backend notification flows).

---

## 3) Shared/platform journeys supporting both personas

### 3.1 Account and security lifecycle
- Password reset (`POST /api/password/reset`).
- Password change after login (`POST /api/v2/account/password/change`).
- Logout (`POST /api/v2/logout`).
- Device token registration for push (`POST /api/v2/account/device-token`).
- Notification controls (`POST /api/v2/account/notifications/toggle`, `POST /api/v2/account/notification-preferences`).

### 3.2 Support and issue resolution
- Create support ticket (`POST /api/support/ticket`).
- Read ticket (`GET /api/support/ticket/{id}`).
- Reply to ticket (`POST /api/support/ticket/{id}/reply`).

### 3.3 Health and runtime checks
- Public health probes: `/api/health`, `/api/health/live`, `/api/health/startup`, `/api/health/ready`.
- App version gate for mandatory/optional upgrades: `/api/app/version`.

---

## 4) Practical end-to-end snapshots

### 4.1 Full miCook E2E snapshot
Register -> OTP verify -> login -> switch to cook -> run onboarding (including vendor-account step when required) -> create kitchen -> add/edit menu -> receive incoming order requests -> update order status through fulfillment -> monitor dashboard and payout/payment operations.

### 4.2 Full miFoodi E2E snapshot
Register -> OTP verify -> login -> discover/filter kitchens -> view kitchen/menu -> add card/payment method -> place order and complete checkout -> receive order progress notifications -> review historical orders/payments -> use support ticket flow when needed.

---

## 5) Scope notes from current codebase

- The platform is dual-persona in one mobile app binary (Foodie + Cook).
- Legacy lead pre-registration intake is marked retired in platform documentation, while a throttled `/api/preregister` route still exists in API routes; active onboarding should follow normal account registration + cook onboarding endpoints.
