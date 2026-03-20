# Product + UX audit

## 1. Personas and roles

### micook
A micook is the supply-side persona: a person who sets up a kitchen (`mikitchn`), configures opening hours and optional dine-in slots, publishes menu items, receives incoming order requests, accepts or declines them, marks preparation progress, completes orders, receives customer reviews, and eventually gets paid out through Stripe vendor onboarding and post-completion transfer automation.

**Goals inferred from code**
- Create or continue a cook role from an existing account.
- Complete onboarding steps needed to become an active cook.
- Pass compliance and payout-readiness checks before kitchen activation.
- Maintain kitchen profile, compliance/certification details, and payout readiness.
- Publish dishes with schedule/service-type rules.
- Manage order lifecycle from request to completion.
- Review customer feedback and switch back to mifoodi when needed.

### mifoodi
A mifoodi is the demand-side persona: a person who signs up, verifies account access, browses discovery feeds, views kitchens and menus, saves favourites, builds a cart, chooses dine-in or take-away, selects a payment method, places orders, tracks order status, cancels before acceptance, and reviews completed experiences.

**Goals inferred from code**
- Create and verify a mobile customer account.
- Discover nearby, recommended, and top-rated kitchens.
- Filter or search based on location, date, and service type.
- Place an order with card or one-time Stripe payment method selection.
- View payment history and order history.
- Maintain profile, favourites, payment methods, and optionally activate micook onboarding.
- Handle app updates, support tickets, and account/security preferences from mobile settings.

### Additional roles discovered
- **Admin / platform admin / super admin**: present in Filament resources and role checks, but out of scope for mobile journeys.
- **Support / CRM operators**: implied by support ticket APIs, SLA escalation jobs, and admin resources.
- **System automation**: scheduled commands and background jobs perform vendor-transfer, support SLA escalation, and certificate outcome delivery.

## 2. End-to-end user journeys

## 2.1 micook key journeys

### Journey name: micook – onboarding and account creation
**Trigger:** A user selects the micook persona during sign-up, or an existing mifoodi taps the micook CTA from profile.

**Preconditions:**
- User has a mobile account and can authenticate.
- OTP verification succeeds after sign-up.
- For role switching from mifoodi, the user has a valid foodie membership.

**Happy path steps**
1. User selects the micook role in sign-up or starts cook activation from the foodie profile.
2. Backend creates or reuses a `user_roles` membership for role `2` with onboarding status.
3. Backend also ensures the same account has an active mifoodi role membership and a Stripe customer account, so dual-role use is possible.
4. If the user just completed sign-up as a cook, the dedicated cook profile setup screen asks for initial mikitchn details and images before normal dashboard usage.
5. App routes the authenticated user to cook-facing flows and opens cook profile or dashboard depending on current state.
6. User progresses through missing onboarding tasks: kitchen profile, certificate/compliance, and vendor payout account setup.
7. Once onboarding checklist is satisfied, role transition state becomes ready/active and the user can fully use micook screens.

**Alternative / edge paths**
- **Case: role disabled.** Switching or activation returns a disabled-role error and UI shows a support-oriented blocked message.
- **Case: onboarding incomplete.** The role exists but remains in onboarding; the app keeps showing “Continue micook setup” rather than enabling full switching.
- **Case: Stripe vendor provisioning fails.** Vendor account completion endpoint returns `provision_error`, so the account can remain partially onboarded.
- **Case: unsupported role or admin identity.** Mobile authentication excludes admin-only roles and rejects unsupported role combinations.

### Journey name: micook – profile setup and verification
**Trigger:** Newly activated micook opens cook profile or edit-kitchen flows.

**Preconditions:**
- User is authenticated.
- Cook role exists or cook onboarding has started.

**Happy path steps**
1. User opens cook profile/dashboard and loads `v2/account/profile` and dashboard data.
2. User edits personal profile fields: first name, last name, email, phone, description, avatar.
3. User creates a `mikitchn` with kitchen name, address, seat count, timings, phone, service mode flags, lat/lng, and images.
4. Backend validates timings JSON, phone format, and requires images on first kitchen creation.
5. Kitchen activation is effectively gated by kitchen data + certificate presence + vendor account state exposed in onboarding checklist logic.
6. If dine-in is enabled, user optionally configures structured dine-in slots within open hours.
7. Certificate/compliance data is stored alongside the kitchen, and later reviewed via admin workflows.
8. User completes Stripe vendor onboarding/account step to support payouts.

**Alternative / edge paths**
- **Case: kitchen already exists.** Create endpoint returns conflict and user must use edit-kitchen instead.
- **Case: no first/last name.** Kitchen creation fails because certificate owner name is required first.
- **Case: invalid phone.** Backend rejects non-international phone formats.
- **Case: dine-in schema not migrated.** Enabling dine-in or dine-in slots is blocked until the table exists.
- **Case: overlapping or out-of-hours dine-in slots.** Backend rejects slot definitions outside opening windows or overlapping on the same day.

### Journey name: micook – menu and dish creation / management
**Trigger:** User opens Menu tab and taps add/edit item.

**Preconditions:**
- Kitchen profile exists.
- Authenticated cook owns the kitchen.

**Happy path steps**
1. App loads current menu via `v2/mymenu` and reference data via `v2/getcookingstyles` and `v2/getspecialdiets`.
2. User creates or edits a food item with name, cooking style, special diets, price, description, images, and service type flags.
3. User can define one-off availability via `available_date` or recurring availability via `available_days`, plus optional time windows.
4. Backend validates food belongs to the cook’s kitchen and ensures at least one of dine-in or take-away is enabled.
5. Backend stores uploaded images, updates image arrays, and allows deleting prior images during edit.
6. User toggles item active/inactive state through `v2/food/status/{id}`.

