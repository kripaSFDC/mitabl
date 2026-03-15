# mitabl – Requirements Gap Analysis & Improvement Suggestions

---

## Executive Summary: The mitabl Philosophy & USPs

Before analyzing functional gaps, it is critical to understand *what* mitabl is. mitabl is **not a traditional restaurant delivery platform**. It is a community-driven mobile marketplace designed to connect homecooks (**miCooks**) with people who love authentic home-cooked meals (**miFoodies**). 

### Core Identity & Mission

* **Mission:** To build the world's most trusted mobile marketplace for local home-cooked food.
* **Vision:** To become the leading platform where local cooks and food lovers connect through dependable digital experiences.
* **Mantra:** "Break bread with mitabl." (Cook | Discover | Order | Share | Connect)

### Unique Selling Propositions (USPs)

Unlike generic food delivery apps (like UberEats or DoorDash) which focus purely on logistics and speed from commercial kitchens, mitabl differentiates itself through:

1. **Authentic Home Cooking:** The supply side is entirely independent, local home cooks offering genuine, heritage, and homestyle meals that cannot be found in traditional restaurants.
2. **Community Connection:** The platform aims to turn "everyday food moments into meaningful connections." It actively encourages community building, supporting local talent, and sharing experiences.
3. **Flexible Dining Formats:** Rather than just delivery, mitabl focuses on **Dine-In** (eating at the cook's table or home) and **Pick-up/Take-away** (collecting directly from the cook), eliminating delivery logistics and fostering immediate human connection.
4. **Trust & Verification:** Recognizing the unique nature of home-cooked food, mitabl emphasizes safety by requiring cooks to complete a verification process and follow food safety guidelines, supported by a robust rating and review system.
5. **Cook Empowerment:** The platform provides a "dependable platform" with tools for cooks to manage menus, schedules, and orders, treating them as partners rather than just fulfilment nodes.

*This foundational philosophy-prioritizing trust, local connection, and authentic food over purely transactional speed-must drive every technical and product decision, including the gap remediations and proposed innovations outlined below.*

---

## Entity Model Reference (Grounding for All Gaps)

> This section was added during revalidation to prevent any ownership misattribution in gap descriptions below.

| Entity             | Role                                                                                                                                                      | Key FK                                 |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `User` (role_id=2) | micook persona                                                                                                                                            | -                                      |
| `User` (role_id=3) | mifoodi persona                                                                                                                                           | -                                      |
| `Mikitchn`         | The persisted kitchen record. Owned by micook via `user_id`. Enforced as **1-per-user** (`hasOne` on User; backend blocks create if one already exists).  | `mikitchns.user_id` → `users.id`       |
| `Foods`            | Menu items. Owned by **Mikitchn**, not by User directly.                                                                                                  | `foods.restaurant_id` → `mikitchns.id` |
| `Order`            | Bridge entity. Placed by mifoodi (`orders.user_id`) against a kitchen (`orders.mikitchn_id`).                                                             | Both FKs present                       |
| `Payment`          | Attached to order (`payments.order_id`). indirectly tied to both sides. Foodie history filters by `order.user_id`; cook payout by vendor/kitchen linkage. | `payments.order_id` → `orders.id`      |

**Key relationship confirmed in code:**

- `User::restaurant()` → `hasOne(Mikitchn::class)` - one micook = one Mikitchn
- `Mikitchn::foods()` → `hasMany(Foods::class, 'restaurant_id')` - foods belong to Mikitchn
- `FoodsController::saveFood()` writes `restaurant_id = Auth::user()->restaurant->id` - uses Mikitchn id, never raw user id
- `OrderService::createOrder()` uses field name `kitchen_id` from the request payload which maps directly to `mikitchns.id` (validated by `exists:mikitchns,id`) and writes to `order->mikitchn_id`
- `OrderController::canManageOrder()` checks ownership via `$user->restaurant->id === $order->mikitchn_id` for cook side

**Practical consequence:** Because the 1:1 cook→kitchen is enforced, "cook-owned" and "kitchen-owned" are functionally equivalent statements from an access control perspective. Gaps described in terms of either micook or Mikitchn are correct - but precise terminology matters for implementation guidance.

---

## Requirement 1 - miFoodi browses food menu (all dishes with price) by various miKitchns/miCooks and places an order as dine-in or take-away

### 1a. Browsing kitchens - 🟡 Partial

| What exists                                                                                                                                        | Gap                                                                                                                                                                                                                                                                                                                                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Discovery endpoints (`nearest`, `top-rated`, `recommended`, `filtered`, `restaurants/{id}`) return kitchen cards with images, ratings, and timing. | **The kitchen detail response does NOT include the food menu (dish list with prices).** `DiscoveryController::show` loads `addedimage`, `certificate`, `weektimings`, and `user` - but **not `foods`** relation. A separate `GET /api/v2/mymenu` exists but is cook-only (behind `restaurant` middleware). There is no public/foodie-accessible menu endpoint for a given kitchen. |
| Filter supports `dine_in` and `take_away` flags on kitchens.                                                                                       | No per-dish `dine_in` / `take_away` flag exists on the `foods` table or `FoodsController`. A miFoodi cannot tell whether a specific dish is dine-in only or take-away only.                                                                                                                                                                                                        |
| No keyword / dish-name text search.                                                                                                                | Search is ranking-only. A foodie cannot search "biryani" or "pasta" across all kitchens.                                                                                                                                                                                                                                                                                           |

### 1b. Placing an order - 🔴 **Critical Missing Feature**

| What exists                                                                                                                 | Gap                                                                                                                                                                                                                        |
| --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `OrderController::store` is fully implemented with validation, pricing, discount, and DB persistence logic.                 | **There is NO route registration for this endpoint in `api.php`**. The method is completely unreachable by any client. The mobile app has no order placement repository or UI. End-to-end order placement is fully broken. |
| Order model correctly carries `dine_in`, `take_away`, `persons`, `delivery_date`, `delivery_time_from`, `delivery_time_to`. | The mobile app has no ordering flow UI - no cart screen, no order summary screen, no dine-in vs take-away selection screen for the miFoodi.                                                                                |

---

## Requirement 2 - miFoodi saves credit/debit cards & uses them or a one-time card at checkout

### 2a. Saving cards - 🟡 Partial (backend ready, mobile NOT wired)

| What exists                                                                                                                                  | Gap                                                                                                                                                                                                                    |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /api/v2/payments/cards` - add card. `GET /api/v2/payments/cards` - list cards. Stripe `payment_method_id` validated with `pm_` prefix. | **Mobile app `payments_repository.dart` only calls `GET` (fetch), never `POST` (add card).** There is no "Add Card" button or UI in the mobile app payments page. The page only shows saved cards and payment history. |
| `POST /api/v2/payments/checkout-session` creates a Stripe-hosted card setup session.                                                         | Mobile app does not call this endpoint either. No checkout session flow in the app.                                                                                                                                    |

### 2b. Selecting a saved card at checkout - 🔴 Not implemented

| What exists                                                                                                                                                                       | Gap                                                                                                                                                                                                                                                                       |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PaymentService::resolveCustomerPaymentMethodId` supports resolving by saved `card_id` or raw `pm_` string. `createPaymentIntent` supports creating an intent against a customer. | **The `createIntent` endpoint (`POST /api/v2/payments/intent`) does NOT accept a `card_id` or `payment_method_id` parameter**. It only takes `order_id`. The card is only specified at `confirmIntent`. The flow does not support "select card → pay" in a single action. |
|                                                                                                                                                                                   | Mobile app has NO checkout/order-payment flow UI. miFoodi cannot select a card during ordering.                                                                                                                                                                           |

### 2c. One-time payment with a different card - 🔴 Not implemented

| What exists                                                                                          | Gap                                                                                                                                                                                                                                                         |
| ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stripe PaymentIntent system is flexible enough to support a one-time `payment_method_id` on confirm. | No API endpoint or mobile UI allows passing a one-time card (new `pm_*`) at order time. The `confirmIntent` endpoint uses only the `card_id` stored on the `Payment` record, set during intent creation - which does not currently accept a card reference. |

---

## Requirement 3 - miFoodi can cancel the order until it is not yet accepted by miCook

### 3a. Cancellation API - 🟡 Incorrect scoping

| What exists                                                                                                                                                          | Gap                                                                                                                                                                                                                                                                                                   |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /api/v2/updateorderstatus` allows setting status to `4` (cancelled). `canManageOrder` allows both the order owner (user) and the owning cook to change status. | **There is no guard preventing the miFoodi from cancelling an already-accepted (status=3/confirmed) order.** The `statusUpdate` method only validates the allowed values; it does not enforce the business rule "cancel only if not yet accepted". A foodie can cancel a confirmed/in-progress order. |
|                                                                                                                                                                      | **There is no cancellation reason or policy enforcement** (e.g., no-show window, cancellation fee). The `CancelReason` model exists but nothing in `statusUpdate` requires or records a cancel reason.                                                                                                |
|                                                                                                                                                                      | **No push notification is sent to the miCook when a miFoodi cancels.** `FcmController::sendTo` exists but is never called from `OrderController`.                                                                                                                                                     |

---

## Requirement 4 - miCook sees incoming orders, accepts them; payment deducted; status → confirmed / in-progress

### 4a. Accepting and triggering payment - 🟡 Partial / incorrect

| What exists                                                                                                                                                                                                | Gap                                                                                                                                                                                                                                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /api/v2/updateorderstatus` with `status=3` triggers `PaymentService::confirmPaymentIntent`. Payment record is locked and confirmed in a DB transaction. `order.paid=1` and `order.status=3` are set. | **Payment can only be confirmed if a `Payment` record already exists for the order.** But with order placement broken (Req 1), no `Payment` record will exist. The flow is: place order → create intent → cook accepts → payment confirmed. The middle step (create intent) is also not called from mobile. |
|                                                                                                                                                                                                            | After acceptance, **no push notification is sent to the miFoodi** confirming acceptance, pickup/dine-in time, or estimated wait. `FcmController` is orphaned - never invoked in the order lifecycle.                                                                                                        |
|                                                                                                                                                                                                            | The status after acceptance is `3` (confirmed). The codebase has no "in progress" status (e.g., status=5). The FAQ and website reference "in progress" semantically, but no status exists for it.                                                                                                           |

---

## Requirement 5 - miFoodi receives order confirmation and dine-in/pick-up time

### 5a. Confirmation notification - 🔴 Not implemented

| What exists                                                                                                             | Gap                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `account/device-token` endpoint exists to store FCM tokens. `FcmController::sendTo` exists with legacy FCM v1 HTTP API. | **`FcmController::sendTo` is never called from `OrderController` or `statusUpdate`.** No push notification is sent at any point in the order lifecycle to either party.  |
| Order model carries `delivery_date`, `delivery_time_from`, `delivery_time_to`.                                          | These fields are set at order creation time, not when the cook accepts. There is no mechanism for the cook to propose or override the pickup/dine-in time at acceptance. |

### 5b. Order detail visible to miFoodi - 🟡 Partial

`GET /api/v2/account/orders` lists miFoodi's orders with status. But with order placement broken, there will be no orders to see.

---

## Requirement 6 - miCook can see orders and view pick-up/dine-in time

### 6a. - 🟢 Implemented (with caveats - fix the caveat)

`kitchenupcomingorders`, `kitchenorderrequest`, `allorders` all return `delivery_date`, `delivery_time_from`, `delivery_time_to` via the `Order` resource. Filter by `take_away` / `dine_in` sort exists.

> **Caveat:** There is a **typo in the method name** - `myUpcomingOrderss` (double `s`). The route maps to it correctly but it is a maintenance risk. 

-> Fix the method name to myUpcomingOrders and also all references to this method should be updated. there MUST not be any method name or reference or method call or instanciation etc. for myUpcomingOrderss.

---

## Requirement 7 - miCook creates daily/weekly menu; sets dine-in seats; creates dine-in timeslots

### 7a. Daily/weekly menu - 🔴 Not implemented as designed

| What exists                                                                                                                      | Gap                                                                                                                                                                                                                                                                                                                          |
| -------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FoodsController` allows adding/editing/toggling individual food items with `food_name`, `price`, `cookingstyle`, `specialDiet`. | **There is no concept of daily or weekly menu scheduling.** A dish is just either active or inactive globally. There is no `available_date`, `available_days`, `available_from_time`, `available_to_time` field on `foods`. A miCook cannot say "I serve lamb on Fridays only" or "this dish is only available on weekends". |
| FAQ says "availability schedule" and "pre-order meals" are features.                                                             | No scheduling schema, validation rule, or API field supports this. The website FAQ states this as a user-facing promise that is not implemented.                                                                                                                                                                             |

### 7b. Dine-in seats - 🟡 Partial

| What exists                                                                              | Gap                                                                                                                                                                                                         |
| ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Mikitchn.no_of_seats` field exists and is set during `createKitchen` / `updateKitchen`. | **No enforcement at order creation time.** `OrderService::createOrder` does not check if `persons` exceeds `kitchen.no_of_seats`. A miFoodi could theoretically book more people than the kitchen capacity. |
|                                                                                          | No real-time availability tracking - no check for concurrent bookings that might exceed capacity for the same date/time slot.                                                                               |

### 7c. Dine-in timeslots - 🔴 Not implemented

| What exists                                                                           | Gap                                                                                                                                                                                                         |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Kitchen `Timing` model and `weektimings` relation store open/close hours per weekday. | **There is no time-slot system**. No `DineInSlot` model, no slot capacity, no slot booking. The order just carries a free-form `delivery_time_from` / `delivery_time_to` window.                            |
| FAQ Q10 says "Choose the available date and time" implying a slot picker.             | No slot availability API exists. The mobile app has no slot picker UI. miFoodi cannot choose from available slots - they enter a time window manually (same pattern as the lat/lng location input problem). |



---



## Changes Implemented

### A. Fix the Critical Blocker First (P0)

Register `OrderController::store` in `api.php` under a customer-gated route. Without this, the entire platform value proposition (placing orders) does not function. This is a 1-line fix in `api.php`.

```php
Route::post('orders', [OrderController::class, 'store'])->middleware('customer');
```

---

### B. Introduce a Proper Order Lifecycle with Notifications

The FCM infrastructure exists but is dormant. Wire push notifications into every state transition:

| Event           | Who to notify | Message                                           |
| --------------- | ------------- | ------------------------------------------------- |
| Order placed    | miCook        | "New order request from [Foodie Name]!"           |
| Cook accepts    | miFoodi       | "Your order is confirmed! Come at [time]."        |
| Cook declines   | miFoodi       | "Your order was declined. Full refund initiated." |
| miFoodi cancels | miCook        | "Order cancelled by customer."                    |
| Order ready     | miFoodi       | "Your meal is ready for pickup/dine-in."          |
| Order completed | Both          | "Thanks for using mitabl! Leave a review."        |

---

### C. Slot-Based Dine-In Booking System

Instead of free-form time windows, introduce a proper slot model:

- miCook sets **available time slots** (e.g., 12:00–13:00, 13:00–14:00) with **seat capacity per slot**
- miFoodi sees only open slots and picks one from a picker
- Backend validates: `persons` ≤ `remaining_capacity_for_slot`
- Concurrent bookings handled with a pessimistic lock or slot reservation token

---

### D. Food Menu Scheduling (Daily/Weekly)

Add an `availability` concept to the `foods` table:

- `available_days` (array of weekdays, e.g., `["Friday","Saturday","Sunday"]`)
- `available_from` / `available_to` time
- This allows a miCook to set "I serve Sunday roast only on Sundays"
- Discovery API surfaces only dishes available on today's date/day

---

### E. Dish-Level Dine-In / Take-Away Tagging

The current system only tags the **kitchen** as dine-in/take-away. Add per-dish flags:

- `dine_in_available`: boolean on `foods`
- `take_away_available`: boolean on `foods`
- Discovery `restaurants/{id}` response should include the menu with these flags so miFoodi can filter dishes by their preferred service type

---

### F. Pre-Order / Advance Booking

The FAQ mentions "pre-order meals." Implement:

- Ability to order X days in advance (configurable per cook)
- Cook sets `advance_order_days` in kitchen profile
- Validation in `OrderController::store`: `delivery_date` ≤ today + `advance_order_days`

---

### G. No-Show & Cancellation Policy

The FAQ mentions "reservation fees" for no-shows. Implement:

- A **hold/authorise** Stripe PaymentIntent at order placement (not immediate capture)
- **Cancel policy window**: free cancellation within N hours of placing; penalty afterward
- Cook's no-show flag marks a booking as no-show → triggers partial payout to cook
- Currently, payment is only captured on cook acceptance (`capture_method: automatic`). Switch to `capture_method: manual` → capture on acceptance, refund on cancel.

---

### H. Keyword Search for Dishes Across Kitchens

Currently there is no text search. Add:

- `GET /api/v2/discovery/search?q=biryani` - searches across `foods.food_name` + `foods.description` and `mikitchns.name`
- Returns matched dishes grouped by kitchen with availability and price

---

### I. In-App Messaging Between miFoodi and miCook

FAQ Q15 mentions "you may be able to message the cook through the mitabl app." Currently, no messaging system exists:

- A basic thread-per-order messaging model (similar to the existing support ticket pattern) would fulfill this
- Useful for dine-in instructions, dietary preferences, late arrivals

---

### J. Account Delete Flow

Mobile app calls `v2/account/delete` but the backend route does not exist. This is a required feature for both App Store and Google Play compliance (mandatory user data deletion). Wire up a proper GDPR/app store-compliant account deletion endpoint.

---

### K. Security: Registration Endpoint is Open

As noted in `docs/Planned Improvements.md`, anyone can register unlimited accounts (cook/foodie) with no rate limiting or device verification. For a food-trust platform this is significant:

- Add throttle middleware to `POST /api/register`
- Consider email domain or phone number uniqueness enforcement
- Optionally, add an app-signature header check to prevent bots

---

### L. Hardcoded Business Logic Should Be Config-Driven

From `OrderService`:

- Discount for first 5 orders: `$discountAmountCents = 5000` ($50 AUD) - hardcoded
- GST rate: `10` - hardcoded in two places

These should be pulled from `PlatformSettingRegistry` (already exists) so the admin can adjust without a deployment.

---

### M. miCook Identity & Trust Signals (Platform Philosophy)

The platform is built on community trust. Consider surfacing:

- **Cook story/bio** - `user.description` exists but is not consistently surfaced in discovery cards
- **Years cooking** / **Cuisine specialties** - not captured in the data model
- **Verification badge** - certificate/ABN status is stored but not visually surfaced in the discovery feed
- **Repeat customer indicator** - tell a miFoodi "You ordered from here before" (helps retention)

---

### N. Review Flow is Route-Orphaned

`ReviewController` (add review to restaurant, add review to foodie, get kitchen reviews) exists fully - but **none of its routes are registered in `api.php`**. Reviews are referenced in discovery (ratings from `reviews.avg_rating`) but foodies cannot submit reviews. This breaks the "ratings and reviews" trust mechanic mentioned in FAQ Q5 and Q6.

---

---

## 🚀 Proposed Innovations

> These go beyond gap-fixing. Each proposal is a new capability idea, stress-tested against mitabl's core philosophy:
> **"world's most trusted mobile marketplace for local home-cooked food - cook | discover | share | connect."**
> Every idea is grounded in what makes home-cooked meals fundamentally different from restaurant delivery.

---

### PI-1 - `miTable`: The Shared Dine-In Experience (Community Dining)

**Proposed Innovation**

> *"Break bread with mitabl." - Homepage*

The current model treats every dine-in booking as a private, per-order event. But the platform philosophy is deeply communal. Introduce **miTable** - a concept where a miCook opens a shared dining table and multiple unrelated miFoodies can join the same sitting.

**How it works:**

- miCook creates a "miTable event": a fixed date, time slot, menu, price per seat, and max covers (e.g., "Sunday Lebanese feast, 6 seats, AUD 45/person, Nov 3 at 1PM")
- miFoodies browse upcoming miTable events near them - like a dining-out experience at a local home table
- miFoodies buy a seat (1–N seats up to max) - payment held, released to cook when the first guest minimum is met
- If minimum guests are not met by the RSVP deadline, all payments are automatically refunded

**Why it fits the philosophy:**
This is the soul of mitabl - breaking bread with strangers-turned-neighbours. It's impossible on any restaurant delivery platform. It directly delivers on "discover | share | connect" and creates the "meaningful local food moment" the about page promises.

**Platform implications:**

- New `miTable` model linked to `Mikitchn`, with `seats_total`, `seats_booked`, `min_guests`, `price_per_seat`, `event_at`
- New discovery feed for upcoming events (sorted by date/proximity)
- Stripe `capture_method: manual` - hold on seat booking, capture on event confirmation

---

### PI-2 - miCook Availability Status ("Open Now" / "Closed" / "Accepting Pre-orders")

**Proposed Innovation**

Currently, a kitchen either has timings or not. There is no real-time `open_now` signal. Introduce a **live availability state** for each kitchen:

| State                  | Meaning                                                         |
| ---------------------- | --------------------------------------------------------------- |
| 🟢 **Open Now**        | Kitchen is within operating hours and actively accepting orders |
| 🟡 **Pre-orders Only** | Kitchen is closed now but accepting future-dated orders         |
| 🔴 **Closed**          | Not accepting any orders right now                              |
| ⏸️ **Paused**          | Temporarily paused by cook (e.g., overwhelmed with orders)      |

**Why it fits:**
Home cooks are not operating 24/7 commercial kitchens. A foodie tapping into a kitchen at 9PM shouldn't see a menu they can't order from. Discovery cards should surface the status badge prominently. The "Paused" state (FAQ Q23 - "Can I pause orders?") is already promised but not implemented.

**Platform implications:**

- Computed `is_open_now` on kitchen detail endpoint, derived from `Timing` records vs. current server time
- New `kitchen_status` enum field: `open`, `pre_order_only`, `paused`, `closed`
- Discovery feed filters: "Open Now" toggle (a missing but high-demand filter)
- Push notification when a favourite miCook opens for the day: "☀️ [Cook Name]'s kitchen is now open!"

---

### PI-3 - Dietary & Allergen Intelligence on Dishes

**Proposed Innovation**

The `specialDiet` field exists on foods (stored as integer array mapping to `SpecialDiet` lookup table). But this data is **never surfaced to the miFoodi** in the discovery or ordering flow.

Elevate this into a **full allergen + dietary preference engine**:

- miFoodi sets their **dietary profile** once (vegan, gluten-free, nut allergy, halal, etc.)
- Discovery feed automatically **highlights compatible dishes** and **warns** about incompatible ones
- Per-dish `allergen_flags` (separate from dietary style) - e.g., contains nuts, dairy, shellfish
- "Safe for me" badge appears on dishes matching the foodie's saved profile

**Why it fits:**
Trust is the platform's core promise. A foodie with a nut allergy trusting a home cook needs this more than they would at a restaurant with a printed menu. This is a genuine trust differentiator that no generic delivery platform delivers on at the community level.

**Platform implications:**

- New `allergen_flags` (bitmask or JSON) on `foods` table
- New foodie `dietary_profile` preference stored on `users` or a linked `foodie_preferences` table
- Discovery `restaurants/{id}` includes foods annotated with `safe_for_me: true/false/warning`

---

### PI-4 - miCook "Story Mode": The Cook Profile Experience

**Proposed Innovation**

The platform's brand says *"cook | discover | share | connect"* - but the miCook profile is currently just a name, avatar, and description text field. Introduce **Story Mode** - a richer cook identity layer:

- **Cook origin story**: short-form rich-text bio (where they're from, what drives them to cook)
- **Signature dishes**: 3 pinned dishes shown at the top of the kitchen card
- **Cuisine heritage tags**: free-form or from a curated list (e.g., "Lebanese grandmother recipes", "Japanese homestyle", "Sri Lankan street food")
- **Photo story**: a small gallery (beyond food photos) showing the cook's kitchen, garden, family meals
- **Cook milestone badges**: "100 happy foodies", "First dine-in event", "Verified food handler"

**Why it fits:**
This makes a home cook feel real and trusted in a way that a star rating never will. miFoodies are choosing to eat food made in a home - the cook's humanity and story is their menu. Airbnb hosts won awards for storytelling; mitabl can do the same for cooks. This directly fulfils the "meaningful connections" and "community" mission.

**Platform implications:**

- New `cook_story`, `signature_dish_ids[]`, `heritage_tags[]` fields on `Mikitchn` or a linked `CookProfile` table
- New `badge` model with criteria hooks (e.g., `completed_orders >= 100 → award badge`)
- Discovery card redesign to surface signature dishes and one heritage tag prominently

---

### PI-5 - Smart Re-order: "Eat This Again"

**Proposed Innovation**

Once miFoodi has order history, surface a **"Eat This Again"** persistent shortcut:

- Home feed for a returning foodie shows a personalised card: *"Last time at [Cook Name]: Lamb Kofta + Hummus - AUD 28. Order again?"*
- One-tap re-order pre-fills cart, time preferences, and payment method
- Optionally notify: *"[Cook Name]'s lamb kofta is available this Saturday - want to book?"*

**Why it fits:**
Retention in food apps is won by removing friction for repeat orders. A community platform is even more about loyalty - these are your neighbourhood cooks. Making it trivial to "come back to your favourite" is deeply aligned with building a local food community, not just transactional convenience.

**Platform implications:**

- New `GET /api/v2/account/reorder-suggestions` endpoint - queries `Order` history, groups by kitchen + food combos, checks current availability
- Mobile: new home feed section "Order it again" above the discovery feed

---

### PI-6 - miCook Revenue Intelligence Dashboard

**Proposed Innovation**

The current dashboard shows `total_earning`, `n_bookings`, `n_upcoming_bookings`. This is three numbers - not intelligence. Elevate the miCook dashboard to a **light business intelligence panel**:

| Metric                                         | Value it gives a cook              |
| ---------------------------------------------- | ---------------------------------- |
| Earnings this week vs. last week               | Trend awareness                    |
| Top dish by order count                        | Know what to make more of          |
| Peak booking day/time                          | Helps plan kitchen prep            |
| Average rating trend (last 30 days)            | Quality self-monitoring            |
| Cancelled orders rate                          | Early warning of fulfilment issues |
| Revenue by service type (dine-in vs take-away) | Inform slot and menu strategy      |

**Why it fits:**
The platform's promise to miCooks is not just "receive orders" - it's "grow". The about page says *"mitabl gives micooks a dependable platform to... serve their local audience."* Empowering cooks with data is how the platform becomes indispensable, not just functional.

**Platform implications:**

- Extend `GET /api/v2/account/dashboard` with an `insights` sub-object
- New database queries: top food by `OrderData` aggregation, booking hour histogram, rating moving average
- Admin equivalent view should already show this - share the query layer

---

### PI-7 - Group Ordering for miFoodi (Office Lunches, Family Bookings)

**Proposed Innovation**

miFoodies should be able to **initiate a group order** where multiple people each add items to a shared cart before checkout:

- miFoodi creates a group order → gets a **shareable link**
- Friends/colleagues tap the link, each picks their dishes (up to the kitchen's capacity)
- Once the group leader confirms, a single combined order is placed and one payment (split or single) is made
- Cook sees one consolidated order, not N individual orders

**Why it fits:**
The FAQ says "make several dine-in or takeaway requests" - but one of the biggest friction points in group dining is coordinating orders. Solving this is a classic "10x better than calling a restaurant" moment. It fits the "connect" pillar perfectly.

**Platform implications:**

- New `GroupOrder` model with a sharable token, status (`drafting`, `locked`, `placed`), and linked `Order`
- Each participant adds a `GroupOrderItem`; the leader confirms and the system creates the final `Order`
- New endpoints: `POST /api/v2/group-orders`, `POST /api/v2/group-orders/{token}/items`, `POST /api/v2/group-orders/{token}/confirm`

---

### PI-8 - "Cook's Special" - Flash Availability Notifications

**Proposed Innovation**

Introduce a **Cook's Special** feature where a miCook can push a spontaneous, limited-time offer to their followers:

- miCook taps "Post a special" → enters dish name, price, available count (e.g., "5 portions"), and expiry window (e.g., "next 2 hours")
- All miFoodies who have **favourited** this kitchen receive a push notification: *"🔥 Sarah's Kitchen just posted: Chicken Biryani - AUD 18, only 5 left. Grab yours now!"*
- Availability auto-expires when the time window closes or stock reaches 0

**Why it fits:**
Home cooks often have spontaneous surplus (made a big batch of curry, have guests cancelling). This gives them a safety valve and a direct revenue channel. For foodies, it's the thrill of discovering a local special - exactly the "authentic, real, community" feeling the platform promises. No delivery app does this for home cooks.

**Platform implications:**

- New `Special` model: `kitchen_id`, `dish_name`, `price`, `qty_total`, `qty_remaining`, `expires_at`
- FCM batch notification to all favouriting foodies using existing device tokens
- Discovery: "Specials Near You" section on the home feed (time-limited, urgency UI)

---

### PI-9 - miCook Waitlist: "Notify Me When Available"

**Proposed Innovation**

When a kitchen is full for a given slot, or a dine-in event is sold out, miFoodi should be able to **join a waitlist**:

- miFoodi taps "Notify me if a spot opens" on a fully-booked slot or event
- If a cancellation occurs or the cook adds capacity, waitlisted foodies are notified in order
- First to confirm within a time window (e.g., 30 mins) gets the spot

**Why it fits:**
This converts "lost bookings" into "deferred demand" - a major retention win. It also signals to cooks that demand exceeds supply, giving them data to open more slots or run another miTable event. The `WatchSubscription` model already **exists in the codebase** - this is close to being buildable immediately.

**Platform implications:**

- `WatchSubscription` model is already in `backend/app/Models/WatchSubscription.php` - leverage it
- New `POST /api/v2/kitchens/{id}/slots/{slot_id}/waitlist` endpoint
- New job: on cancellation → notify next waitlisted user via FCM

---

### PI-10 - miCook Preparation Timer & Order Status Clock

**Proposed Innovation**

Once an order is accepted, both parties exist in an information vacuum - the miFoodi doesn't know if the cook has started, how long left, or when to leave home. Introduce a **preparation timer**:

- miCook confirms acceptance and sets (or adjusts) the **ready time** (e.g., "Ready in 45 mins from now")
- miFoodi sees a live countdown: *"Your meal will be ready at 1:30PM - leave in 20 mins"*
- miCook can send a **"Ready Now"** signal → push notification to miFoodi: *"Your order is ready! Head over to [address]"*

**Why it fits:**
This solves the #1 anxiety in home-cook dining: "when do I actually leave?" Home cooks don't have standard restaurant timing. The platform's "reliable fulfilment" promise (from the about page) depends on this visibility. This is something Uber Eats and DoorDash do for drivers - mitabl should do it for dine-in and take-away.

**Platform implications:**

- New `ready_at` timestamp on `Order` - miCook sets it on acceptance or updates it
- New status: `STATUS_READY = 5` (cook signals food is ready)
- The acceptance response payload returns the `ready_at` time to the miFoodi's push notification

---

### PI-11 - Tiered miCook Recognition System ("Levels")

**Proposed Innovation**

Motivate quality and consistency with a **tiered cook recognition system** visible to foodies:

| Level               | Criteria                                            | Badge       |
| ------------------- | --------------------------------------------------- | ----------- |
| 🌱 **New Cook**     | < 10 completed orders                               | -           |
| ⭐ **Rising Cook**   | 10+ orders, avg rating ≥ 4.0                        | Silver star |
| 🔥 **Popular Cook** | 50+ orders, avg rating ≥ 4.3, < 10% cancel rate     | Flame badge |
| 👑 **miCook Elite** | 200+ orders, avg rating ≥ 4.7, certificate verified | Crown       |

- Elite cooks get preferential placement in discovery rankings
- Foodies can filter for "Elite only" or "Rising Cooks" (discovery of new gems)
- Levels are dynamically recomputed nightly

**Why it fits:**
Trust signals drive conversion in marketplace platforms. A rating number alone is weak - a visible level system gives foodies at-a-glance confidence and gives cooks a meaningful, public incentive to maintain quality. FAQ Q24 promises "higher ratings improve visibility" - this operationalises that promise with a motivating gamification layer.

**Platform implications:**

- Nightly scheduled job computes levels from `Order`, `Review`, `Certificate` data
- New `cook_level` field on `Mikitchn`
- Discovery ranking formula weights `cook_level` alongside rating and recency

---

### PI-12 - miFoodi "Dietary Passport" & Personalised Discovery Ranking

**Proposed Innovation**

Every miFoodi should have a **Dietary Passport** - a saved set of preferences that shapes their entire discovery experience:

- Dietary type (vegan, vegetarian, halal, kosher, gluten-free, etc.)
- Cuisine interests (Lebanese, Japanese, Indian, etc.)
- Service preference (dine-in person / take-away person)
- Max distance willing to travel
- Price preference range (AUD 10–20, 20–40, 40+)

The discovery feed then ranks kitchens using a **personalised relevance score** = proximity + dietary match + cuisine interest + historical order overlap + rating.

**Why it fits:**
"Discover" is one of the four platform pillars. Right now discovery is purely geo/rating-based - no personalisation. A foodie who loves Japanese home cooking and is vegan should never see a meat-heavy Italian kitchen in their top results. This makes discovery feel magical and turns the app into something foodies return to daily just to browse, not only when hungry.

**Platform implications:**

- New `foodie_preferences` table: `user_id`, `dietary_types[]`, `cuisine_interests[]`, `service_type`, `max_distance_km`, `price_min`, `price_max`
- New `GET /api/v2/account/preferences` + `PUT /api/v2/account/preferences` endpoints
- Discovery ranking logic updated to compute a `relevance_score` using preference overlap

---

### PI-13 - Social Proof Layer: "X of your Suburb Ordered Here This Week"

**Proposed Innovation**

Inject **localised social proof** into the discovery experience:

- Kitchen cards show: *"12 foodies in Newtown ordered from here this week"*
- Or: *"Trending in Surry Hills this weekend"* (based on order velocity in a geo-cluster)
- Or: *"Your neighbours love this kitchen"* (based on overlapping location radius with past orderers)

This is privacy-safe - no individual data is shown, only aggregate counts.

**Why it fits:**
The platform's entire story is neighbourhood and community. Knowing your literal neighbours are eating here is the strongest possible social proof for a local food platform - it's word-of-mouth, operationalised in the app. This is something no generic delivery app can authentically claim.

**Platform implications:**

- New aggregation query: `Order count by kitchen_id WHERE delivery_date >= last 7 days AND user is within X km of kitchen` (approximate suburb-level bucketing, no PII)
- New `social_proof` field in the kitchen discovery response
- Rolling 7-day window maintained in a Redis/cache key invalidated on new orders

---

### PI-14 - "miCook Mentor" Programme: Cook-to-Cook Community

**Proposed Innovation**

As the platform grows, experienced miCooks can become **miCook Mentors** - guiding newer cooks through the platform:

- Elite-level cooks (PI-11) can opt into the Mentor programme
- New cooks are matched with a mentor during onboarding
- Mentor gets a small commission bonus for every order their mentee completes in the first 3 months
- In-app mentor chat (separate from order messaging)
- Mentor leaderboard in the admin panel

**Why it fits:**
The vision says *"become the leading platform where local cooks and food lovers connect"* - but "connect" currently only means cook-to-foodie. A cook-to-cook connection layer builds the community from the supply side, dramatically improves cook quality/retention, and creates a sense of belonging that is impossible to replicate on any logistics-first delivery platform. This is mitabl's unfair advantage: it's a community, not a fulfilment network.

**Platform implications:**

- New `MentorRelationship` model: `mentor_id`, `mentee_id`, `started_at`, `active`
- Mentor matching during onboarding: `GET /api/v2/account/onboarding/cook/suggested-mentor`
- Commission calculation in payout: additional `mentor_bonus_pct` applied to mentee's first N orders
- Admin panel: Mentor programme management page (assign, view pairs, measure impact)

---