**Alternative / edge paths**
- **Case: no kitchen yet.** Food creation is blocked with a kitchen-required error.
- **Case: no pictures on create.** Initial food create requires images.
- **Case: both `available_date` and recurring days supplied.** Backend rejects mutually exclusive scheduling modes.
- **Case: dish service type exceeds kitchen capabilities.** Dine-in or take-away cannot be enabled on a dish if the kitchen itself does not support that mode.

### Journey name: micook – receiving and managing orders
**Trigger:** A mifoodi places an order with the cook’s kitchen.

**Preconditions:**
- Cook owns a kitchen.
- Order is created in `requested` status.

**Happy path steps**
1. User opens Requests tab to see new requested orders (`status = requested`).
2. User reviews order details, items, service type, slot/time, and customer info.
3. To accept, cook updates status to `confirmed`.
4. During acceptance, backend checks cook ownership, verifies current status is requested, and confirms the payment intent if one exists or can be initialized from the stored payment reference.
5. For take-away orders only, cook may override delivery date/time during acceptance.
6. User can move confirmed orders to `in progress` and then to `completed`.
7. Completed orders create/update a `CompletedOrder` record for later payout automation.
8. Bookings screens separate requested, upcoming, and historical orders.

**Alternative / edge paths**
- **Case: order already completed.** Further status changes are blocked.
- **Case: cancelled order.** Cancelled orders cannot be moved to active states.
- **Case: no payment method selected yet.** Acceptance can fail because mifoodi must attach a payment method before cook acceptance.
- **Case: dine-in order.** Acceptance cannot override slot/time; original slot must remain.
- **Case: wrong actor.** Only the owning cook can accept, mark in-progress, or complete.

### Journey name: micook – cancellations and fulfilment exceptions
**Trigger:** Cook needs to cancel or cannot fulfil an order.

**Preconditions:**
- Cook can manage the order.

**Happy path steps**
1. Cook submits `status = cancelled` with a required cancellation comment.
2. Backend creates or updates `CancelReason` with actor metadata and default subject “Cancelled by micook” if no subject provided.
3. Order status is updated to cancelled.
4. `CancelOrderRefund` event is dispatched for refund processing or downstream handling.

**Alternative / edge paths**
- **Case: no cancel comment.** Cancellation is rejected.
- **Case: not owning cook.** Unauthorized.
- **Case: legacy cancelled state used by client.** Backend normalizes legacy status `0` into modern cancelled status `4`.

### Journey name: micook – payments and payouts
**Trigger:** Cook reaches vendor setup or completes orders that should settle later.

**Preconditions:**
- Cook role onboarding has started.
- Stripe vendor account provisioning is available.

**Happy path steps**
1. Cook completes vendor onboarding via account endpoints and Stripe connected-account flows.
2. When orders are accepted, the related payment intent is confirmed and order is marked paid.
3. After order completion, a `CompletedOrder` record is stored.
4. Scheduled command `orderpayment:cron` finds completed orders older than one day and emits `MakeOrderPaymentToVendor` automation events.
5. Admin/system automation, not mobile users, performs the actual vendor transfer action; direct mobile/API `vendor-transfer` is forbidden.

**Alternative / edge paths**
- **Case: vendor account missing.** Cook onboarding remains incomplete.
- **Case: payment already finalized.** Acceptance path skips redundant confirmation.
- **Case: manual transfer requested from mobile.** Endpoint returns 403; payouts are intentionally admin-automated.

### Journey name: micook – ratings, reviews, and customer assessment
**Trigger:** A completed order exists and cook wants to review the mifoodi or inspect received reviews.

**Preconditions:**
- Restaurant profile exists.
- Order is completed.

**Happy path steps**
1. Cook opens customer review page to inspect reviews left by mifoodi accounts.
2. Backend loads restaurant reviews filtered by `by_user = customer`.
3. Cook can also submit a review about the mifoodi tied to the completed order.
4. Backend ensures the target user is role `3` (foodie), ensures the order belongs to both the cook’s restaurant and target foodie, and enforces one kitchen-origin review per order.

**Alternative / edge paths**
- **Case: order not completed.** Review submission is blocked.
- **Case: mismatched foodie/order/restaurant.** Review submission is blocked.
- **Case: duplicate review per order.** Unique rule rejects the second submission.

### Journey name: micook – notifications and communication
**Trigger:** App launch, role switch, notification preference change, or support need.

**Preconditions:**
- Firebase is available for push.
- User is authenticated for backend sync of device token.

**Happy path steps**
1. App requests push permission and creates local notification channels.
2. Notification token is synced to backend using notification-preference endpoint.
3. Tapping notification payloads can route into screen flows.
4. Deep links can open cook profile or booking-related pages.
5. User can submit support tickets and follow replies through support ticket APIs.

**Alternative / edge paths**
- **Case: Firebase unavailable.** Notification service logs warning and skips initialization.
- **Case: unsupported deep link payload.** Service logs and safely ignores it.
- **Case: order deep link only contains ID.** App falls back to bookings list because order detail requires richer booking data.

## 2.2 mifoodi key journeys

### Journey name: mifoodi – onboarding and account creation
**Trigger:** User signs up as mifoodi or switches from cook back to mifoodi.

**Preconditions:**
- Mobile user has email/phone details needed for registration.

**Happy path steps**
1. User picks the mifoodi persona during sign-up.
2. App posts registration payload including `role_id = 3`.
3. User receives OTP and verifies via the OTP screen.
4. Authentication state is established and app routes the user to `/HomePage`.
5. App fetches foodie profile and available roles.

**Alternative / edge paths**
- **Case: cook account also has foodie membership.** Switching is instant if foodie membership is active.
- **Case: OTP failure or expired code.** User must retry or resend OTP.
- **Case: admin or unsupported identity role.** Mobile auth is rejected server-side.

### Journey name: mifoodi – splash, update gate, and authenticated app entry
**Trigger:** App launch or cold start.

**Preconditions:**
- Mobile app is installed.

**Happy path steps**
1. Splash screen appears immediately on launch.
2. App calls the backend app-version endpoint during the splash window.
3. If backend says the running version is below `minimum`, a non-dismissible forced-update modal is shown.
4. If backend says a newer `latest` exists but current version still meets minimum, an optional update modal is shown.
5. In parallel, authentication state resolves; authenticated users are routed to HomePage or DashboardCook based on active role, while unknown users fall back to LandingPage after a timer.

**Alternative / edge paths**
- **Case: update endpoint fails.** The check fails silently and app startup continues.
- **Case: required update.** User cannot dismiss the dialog without leaving to update.
- **Case: auth state stays unknown.** Splash fallback timer sends user to LandingPage after ~3 seconds.

### Journey name: mifoodi – browsing and searching for kitchens / dishes
**Trigger:** User lands on home screen or opens a kitchen detail screen.

**Preconditions:**
- Authenticated mifoodi account.

**Happy path steps**
1. Home screen loads recommended, top-rated, and nearby kitchen lists.
2. User can open filters and apply location/date/service-type constraints.
3. Search/discovery endpoints support nearest, top-rated, recommended, filtered, and text search experiences.
4. User taps a kitchen card to open detail/menu flow.
5. Kitchen detail includes images, rating average, favourite state, kitchen profile, certificate/GST summary, active foods, and optional dine-in slots.
6. Menu endpoint filters dishes by requested date/time and service type.

**Alternative / edge paths**
- **Case: offline/network failure.** Home modules display offline retry widgets.
- **Case: no menu available for selected time/date.** Menu list is empty but kitchen still loads.
- **Case: invalid location/date params.** Backend returns validation errors.

### Journey name: mifoodi – favourites management
**Trigger:** User saves or unsaves a kitchen.

**Preconditions:**
- Authenticated mifoodi account.

**Happy path steps**
1. User toggles favourite on a kitchen card/detail screen.
2. App posts `restaurant_id` to favourites toggle endpoint.
3. User can open dedicated favourites screen to browse saved kitchens with pagination.

**Alternative / edge paths**
- **Case: restaurant deleted or missing.** Toggle returns 404.
- **Case: no favourites yet.** Screen renders no-data state.

### Journey name: mifoodi – cart building and checkout preparation
**Trigger:** User opens a kitchen and starts adding dishes.

**Preconditions:**
- Kitchen detail is available.
- At least one menu item is available for selected service/date.

**Happy path steps**
1. User opens `/OrderMenu` for a kitchen.
2. App loads kitchen summary plus menu items.
3. User adds/removes items, and floating cart CTA appears when quantity > 0.
4. In cart screen, user chooses exactly one service mode: dine-in or take-away.
5. User selects date.
6. If dine-in, user must choose guests and a valid dine-in slot.
7. If take-away, user must choose a time window.
8. Session controller computes totals and enables “Review order” only when required selections are complete.

**Alternative / edge paths**
- **Case: cart empty.** Cart screen shows empty state.
- **Case: dine-in slots loading or unavailable.** UI shows loading/selection issues; checkout cannot proceed.
- **Case: service mode unsupported by kitchen.** Choice chips only show supported modes.

### Journey name: mifoodi – payments and order confirmation
**Trigger:** User reaches checkout and submits the order.

**Preconditions:**
- Cart/session data is valid.
- Authenticated foodie account.

**Happy path steps**
1. Checkout screen loads saved cards from Stripe-backed customer account.
2. If cards exist, the first saved card may be auto-selected.
3. User can launch external Stripe setup flow to add a card or use a one-time payment method via embedded web flow.
4. App posts order creation payload to `v2/account/orders` including kitchen, time, taxes, items, service mode, guests/slot if dine-in, and optional payment selection (`card_id` or `payment_method_id`).
5. Backend creates order in requested state and optionally initializes payment intent immediately.
6. If payment method is attached later, app can call `v2/payments/intent` to attach it to an existing order.
7. Server calculates totals itself, including GST where enabled and an automatic 50.00 discount for users with fewer than five completed orders.
8. Backend also supports an optional `promo_code` id, although no visible mifoodi promo-entry UI surfaced in the scanned mobile flows.
9. Order remains pending until cook acceptance triggers payment confirmation.

**Alternative / edge paths**
- **Case: both dine-in and take-away selected or neither.** Backend rejects request.
- **Case: dine-in without persons/slot.** Backend rejects request.
- **Case: take-away without time window.** Backend rejects request.
- **Case: promo invalid or expired.** Backend rejects request.
- **Case: payment method belongs to another customer.** Stripe/PaymentService rejects it.
- **Case: saved cards fail to load.** Checkout shows error and refresh path.
- **Case: introductory-discount expectation mismatch.** Backend may apply discount automatically even if the mobile UI does not explicitly explain the rule.

### Journey name: mifoodi – order tracking and cancellation
**Trigger:** User opens miOrders screen after placing one or more orders.

**Preconditions:**
- User is in mifoodi role or can switch back to mifoodi.

**Happy path steps**
1. MiOrders screen fetches paginated account order history.
2. User sees order states including requested, confirmed, in progress, completed, and cancelled.
3. If needed and still allowed, user cancels an order by posting status `4` plus `cancel_comment`.
4. Backend records cancellation reason, normalizes actor type to customer, updates order state, and dispatches refund event handling.

**Alternative / edge paths**
- **Case: current role is cook.** Screen offers “Switch to mifoodi” CTA and retries after role switch.
- **Case: mifoodi tries to cancel after cook accepted.** Backend blocks it; mifoodi can only cancel in requested state.
- **Case: offline.** Orders screen shows retry widgets.

### Journey name: mifoodi – payment history and saved cards
**Trigger:** User opens payments screen.

**Preconditions:**
- Mifoodi role is active or recoverable by switch.

**Happy path steps**
1. App fetches payment history from account endpoint with optional paging.
2. User sees amount, order linkage, payment status, card reference, and confirmation timestamps.
3. User can manage/add cards through Stripe setup flow.

**Alternative / edge paths**
- **Case: wrong active role.** Payments screen shows a role-switch CTA.
- **Case: Stripe customer account missing.** Backend attempts to provision one; failures surface as 422 errors.

### Journey name: mifoodi – ratings and reviews
**Trigger:** A completed order exists.

**Preconditions:**
- Authenticated mifoodi owns the order.
- Order status is completed.

**Happy path steps**
1. User submits restaurant review with text, tags, rating, restaurant ID, and order ID.
2. Backend verifies ownership, restaurant linkage, completion status, and one review per order from customer side.
3. Review is stored with `by_user = customer` and becomes visible in kitchen review displays.

**Alternative / edge paths**
- **Case: non-completed order.** Review is rejected.
- **Case: wrong restaurant or order.** Review is rejected.
- **Case: duplicate review.** Unique validation blocks it.

### Journey name: mifoodi – notifications, support, and loyalty-like extras
**Trigger:** Push notification arrives, user opens support, or browses account options.

**Preconditions:**
- Authenticated app session.

**Happy path steps**
1. Device token and notification preference are synced to backend.
2. Notification tap routes into supported screens.
3. User can submit support tickets, fetch ticket status, and reply.
4. User can browse payments, favourites, and profile, which function as retention/account-management surfaces.

**Alternative / edge paths**
- **Case: no explicit loyalty/referral implementation found.** No concrete customer rewards system was visible in analyzed mobile/backend paths.
- **Case: support SLA escalation.** Backend jobs imply unresolved tickets can be escalated even if mobile UI remains simple.

### Journey name: shared – account settings, support, and security controls
**Trigger:** User opens cook settings or security/support related surfaces.

**Preconditions:**
- Authenticated session.

**Happy path steps**
1. User opens settings and can toggle push notifications.
2. App persists the local preference and syncs it to backend.
3. User can enable biometric lock if the device supports it.
4. User can open FAQ web content, create support tickets, load ticket status, and reply to existing tickets.
5. User can attempt account deletion from settings.

**Alternative / edge paths**
- **Case: biometrics unavailable.** App keeps the toggle off and shows an explanatory snackbar.
- **Case: support ticket access without auth.** Support repository can also rely on a ticket token header for retrieval/reply.
- **Case: account deletion.** Mobile contains a delete-account action, but the scanned backend route file does not expose `/api/v2/account/delete`, so this flow may currently be incomplete or environment-specific.

## 3. Screen-by-screen breakdown (mobile app)

| Screen / route | Personas | Entry points | Exit points | Data displayed | Main actions / backend calls |
|---|---|---|---|---|---|
| `/Splash` | shared | cold start | LandingPage, HomePage, DashboardCook, update modal | brand splash and startup state | `GET /api/app/version`, auth bootstrap, timed fallback to landing |
| update gate modal | shared | Splash when backend signals optional/required upgrade | app store, dismiss for optional updates | latest/minimum version requirement and store links | `GET /api/app/version`, external store launch |
| biometric lock page | shared authenticated | app resume when biometric lock enabled | previous route after unlock | device-auth prompt UI | local biometric auth only |
| `/LandingPage` | shared unauthenticated | app launch, logout | Login, Sign up | marketing / persona entry choices | navigate only |
| `/LoginPage` | shared unauthenticated | landing | HomePage or DashboardCook after auth, Forgot | email/password fields | `POST /api/login`, token refresh support, route by active role |
| `/SignUpPage` | shared unauthenticated | landing | OTP | role selection, account fields | `POST /api/register` with selected `role_id` |
| `/OTPPage` | shared unauthenticated | Sign up / auth verification | HomePage, DashboardCook | OTP input | `POST /api/verifyOtp`, resend OTP |
| `/ForgotPage` | shared unauthenticated | Login | back to Login | password reset email form | `POST /api/password/reset` |
| `/HomePage` | mifoodi | post-login, role switch back to foodie | ProfileFoodie, filters, kitchen/menu flows | nearby, recommended, top-rated kitchens; profile banner | `GET /api/v2/discovery/recommended`, `/top-rated`, `/nearest`, plus foodie profile fetch |
| `/ProfileFoodie` | mifoodi | HomePage profile button | EditProfileFoodie, HomePage, role switch / cook onboarding | user details, micook CTA state, profile summary | `GET /api/v2/account/profile`, `POST /api/v2/account/switch-role`, `POST /api/v2/account/roles/cook/activate`, `POST /api/v2/account/onboarding/cook/vendor-account` |
| `/EditProfileFoodie` | mifoodi | ProfileFoodie | back to profile | editable user fields, avatar | `POST /api/v2/editprofile` multipart |
| `/Favourites` | mifoodi | foodie account area | OrderMenu or kitchen detail flows | paginated saved kitchens | `GET /api/v2/account/favorites`, `POST /api/v2/account/favorites/toggle` |
| `/MiOrders` | mifoodi | foodie account area | order status/cancel actions, role-switch CTA | paginated customer orders | `GET /api/v2/account/orders`, `POST /api/v2/updateorderstatus` for cancellation |
| `/Payments` | mifoodi | foodie account area | Stripe setup / refresh | payment history, saved cards, role-switch CTA | `GET /api/v2/account/payments/history`, `GET /api/v2/payments/cards`, `POST /api/v2/payments/checkout-session`, `POST /api/v2/payments/cards` |
| `/OrderMenu` | mifoodi | kitchen card / deep link into cook profile then kitchen | OrderCart | kitchen hero, menu items, availability, service choices | `GET /api/v2/discovery/restaurants/{id}`, `GET /api/v2/discovery/restaurants/{id}/menu` |
| `/OrderCart` | mifoodi | OrderMenu | OrderCheckout | cart lines, selected service/date/time/slot, totals | `GET /api/v2/discovery/restaurants/{id}/dine-in-slots` as needed |
| `/OrderCheckout` | mifoodi | OrderCart | order confirmation result / refresh card flow | order recap, address, payment methods | `GET /api/v2/payments/cards`, `POST /api/v2/account/orders`, `POST /api/v2/payments/intent`, Stripe payment-method web entry |
| `/DashboardCook` | micook | post-login or role switch | bottom nav tabs | tab shell for dashboard/menu/requests/profile | local tab navigation; profile fetch on init |
| cook dashboard tab (`HomePageCook`) | micook | DashboardCook | Bookings, UpcomingBookings, settings-related routes | KPIs / dashboard data | `GET /api/v2/account/dashboard` |
| cook menu tab (`MenuPage`) | micook | DashboardCook | AddMenuPage, MenuDetails | current menu list, availability/status | `GET /api/v2/mymenu`, `POST /api/v2/food/status/{id}` |
| `/AddMenuPage` | micook | MenuPage, MenuDetails edit | MenuPage | dish form, images, special diets, cooking styles | `GET /api/v2/getcookingstyles`, `GET /api/v2/getspecialdiets`, `POST /api/v2/food/add`, `POST /api/v2/food/editfood` |
| `/MenuDetails` | micook | MenuPage | edit / back | single menu item details | uses menu item data, routes to edit |
| cook requests tab (`RequestsPage`) | micook | DashboardCook | OrderDetails | new requested orders | `GET /api/v2/kitchenorderrequest` |
| `/OrderDetails` | micook | Requests or bookings list | update state / review customer | order items, customer info, status actions | `POST /api/v2/updateorderstatus`, later review submission |
| `/Bookings` | micook | dashboard/bookings navigation | OrderDetails, UpcomingBookings | historical/completed/cancelled booking lists | `GET /api/v2/allorders` |
| `/UpcomingBookings` | micook | dashboard/bookings navigation | OrderDetails | confirmed/in-progress future bookings | `GET /api/v2/kitchenupcomingorders` |
| `/ProfileCook` / cook profile tab | micook | DashboardCook | EditProfileCook, EditKitchenProfile, SettingsCook, switch to mifoodi | personal profile, kitchen summary, role switch CTA | `GET /api/v2/account/profile`, `POST /api/v2/account/switch-role` |
| `/EditProfileCook` | micook | ProfileCook | back to profile | editable cook identity fields | `POST /api/v2/editprofile` multipart |
| `/EditKitchenProfile` | micook | ProfileCook | back to profile | kitchen fields, timings, service modes, images, dine-in slots | `POST /api/v2/mikitchn/editkitchen`, `POST /api/v2/deleteimage`, `GET /api/v2/mikitchn/dine-in-slots` |
| `/CookProfile` | shared, mostly mifoodi viewing cook | deep link `/cook/{id}` or kitchen browse | OrderMenu | public-ish cook/kitchen profile | discovery restaurant detail endpoints |
| `/CustomerReviewPage` | micook | bookings/order details | back to bookings/profile | received reviews and/or review form | `GET` review listing endpoints, `POST` foodie review submission |
| `/SettingsCook` | micook | cook profile | logout, FAQ/web views, support, delete-account attempt | notification toggle, biometric toggle, support forms, help links | `POST /api/v2/account/notification-preferences`, support ticket endpoints, logout, mobile delete-account attempt |
| FAQ web view | shared by role context | settings | return to settings | hosted FAQ/help content | web only |
| Stripe payment-method web view | mifoodi | OrderCheckout | return to checkout | embedded secure payment-method collection form | `GET /api/v2/payments/payment-method-entry` |
| support actions (bottom sheet / form) | shared in current app shell, exposed from cook settings | SettingsCook | back to settings | support ticket intake, lookup, and reply forms | `POST /api/support/ticket`, `GET /api/support/ticket/{id}`, `POST /api/support/ticket/{id}/reply` |

## 4. Backend feature map

### App startup and version governance
- `GET /api/app/version`: controls forced vs optional mobile upgrade prompts using config-only minimum/latest versions and store URLs.

### Authentication and session management
- `POST /api/login`: mobile login, role-aware routing, unsupported-role rejection.
- `POST /api/token/refresh`: token refresh for mobile sessions.
- `POST /api/register`: sign-up with mobile role selection.
- `POST /api/verifyOtp`, `POST /api/resendotp`: OTP verification and resend.
- `POST /api/password/reset`: password reset initiation.
- `POST /api/v2/logout`: authenticated logout.

### Account profile and role orchestration
- `GET /api/v2/account/profile`: shared profile endpoint for both personas.
- `PUT /api/v2/account/profile`: update identity/profile fields.
- `POST /api/v2/account/switch-role`: move between mifoodi and micook when memberships allow it.
- `POST /api/v2/account/roles/cook/activate` and `/onboarding/cook/start`: create/continue cook onboarding.
- `POST /api/v2/account/onboarding/cook/vendor-account`: progress vendor payout step.
- `POST /api/v2/account/password/change`: password change.
- `POST /api/v2/account/device-token`: device token update.
- `POST /api/v2/account/notifications/toggle` and `/notification-preferences`: notification preference updates.
- `GET /api/v2/account/mobile-contact` and `/api/v2/mob-contact`: support/contact details surface.

### Discovery and shopping
- `GET /api/v2/discovery/filtered`: generic filtered kitchen list.
- `GET /api/v2/discovery/nearest`: location-sensitive nearby kitchens.
- `GET /api/v2/discovery/top-rated`: rating-based ranking.
- `GET /api/v2/discovery/recommended`: recommendation feed.
- `GET /api/v2/discovery/search`: keyword search.
- `GET /api/v2/discovery/restaurants/{id}`: kitchen detail with foods, ratings, GST/certificate summary, favourite state, optional distance.
- `GET /api/v2/discovery/restaurants/{id}/menu`: date/time/service-type filtered menu.
- `GET /api/v2/discovery/restaurants/{id}/dine-in-slots`: dine-in slot availability by date/person count.

### Kitchen profile and menu management (micook)
- `POST /api/v2/mikitchn/store`: create kitchen.
- `POST /api/v2/mikitchn/editkitchen`: edit kitchen.
- `POST /api/v2/deleteimage`: delete kitchen image.
- `GET /api/v2/mikitchn/dine-in-slots`: fetch cook’s configured slots.
- `GET /api/v2/mymenu`: fetch own menu.
- `POST /api/v2/food/add`: create food item.
- `POST /api/v2/food/editfood`: edit food item.
- `DELETE /api/v2/food/{id}`: delete food item.
- `POST /api/v2/food/status/{id}`: activate/deactivate item.
- `GET /api/v2/getcookingstyles`, `GET /api/v2/getspecialdiets`: menu reference metadata.
- `GET /api/v2/account/dashboard`: cook dashboard summary.

### Ordering lifecycle
- `POST /api/orders` and `POST /api/v2/orders` / `POST /api/v2/account/orders`: create order for customer flows.
- `POST /api/v2/updateorderstatus`: central state-transition endpoint for accept, in-progress, complete, cancel.
- `GET /api/v2/kitchenorderrequest`: cook requested orders.
- `GET /api/v2/kitchenupcomingorders`: cook accepted future orders.
- `GET /api/v2/allorders`: cook historical/completed/cancelled orders.
- `GET /api/v2/account/orders`: foodie order history with status/date filters.

### Payment features
- `GET /api/v2/payments/cards`: retrieve saved cards for foodie Stripe customer.
- `POST /api/v2/payments/cards`: add card by Stripe payment method ID.
- `POST /api/v2/payments/checkout-session`: start secure Stripe setup session.
- `GET /api/v2/payments/payment-method-entry`: hosted/embedded one-time payment-method capture form.
- `POST /api/v2/payments/intent`: attach/initialize order payment intent.
- Payment/order services also apply an automatic introductory discount (50.00) to users with fewer than five completed orders, independent of promo-code support.
- `POST /api/v2/payments/intent/confirm`: explicit payment intent confirmation.
- `GET /api/v2/account/payments/history`: foodie payment history.
- Vendor-related endpoints under `/api/v2/payments/vendor/*`: vendor bank account retrieval, onboarding links, login links, account completion, refresh. Direct `vendor-transfer` is blocked from mobile.
- `POST /api/stripe/webhook`: Stripe event ingestion.

### Reviews and favourites
- `GET /api/v2/account/favorites`: foodie favourites list.
- `POST /api/v2/account/favorites/toggle`: save/unsave kitchen.
- Restaurant review creation/listing and foodie review creation exist in `ReviewController`; these power customer-review and mutual-review flows even if route exposure is partly legacy or indirect.

### Support and communication
- `POST /api/support/ticket`: create support ticket, with optional order/kitchen context and attachments.
- `GET /api/support/ticket/{id}`: fetch ticket state.
- `POST /api/support/ticket/{id}/reply`: reply to ticket.
- Push token + notification preference endpoints support outbound mobile notifications.

### Scheduled / background features
- `orderpayment:cron`: emits payout-to-vendor events for orders completed more than one day earlier.
- `ProcessSupportTicketSlaEscalationJob`: escalates unresolved support tickets on SLA breaches.
- `SendCertificateReviewOutcomeJob`: sends approved/rejected certificate emails and notifications to cooks.
- Additional repair / policy / health commands imply ongoing operational automation around roles and platform monitoring.

## 5. Consolidated feature list

### Feature: shared – startup version gate and safe app entry
- **Personas:** micook, mifoodi
- **Description:** Splash flow checks backend minimum/latest app versions, shows required/optional update prompts, and safely falls back to landing if auth state remains unresolved.
- **Journeys:** mifoodi splash, shared app entry
- **Screens:** Splash, update gate modal
- **Endpoints:** `/api/app/version`

### Feature: shared – mobile authentication and OTP verification
- **Personas:** micook, mifoodi
- **Description:** Register, log in, verify OTP, reset password, refresh token, and route into the correct role-specific home.
- **Journeys:** both onboarding journeys
- **Screens:** LandingPage, LoginPage, SignUpPage, OTPPage, ForgotPage
- **Endpoints:** `/api/register`, `/api/login`, `/api/verifyOtp`, `/api/resendotp`, `/api/password/reset`, `/api/token/refresh`

### Feature: shared – dual-role account membership and switching
- **Personas:** micook, mifoodi
- **Description:** One user account can hold both foodie and cook memberships, with onboarding/active/disabled states and role-based switching.
- **Journeys:** micook onboarding, mifoodi return-from-cook, cook/profile role switching
- **Screens:** ProfileFoodie, ProfileCook
- **Endpoints:** `/api/v2/account/profile`, `/api/v2/account/switch-role`, `/api/v2/account/roles/cook/activate`, `/api/v2/account/onboarding/cook/start`

### Feature: micook – kitchen onboarding and management
- **Personas:** micook
- **Description:** Create/edit kitchen profile, timings, address, seats, service modes, images, coordinates, compliance fields, and optional dine-in slots.
- **Journeys:** micook profile setup and verification
- **Screens:** CookProfile onboarding, EditKitchenProfile
- **Endpoints:** `/api/v2/mikitchn/store`, `/api/v2/mikitchn/editkitchen`, `/api/v2/deleteimage`, `/api/v2/mikitchn/dine-in-slots`

### Feature: micook – personal profile management
- **Personas:** micook
- **Description:** Update identity/contact fields, description, avatar, and notification/security preferences.
- **Journeys:** micook profile setup, notifications and communication
- **Screens:** ProfileCook, EditProfileCook, SettingsCook
- **Endpoints:** `/api/v2/account/profile`, `/api/v2/editprofile`, `/api/v2/account/notification-preferences`, `/api/v2/logout`

### Feature: micook – menu catalog management
- **Personas:** micook
- **Description:** Create/edit/delete menu items, upload photos, set price and dietary metadata, define service-type availability, and schedule dishes by date/day/time.
- **Journeys:** micook menu and dish creation / management
- **Screens:** MenuPage, AddMenuPage, MenuDetails
- **Endpoints:** `/api/v2/mymenu`, `/api/v2/getcookingstyles`, `/api/v2/getspecialdiets`, `/api/v2/food/add`, `/api/v2/food/editfood`, `/api/v2/food/{id}`, `/api/v2/food/status/{id}`

### Feature: micook – dashboard and order inbox
- **Personas:** micook
- **Description:** View dashboard KPIs, requested orders, upcoming accepted bookings, and historical bookings.
- **Journeys:** micook receiving and managing orders
- **Screens:** DashboardCook, RequestsPage, Bookings, UpcomingBookings, OrderDetails
- **Endpoints:** `/api/v2/account/dashboard`, `/api/v2/kitchenorderrequest`, `/api/v2/kitchenupcomingorders`, `/api/v2/allorders`

### Feature: micook – order state management
- **Personas:** micook
- **Description:** Accept requested orders, optionally adjust take-away acceptance windows, mark in progress, complete, or cancel with reasons.
- **Journeys:** micook receiving and managing orders; micook cancellations and fulfilment exceptions
- **Screens:** RequestsPage, OrderDetails, Bookings, UpcomingBookings
- **Endpoints:** `/api/v2/updateorderstatus`

### Feature: micook – vendor onboarding and payout readiness
- **Personas:** micook
- **Description:** Provision Stripe connected account, complete vendor setup, retrieve onboarding/login/account status, and receive delayed settlement through automation.
- **Journeys:** micook payments and payouts
- **Screens:** ProfileFoodie micook CTA continuation, cook onboarding/profile flows
- **Endpoints:** `/api/v2/account/onboarding/cook/vendor-account`, `/api/v2/payments/vendor/*`

### Feature: micook – reviews of mifoodi and receipt of customer ratings
- **Personas:** micook
- **Description:** Inspect customer reviews left on the kitchen and leave one review per completed order for the associated mifoodi.
- **Journeys:** micook ratings and reviews
- **Screens:** CustomerReviewPage, OrderDetails
- **Endpoints:** review controller endpoints for restaurant reviews and foodie reviews

### Feature: mifoodi – discovery and browse
- **Personas:** mifoodi
- **Description:** Browse recommended, top-rated, nearby, filtered, and searched kitchens, with date/time/service filtering and kitchen detail pages.
- **Journeys:** browsing and searching for kitchens / dishes
- **Screens:** HomePage, filters dialog, CookProfile, OrderMenu
- **Endpoints:** `/api/v2/discovery/recommended`, `/nearest`, `/top-rated`, `/filtered`, `/search`, `/restaurants/{id}`, `/restaurants/{id}/menu`, `/restaurants/{id}/dine-in-slots`

### Feature: mifoodi – favourites
- **Personas:** mifoodi
- **Description:** Save kitchens, remove them, and browse a paginated saved list.
- **Journeys:** favourites management
- **Screens:** HomePage, Favourites, kitchen cards/details
- **Endpoints:** `/api/v2/account/favorites`, `/api/v2/account/favorites/toggle`

### Feature: mifoodi – cart and service selection
- **Personas:** mifoodi
- **Description:** Build cart, choose dine-in vs take-away, select date/time, party size, and dine-in slot before checkout.
- **Journeys:** cart building and checkout preparation
- **Screens:** OrderMenu, OrderCart
- **Endpoints:** `/api/v2/discovery/restaurants/{id}`, `/api/v2/discovery/restaurants/{id}/menu`, `/api/v2/discovery/restaurants/{id}/dine-in-slots`

### Feature: shared – settings, support, and biometric lock
- **Personas:** micook, mifoodi (current UI exposure is strongest on cook settings)
- **Description:** Manage notification preference, biometric lock, FAQ/help content, support ticket create/read/reply, and an account-delete attempt from settings.
- **Journeys:** shared account settings, support, and security controls
- **Screens:** SettingsCook, BiometricLockPage, FAQ web view, support sheet
- **Endpoints:** `/api/v2/account/notification-preferences`, `/api/support/ticket`, `/api/support/ticket/{id}`, `/api/support/ticket/{id}/reply`, mobile attempt to `/api/v2/account/delete`

### Feature: mifoodi – checkout and payment method selection
- **Personas:** mifoodi
- **Description:** Review order, load saved cards, add cards through Stripe, use one-time payment methods, and create orders with attached payment references.
- **Journeys:** payments and order confirmation
- **Screens:** OrderCheckout, StripePaymentMethodPage, external Stripe setup flow
- **Endpoints:** `/api/v2/payments/cards`, `/api/v2/payments/checkout-session`, `/api/v2/payments/payment-method-entry`, `/api/v2/account/orders`, `/api/v2/payments/intent`, `/api/v2/payments/intent/confirm`

### Feature: mifoodi – order history and cancellation
- **Personas:** mifoodi
- **Description:** Browse orders, inspect status progression, and cancel only before cook acceptance.
- **Journeys:** order tracking and cancellation
- **Screens:** MiOrders
- **Endpoints:** `/api/v2/account/orders`, `/api/v2/updateorderstatus`

### Feature: mifoodi – profile and cross-role activation
- **Personas:** mifoodi
- **Description:** Edit foodie profile and start or continue micook activation from the same account.
- **Journeys:** mifoodi onboarding, notifications/support, micook activation
- **Screens:** ProfileFoodie, EditProfileFoodie
- **Endpoints:** `/api/v2/account/profile`, `/api/v2/editprofile`, `/api/v2/account/switch-role`, `/api/v2/account/roles/cook/activate`

### Feature: mifoodi – payment history and saved cards
- **Personas:** mifoodi
- **Description:** View payment records linked to orders and maintain saved cards.
- **Journeys:** payment history and saved cards
- **Screens:** Payments
- **Endpoints:** `/api/v2/account/payments/history`, `/api/v2/payments/cards`, `/api/v2/payments/checkout-session`

### Feature: mifoodi – restaurant reviews
- **Personas:** mifoodi
- **Description:** Leave one post-completion review per order for the visited kitchen.
- **Journeys:** ratings and reviews
- **Screens:** order history / review entry surfaces
- **Endpoints:** review controller restaurant-review endpoint(s)

### Feature: shared – push notifications and deep linking
- **Personas:** micook, mifoodi
- **Description:** Register device tokens, respect notification preferences, present local notifications in foreground, and route notification/deep-link payloads into supported screens.
- **Journeys:** notifications and communication for both personas; mifoodi splash/app entry
- **Screens:** app shell, Splash, cook/booking entry routes
- **Endpoints:** `/api/v2/account/notification-preferences`, `/api/v2/account/device-token`

## 6. Gaps, risks, and questions

1. **Payment confirmation timing is unusual.** Orders can be created before payment is fully confirmed; final confirmation happens when the cook accepts. Product should confirm whether this intentional “authorize/confirm on acceptance” behavior matches business expectations, especially for customer messaging and cook trust.
2. **Customer cancellation is intentionally narrow.** mifoodi can cancel only while order status is still `requested`. If support policy should allow later cancellation windows, code does not currently support it.
3. **Role-switch onboarding UX is stateful but partially implicit.** The app infers micook CTA state from role membership + onboarding checklist + Stripe provisioning. Product should define canonical states and copy for active/onboarding/disabled more explicitly.
4. **Dine-in is feature-flagged by schema existence.** The product experience changes if the `dine_in_slots` table is not migrated; this is a technical deployment dependency acting like a feature flag.
5. **Menu availability has mutually exclusive modes.** A dish cannot use both a specific `available_date` and recurring `available_days`; confirm this matches merchant expectations.
6. **Automatic first-five-orders discount is backend-driven.** The order service applies a fixed 50.00 discount for users with fewer than five completed orders, but that rule is not obviously explained in the scanned mobile checkout UX.
7. **Promo-code support looks backend-first.** Orders accept `promo_code`, validate active windows, and serialize promo data in resources, but no clear mobile promo-entry UI was surfaced in the reviewed screens.
8. **Dish-level service support inherits kitchen constraints.** A dish cannot expose dine-in or take-away unless the kitchen supports that mode. This is sensible, but should be surfaced clearly in UX copy.
9. **Take-away acceptance can change promised time, dine-in cannot.** That distinction is enforced server-side and should be reflected in cook order-management UI and customer comms.
10. **Order deep links are only partial.** Deep links to `/order/{id}` currently land on Bookings because full order-detail arguments are not reconstructible from the link payload alone.
11. **Manual vendor transfers are blocked from public API.** Settlement is automation/admin-driven, so any PM expectation of self-serve withdrawals is not implemented here.
12. **Account deletion appears incomplete.** Mobile settings attempt `/api/v2/account/delete`, but that route was not found in the scanned backend API file, so this may currently be broken, deferred, or implemented elsewhere.
13. **No concrete loyalty/referral system was visible in the mobile product, despite some admin/pre-registration references.** If these are roadmap items, they are not materially represented in the analyzed mobile/backend paths.
14. **Review routing exposure should be double-checked.** Review controller behavior is clear, but exact public route registration for every review action was not fully confirmed from the scanned route file and may rely on legacy or omitted routes.
15. **Notification preference storage looks cook-keyed.** Mobile notification preference resolution uses a cook-named local preference key; product/design should confirm whether mifoodi and micook should have separate or shared toggles.
16. **Biometric auth fails open when unavailable.** That is user-friendly, but if stronger account protection is required, this behavior should be revisited.
17. **Support is present but mostly operationally defined.** Ticket SLAs and escalations exist in backend jobs, yet user-facing expectations (response times, escalation visibility) are not obvious in mobile UX.
