# MITABL Mobile App — UI Implementation Master Plan

> Generated: 2026-03-22
> Based on visual inspection of all 42 design screens in `design-artifacts/D-Design-System/mobile-appdesign/`
> Cross-referenced against existing Flutter codebase in `mobile-app/lib/`

---

## TABLE OF CONTENTS

1. [Screen Mapping Summary](#1-screen-mapping-summary)
2. [Critical Corrections from Visual Audit](#2-critical-corrections-from-visual-audit)
3. [Phase 0 — Foundation: Design System Alignment](#phase-0--foundation-design-system-alignment)
4. [Phase 1 — Authentication & Onboarding](#phase-1--authentication--onboarding)
5. [Phase 2 — Foodie Core Experience](#phase-2--foodie-core-experience)
6. [Phase 3 — Foodie Account & Social](#phase-3--foodie-account--social)
7. [Phase 4 — Cook Onboarding](#phase-4--cook-onboarding)
8. [Phase 5 — Cook Dashboard & Operations](#phase-5--cook-dashboard--operations)
9. [Phase 6 — Cook Menu & Profile Management](#phase-6--cook-menu--profile-management)
10. [Phase 7 — Cross-Cutting Concerns](#phase-7--cross-cutting-concerns)
11. [Identified Gaps & New Dependencies](#identified-gaps--new-dependencies)
12. [Execution Order & Dependencies](#execution-order--dependencies)
13. [Reuse Opportunities](#reuse-opportunities)

---

## 1. Screen Mapping Summary

| Category | Count | Description |
|---|---|---|
| **Major UI Overhaul** (code exists, significant redesign) | 12 | Screens where design is fundamentally different from current code |
| **UI Refresh** (code exists, styling/component updates) | 15 | Screens where structure is similar but needs design token alignment |
| **New Screens** (build from scratch) | 14 | No existing implementation at all |
| **Design Reference** (not a screen) | 1 | `warm_tactile_mitabl` = Design System tokens (DESIGN.md) |
| **Total** | **42** | |

### Complete Screen-to-Code Mapping (Verified via Visual Inspection)

| # | Design Screen | Existing Code | Status | Effort |
|---|---|---|---|---|
| 1 | `splash_screen` | `lib/splash.dart` | Refresh | Low |
| 2 | `landing_page` | `lib/pages/landing_page/landing_page.dart` | **Major Overhaul** | High |
| 3 | `login` | `lib/pages/login/` | Refresh | Medium |
| 4 | `sign_up` | `lib/pages/signup/` | Refresh | Medium |
| 5 | `sign_up_foodie` | None (shared signup page) | **New Screen** | Medium |
| 6 | `forgot_password` | `lib/pages/forgot/` | Refresh | Low |
| 7 | `reset_link_sent` | None | **New Screen** | Low |
| 8 | `otp_verification_1` | `lib/pages/otp/` | Refresh | Low |
| 9 | `otp_verification_2` | None (same OTP page) | **New Variant** | Medium |
| 10 | `biometric_lock` | `lib/pages/common/biometric_lock_page.dart` | Refresh | Low |
| 11 | `discovery_foodie_home` | `lib/pages/home/` | **Major Overhaul** | High |
| 12 | `search_filters` | `lib/pages/home/elements/filter_dialog.dart` (dialog only) | **New Screen** | Medium |
| 13 | `cook_profile_menu` | `lib/pages/ordering/view/order_menu_page.dart` | **Major Overhaul** | High |
| 14 | `menu_item_details` | None | **New Screen** | Medium |
| 15 | `cart_checkout` | `lib/pages/ordering/view/order_cart_page.dart` + `order_checkout_page.dart` | **Major Overhaul** | High |
| 16 | `order_confirmation` | None | **New Screen** | Medium |
| 17 | `order_tracking` | None | **New Screen** | High |
| 18 | `edit_profile_foodie` | `lib/pages/edit_profile_foodie/` | Refresh | Medium |
| 19 | `my_orders` | `lib/pages/miorders/` | **Major Overhaul** | High |
| 20 | `order_details` | Route exists, basic view | **Major Overhaul** | High |
| 21 | `favourites` | `lib/pages/favourites/` | **Major Overhaul** | Medium |
| 22 | `payments` | `lib/pages/payments/` | **Major Overhaul** | High |
| 23 | `add_payment_method` | `lib/pages/common/view/stripe_payment_method_page.dart` (different) | **New Screen** | Medium |
| 24 | `submit_a_review` | None | **New Screen** | Medium |
| 25 | `notification_center` | None | **New Screen** | High |
| 26 | `become_a_micook` | `lib/pages/profile_signup_cook/` | Refresh | Medium |
| 27 | `setup_payouts` | None | **New Screen** | High |
| 28 | `kitchen_certification` | None | **New Screen** | Medium |
| 29 | `cook_dashboard` | `lib/pages_cook/dashboard_cook/` | **Major Overhaul** | High |
| 30 | `order_requests` | `lib/pages_cook/requests/` | Refresh | Medium |
| 31 | `order_rejection_reason` | None | **New Screen** | Low |
| 32 | `upcoming_bookings` | `lib/pages_cook/upcoming_bookings/` | Refresh | Medium |
| 33 | `past_bookings` | `lib/pages_cook/bookings/` | **Major Overhaul** | High |
| 34 | `revenue_analytics` | None | **New Screen** | High |
| 35 | `settings` | `lib/pages_cook/settings_page/` | Refresh | Medium |
| 36 | `add_menu_item` | `lib/pages_cook/add_menu_item/` | Refresh | Medium |
| 37 | `kitchen_profile_settings` | `lib/pages_cook/edit_kitchen_profile/` | Refresh | Medium |
| 38 | `operating_hours` | `timing_edit.dart` / `timing_dialog.dart` | **Major Overhaul** | High |
| 39 | `customer_reviews` | `lib/pages_cook/customer_reviews/` | Refresh | Medium |
| 40 | `user_details` | `lib/pages_cook/user_details_page/` | Refresh | Medium |
| 41 | `offline_state` | `lib/helper/offline_error_widget.dart` (widget only) | **New Screen** | Low |
| 42 | `warm_tactile_mitabl` | N/A | Design Reference | N/A |

---

## 2. Critical Corrections from Visual Audit

These findings significantly affect the plan and were identified ONLY through visual inspection of all screen.png files:

### 2.1 STRUCTURAL: Foodie Bottom Navigation Bar (MISSING)
- **Current:** Foodie side has NO persistent bottom navigation. Only `DashboardCookPage` has a `BottomNavigationBar`.
- **Design shows:** Multiple foodie screens (discovery, orders, favourites, payments, profile) all have a bottom nav bar with tabs like: Discovery | Orders | Profile (or Explore | Favourites | Payments | Profile).
- **Impact:** Need to create a **Foodie Home Shell** (similar to cook's `DashboardCookPage`) that wraps foodie screens with persistent bottom navigation.
- **Files affected:** Need new `lib/pages/home_foodie/home_foodie_page.dart` wrapper, update `route_generator.dart`, update `app.dart` navigation logic.

### 2.2 TWO SEPARATE Signup Screens
- **Current:** One shared `signup_page.dart` for all users.
- **Design shows:**
  - `sign_up` = "Pull up a chair." — Cook signup (Full Name, Email/Phone, Password, Social login)
  - `sign_up_foodie` = "Join the Community" — Foodie signup (Full Name, Email/Phone, Password, **Delivery Address**, Social login)
- **Impact:** Need separate `SignUpFoodiePage` with delivery address field. May need a `SignUpFoodieCubit` or extend existing.

### 2.3 TWO SEPARATE OTP Verification Screens
- **Current:** One `otp_page.dart` with Pinput widget.
- **Design shows:**
  - `otp_verification_1` = Phone-based, **4 digit** code, "Verify" button, "Resend Code" link, "256-BIT ENCRYPTION" badge
  - `otp_verification_2` = Email-based, **5 digit** code (wider circles), "Verify Code" button, "RESEND CODE", "JOIN THE MITABL ATELIER" imagery, "Contact Support" link
- **Impact:** Need two separate views or a parameterized variant. Different digit count, different layout, different footer content.

### 2.4 Landing Page is Now Editorial/Marketing
- **Current:** Simple centered layout with logo + 2 buttons (LOGIN / CREATE NEW ACCOUNT).
- **Design shows:** Full editorial page — "Taste the heart of your neighborhood" hero, "Curated by your neighbours" section, food photography grid cards, "Happening now" section with live cook cards, CTA buttons.
- **Impact:** Complete rebuild. This is not a refresh — it's a fundamentally new screen.

### 2.5 Offline State Needs Full Screen (Not Just Banner)
- **Current:** `OfflineErrorWidget` is a banner overlay widget.
- **Design shows:** Full standalone screen — cute chef illustration, "Oops! It looks like you're offline" message, Retry button, "BACK TO DASHBOARD" button.
- **Impact:** Create new full-screen `OfflineStatePage` while keeping existing banner for inline use.

### 2.6 Payments Screen is Major Redesign
- **Current:** Basic list of saved cards (ListTile) + payment history (ListTile).
- **Design shows:** miFoodi Rewards section, visual credit card representations with gradients, Bank of Atelier branding, Recent Transactions with icons, "Save with miFoodi Card" promo banner, "Purchase Protection" CTA.
- **Impact:** Complete rebuild of payments UI. Major new visual components.

### 2.7 Cook Dashboard Cooking Queue is New Paradigm
- **Current:** Basic dashboard with stats display using simple widgets.
- **Design shows:** "Kitchen Live" toggle with green indicator, Active Orders (3) + Today's Earnings ($84.50) metric cards, **Cooking Queue** with ticket-based order cards (#042, #041, #043) each showing customer, pickup time, items, special notes, Delay/Mark Ready buttons, color-coded states (normal, delayed=red, just-in=faded).
- **Impact:** Complete rebuild. Real-time cooking queue is a new interaction paradigm requiring new widgets and likely new API endpoints.

### 2.8 Past Bookings Has Monthly Performance Analytics
- **Current:** Basic bookings list.
- **Design shows:** History list + **Monthly Performance** card ($8,450 earnings), Top Dishes ranking with earnings per dish.
- **Impact:** Analytics data needed, new API endpoint for monthly performance.

### 2.9 Operating Hours is Much Richer
- **Current:** Simple timing dialog/edit with basic time pickers.
- **Design shows:** Per-day Open/Closed toggles, Start/End time pickers per day, **"Add Break"** feature (afternoon break), **Quick Status** summary card (Weekly Total: 54 Hours, Status: LIVE NOW), **Availability Density** chart visualization.
- **Impact:** Major overhaul. New features: breaks, quick status, density chart. Needs new model fields and API support.

### 2.10 Notification Center Has Categorized Notifications
- **Design shows:** Categorized badges (MI FOOD = orange, MI COOK = green), notification types (order accepted, new review, payout processing), **Weekly Digest** card with "View Report" CTA, "MARK ALL AS READ" action.
- **Impact:** Needs notification categorization, read/unread state, digest report.

### 2.11 Cook Bottom Navigation Changed
- **Current:** 4 tabs — Dashboard, Menu, Requests, Profile
- **Design shows varied patterns:**
  - `cook_dashboard`: Dashboard, Menu, Earnings, Profile
  - `order_requests`: Home, Orders, Inbox, Profile
  - `customer_reviews`: Bookings, Reviews, Orders, Settings
  - `operating_hours`: Business, Finance, Hours (active), Settings
  - `notification_center`: Home, Orders, Inbox, Profile
- **Impact:** Bottom nav tabs may be context-dependent or the designs show exploration of different layouts. Need to finalize the tab structure before implementing.

---

## PHASE 0 — Foundation: Design System Alignment

> **Priority: CRITICAL — Must complete first. ALL subsequent screens depend on this.**
> **Estimated screens affected: ALL 41**

### 0.1 Update Color Tokens
**File:** `lib/helper/app_config.dart`

| Token | Current Value | New Design Value | Action |
|---|---|---|---|
| primary | `#EA580C` | `#9C3E20` (Roasted Earth) | **Update** |
| primary-container | N/A | `#BC5636` (warm accent) | **Add** |
| secondary-container | N/A | `#CCE7C3` (herb green) | **Add** |
| on-secondary-container | N/A | `#51694C` | **Add** |
| surface | N/A | `#FCF9F4` (Warm Oat) | **Add** |
| surface-container-low | N/A | `#F6F3EE` | **Add** |
| surface-container-lowest | N/A | `#FFFFFF` | **Add** |
| on-surface | N/A | `#1C1C19` (Roasted Espresso) | **Add** |
| on-surface-variant | N/A | `#56423C` | **Add** |
| outline-variant | N/A | `#DDC0B8` (ghost borders at 15%) | **Add** |
| tertiary-fixed-dim | N/A | `#D9C2B6` (unselected chips) | **Add** |
| scaffold BG | `#FFFAF5` | `#FCF9F4` | **Update** |
| hint text | `#9CA3AF` | `#56423C` | **Update** |

### 0.2 Update Typography
**Files:** `lib/helper/app_config.dart`, `lib/app.dart`, `pubspec.yaml`

| Element | Current | New Design | Action |
|---|---|---|---|
| Heading Font | ITC Avant Garde Gothic | **Nunito (weight 800)** | Add to pubspec, update theme |
| Body Font | ITC Avant Garde / GothicA1 | **DM Sans** | Add to pubspec, update theme |
| Display Large | Not defined | 3.5rem, Nunito 800 | **Add** |
| headline-lg | Not defined | Nunito, on-surface color | **Add** |
| body-md | Not defined | DM Sans, on-surface-variant | **Add** |

> **Note:** Keep ITC Avant Garde Gothic bundled fonts as fallback. Add Nunito and DM Sans via `google_fonts` package (already in dependencies).

### 0.3 Update Component Style Constants

Create `lib/widgets/design_tokens.dart`:

```dart
// Border Radius
static const double cardRadius = 20.0;       // 1.25rem - ALL content cards
static const double pillRadius = 100.0;      // Buttons
static const double chipSmRadius = 8.0;      // 0.5rem - nested quick info
static const double inputRadius = 16.0;      // 1rem - input fields

// Spacing
static const double spacingItem = 22.4;      // 1.4rem - between list items
static const double spacingBreath = 48.0;    // ~3rem - white space around photos

// Shadows — USE TONAL LAYERING INSTEAD
// No drop shadows on cards. Use surface-container-lowest on surface-container-low.
// Ambient shadow when required: blur 24-40px, opacity 6%, tinted on-surface

// Glassmorphism
// surface at 80% opacity + 20px backdrop blur for sticky headers/nav
```

### 0.4 Create New Shared Widgets

Create `lib/widgets/` directory:

| Widget File | Purpose | Replaces |
|---|---|---|
| `mitabl_card.dart` | Warm 20px radius card with tonal layering (no shadows) | Current Container+BoxDecoration cards |
| `mitabl_button.dart` | 100px pill shape, primary gradient (135deg #9C3E20→#BC5636), secondary (#CCE7C3) | `semantic_button.dart`, MaterialButton |
| `mitabl_text_field.dart` | Filled surface-container-low, no border, 1rem radius, focus glow (primary 20% opacity 2px border) | Current TextFormField+InputDecoration |
| `mitabl_chip.dart` | Pill chip, unselected: tertiary-fixed-dim, selected: primary | Current ChoiceChip |
| `glass_app_bar.dart` | Glassmorphism sticky header (80% surface opacity, 20px blur) | `common_appbar.dart` |
| `mitabl_bottom_nav.dart` | Updated bottom nav with warm color tokens | Current BottomNavigationBar |
| `slide_to_action.dart` | Slide-to-pay/confirm gesture widget | None (new) |
| `cook_card.dart` | Hero image card with overlapping avatar, rating badge, distance/time/price | Current restaurant list tiles |
| `order_ticket_card.dart` | Cook queue ticket with status colors | None (new) |
| `notification_card.dart` | Categorized notification with badge icon | None (new) |

### 0.5 Create Foodie Home Shell

**New file:** `lib/pages/home_shell/home_shell_page.dart`

```
FoodieHomeShell (Scaffold with BottomNavigationBar)
├── Tab 0: DiscoveryFoodieHome
├── Tab 1: MyOrdersPage
├── Tab 2: ProfileFoodiePage
```

This wraps foodie screens with persistent bottom navigation (matching design patterns seen across discovery_foodie_home, my_orders, favourites, edit_profile_foodie, etc.).

**Update:** `route_generator.dart` — Change `/HomePage` to load `FoodieHomeShell` instead of current `HomePage`.

### 0.6 Update Cook Home Shell Bottom Navigation

**Existing:** `lib/pages_cook/dashboard_cook/view/dashboard_cook_page.dart`

Current tabs: Dashboard | Menu | Requests | Profile
Design shows variations — need to finalize. Suggested consolidated tabs:
- **Dashboard** (cooking queue + metrics)
- **Menu** (menu management)
- **Orders** (requests + bookings)
- **Profile** (settings + profile)

---

## PHASE 1 — Authentication & Onboarding

> **11 screens | 6 refresh + 3 new + 2 new variants**

### 1.1 Splash Screen — REFRESH (Low effort)
- **Existing:** `lib/splash.dart`
- **Design:** Centered Mitabl logo (fork+spoon icon in circle), tagline "Taste the heart of your neighborhood", footer "CULINARY CONNECTION"
- **Work:** Update logo asset, add tagline text, warm gradient background, update colors
- **Reuse:** Existing update check logic (`UpdateCheckService`), auth status check, `AuthenticationBloc`

### 1.2 Landing Page — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/landing_page/landing_page.dart` (simple 2-button layout)
- **Design:** Editorial marketing page — hero section "Taste the heart of your neighborhood", "Curated by your neighbours" with food photography grid, cook profile cards with ratings, "Happening now" live section
- **Work:** Complete rebuild with ScrollView, hero section, photo grid, cook cards, CTA buttons
- **Reuse:** Navigation logic to login/signup
- **New widgets needed:** Hero section, food photo grid, live cook cards
- **Note:** This is a marketing/onboarding experience, NOT just a login gate

### 1.3 Login — REFRESH (Medium effort)
- **Existing:** `lib/pages/login/` (LoginPage + LoginForm + LoginCubit)
- **Design:** "Welcome Back" header (Nunito 800), Email/Phone + Password inputs (filled, no border), gradient pill Login button, social login row (Google, Apple, Facebook icons), "Join now" link
- **Work:** Swap typography to Nunito/DM Sans, replace inputs with `MitablTextField`, replace button with `MitablButton` gradient, add social login row
- **Reuse:** `LoginCubit`, `AuthenticationRepository.logIn()`, form validation models (`Email`, `Password`)
- **Gap:** Social login (Google/Apple/Facebook) — may need `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth` packages if not already implemented

### 1.4 Sign Up (Cook) — REFRESH (Medium effort)
- **Existing:** `lib/pages/signup/` (SignUpPage + SignUpCubit)
- **Design:** "Pull up a chair." heading, Full Name / Email or Phone / Password fields, gradient "Create Account X" button, social login (Google, Facebook), "Log in here" link, terms/privacy text
- **Work:** Update styling, add social login, warm tactile inputs
- **Reuse:** `SignUpCubit`, `AuthenticationRepository.signUp()`, form models

### 1.5 Sign Up Foodie — NEW SCREEN (Medium effort)
- **Existing:** None (currently shares cook signup)
- **Design:** "Join the Community" heading (miFoodi branding), Full Name / Email or Phone / Password / **Delivery Address** fields, gradient "Create Account X" button, social login, "Already a miFoodi? Log In" link
- **Work:** Create new `lib/pages/signup_foodie/` with view + cubit
- **Reuse:** `AuthenticationRepository.signUp()` (extend for delivery address), form models
- **New:** `SignUpFoodieCubit` (or extend `SignUpCubit` with address field), `SignUpFoodiePage`
- **Route:** Add `/SignUpFoodie` to `route_generator.dart`
- **Landing page update:** Two separate signup CTAs — one for cook, one for foodie

### 1.6 Forgot Password — REFRESH (Low effort)
- **Existing:** `lib/pages/forgot/` (ForgotPage + ForgotCubit)
- **Design:** "The Culinary Atelier" header branding, key icon, "Forgot Password?" heading, email input, gradient "Send Reset Link >" button, "Back to Login" link
- **Work:** Update styling, branding, input/button components
- **Reuse:** `ForgotCubit`, `AuthenticationRepository.forgot()`

### 1.7 Reset Link Sent — NEW SCREEN (Low effort)
- **Existing:** None
- **Design:** Success icon (pot with steam), "Check your email" heading, specific email shown (chef@mitabl.com), "Back to Login" primary button, "Resend Link" secondary button, Chef's Tip about spam folder
- **Work:** Create simple confirmation screen
- **Reuse:** Navigate from `ForgotCubit` success state, resend uses `AuthenticationRepository.forgot()` again
- **Route:** Add `/ResetLinkSent` to `route_generator.dart`

### 1.8 OTP Verification 1 (Phone) — REFRESH (Low effort)
- **Existing:** `lib/pages/otp/` (OtpPage + OtpCubit)
- **Design:** Lock icon, "Verify Identity" heading, "We sent a code to your phone", **4 digit** input boxes (warm filled style), gradient "Verify" button, "Resend Code" link, "SECURE 256-BIT ENCRYPTION" badge
- **Work:** Update Pinput styling to 4 digits, warm colors, add encryption badge
- **Reuse:** `OtpCubit`, `AuthenticationRepository.otpVerify()`

### 1.9 OTP Verification 2 (Email) — NEW VARIANT (Medium effort)
- **Existing:** Same `lib/pages/otp/` (not differentiated)
- **Design:** "Verify Identity" heading, "We've sent a 4-digit verification code to your culinary profile email", **5 wider circle** input fields, "Verify Code" button with checkmark, "RESEND CODE" link, decorative image of a plant, "JOIN THE MITABL ATELIER" text, "Contact Support" link
- **Work:** Create variant view `OtpEmailPage` or parameterize existing `OtpPage` to handle email flow (5 digits, different layout/footer)
- **Reuse:** `OtpCubit` (extend for email variant)
- **Route:** Add `/OTPEmailPage` or pass variant param via `RouteArguments`

### 1.10 Biometric Lock — REFRESH (Low effort)
- **Existing:** `lib/pages/common/biometric_lock_page.dart`
- **Design:** Lock icon top-left, "Mitabl" branding, fingerprint scanner with tonal circle layers, "Locked for your security", "Use Face ID or Fingerprint to unlock", "USE PASSWORD" fallback button, encryption messaging footer
- **Work:** Update visual design — tonal ring layers around fingerprint, warm colors, password fallback styling
- **Reuse:** `BiometricService` (authenticate, isEnabled)

---

## PHASE 2 — Foodie Core Experience

> **7 screens | 4 overhaul + 3 new**

### 2.1 Discovery Foodie Home — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/home/` (CarouselSlider sections, location input, filter dialog)
- **Design:** "Good evening, Alex" greeting with avatar, location selector (Brooklyn, NY), search bar "What are you craving?", **sticky category pills** (All, Mexican, Italian, Vegan), **cook cards** with:
  - Full-bleed hero food image
  - Overlapping cook avatar (bottom-left)
  - Rating badge (4.0)
  - Status badges ("Trending", "Vegan Friendly", "Selling fast")
  - Cook name + description
  - Distance (1.2 mi) + Ready time (6:30 PM) + Price tier ($$)
- **Work:** Complete UI rebuild. Replace CarouselSlider with vertical scrolling cook cards. Add greeting header, search, category pills, new card layout.
- **Reuse:** `HomeCubit` (recommended, top-rated, nearby logic), `HomeRepository`, geolocation, `ProfileFoodieCubit` (for user name)
- **New widgets:** `CookCard` (hero image + overlapping avatar + badges), category pills bar
- **Gaps:**
  - Category filtering API (may need new query parameter)
  - "Trending" / "Selling fast" badge logic (API field needed)
  - Ready time / price tier data (may need API changes)
  - Search functionality (may need search API endpoint)

### 2.2 Search Filters — NEW SCREEN (Medium effort)
- **Existing partial:** `lib/pages/home/elements/filter_dialog.dart` (dialog)
- **Design:** Full-screen page — "What are you craving today?" header, search bar, **Cuisine** grid with images (Italian, Japanese, Indian, Mexican + View All), **Dietary Preferences** chips (Vegan, Vegetarian, Gluten-Free, Keto, Pescatarian), **Distance** slider (1km-20km with "Within 8km" label), **Price Range** selector ($, $$, $$$, $$$$), Clear All / Apply Filters buttons
- **Work:** Create full-screen filter page with cuisine image grid, dietary chips, distance slider, price selector
- **Reuse:** Existing filter logic from `HomeCubit`, cooking style data from `CookRepository`
- **New:** `SearchFiltersCubit` for managing filter state, cuisine image assets
- **Route:** Add `/SearchFilters` to `route_generator.dart`

### 2.3 Cook Profile Menu (Customer View) — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/ordering/view/order_menu_page.dart` (basic list layout)
- **Design:** "Maria's Oaxacan Kitchen" — hero food image (full-bleed), rating (4.9, 120+ reviews, 1.2 mi), cook description text, **segmented tabs** (Menu | About), "Specials Today" section header, menu items with:
  - Item name + description
  - Price ($14.50)
  - Dietary badges (VEGAN DF)
  - Item images
  - Quantity counter (+/- when added)
  - Category sections (Sides & Drinks)
- **Floating cart button:** "View Cart" with item count + total ($24.00)
- **Work:** Rebuild with hero header, segmented tab bar, categorized menu sections, floating cart
- **Reuse:** `OrderingRepository.fetchKitchen()`, `fetchMenu()`, cart state from `OrderSessionController`, `StarRating`
- **New widgets:** Segmented tab bar, menu item card with inline quantity, floating cart summary bar

### 2.4 Menu Item Details — NEW SCREEN (Medium effort)
- **Existing:** None
- **Design:** Full-bleed food image hero (vegetables), back button overlay, badge ("MAIN"), "Braised Heritage Short Rib" title, price ($38.00), info row (40 min, Main Course, 4.8 rating), Description text, Key Ingredients list, Lineage Diet tags, Kitchen Performance stats (+19%)
- **Work:** Create detail view with hero image, item info, ingredients, dietary info
- **Reuse:** Menu models from `food_menu.dart`, `OrderingRepository`
- **New:** `MenuItemDetailsCubit` or extend ordering state
- **Route:** Add `/MenuItemDetails` to `route_generator.dart`

### 2.5 Cart Checkout — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/ordering/view/order_cart_page.dart` + `order_checkout_page.dart`
- **Design:** "Checkout" header with cook name, **Pickup/Delivery toggle**, order items with:
  - Item image (circular)
  - Name, special instructions, quantity (x2)
  - Price, +/- buttons
  - "Add more items" CTA
- **Pickup info:** Time slot + location + "Map" link
- **Receipt breakdown:** Subtotal ($36.50) + Taxes ($3.10) + Community Fee ($1.50) = Total ($41.10)
- **Slide to Pay:** Custom slider with skillet icon and total amount
- **Work:** Merge cart + checkout into unified flow, add pickup/delivery toggle, slide-to-pay gesture
- **Reuse:** `OrderingRepository.placeOrder()`, cart models, Stripe integration
- **New widgets:** `SlideToAction` (slide-to-pay), pickup/delivery toggle
- **Gaps:** Delivery option (if not already in API), community fee concept

### 2.6 Order Confirmation — NEW SCREEN (Medium effort)
- **Existing:** None
- **Design:** "Success!" header with heart icon, green "Confirmed" badge, order number (#MF-8294021), Order Summary (items with quantities + prices), Total Amount ($36.50), Estimated Delivery (25-35 min), cook info (Studio Kitchen, address), "Track Order" primary button, "Back to Home" link
- **Work:** Create confirmation screen showing order summary post-purchase
- **Reuse:** Order response model from `ordering_models.dart`, navigation
- **Route:** Add `/OrderConfirmation` to `route_generator.dart`

### 2.7 Order Tracking — NEW SCREEN (High effort)
- **Existing:** None
- **Design:** "Order Status" header, **map** at top with location pin + 15 min badge, "Maria is cooking your meal" status headline, Order #042 + Mole Poblano, **Status timeline:**
  - Order Accepted (6:30 PM) ✓
  - Prep & Chopping (6:35 PM) ✓
  - Cooking — "Simmering the spices..." (active, animated)
  - Ready for Pickup (Estimated 7:00 PM)
- Cook profile card (Maria G., 4.3 rating, 1120+ meals) + "Message" button
- **Work:** Build tracking screen with map, status timeline, cook profile
- **Reuse:** Geolocator, order models
- **New:** `OrderTrackingCubit`, map widget
- **Gaps:**
  - Real-time order status API (WebSocket or polling)
  - Map integration — needs `google_maps_flutter` package
  - Messaging/chat feature (Message button)
- **Route:** Add `/OrderTracking` to `route_generator.dart`
- **New dependency:** `google_maps_flutter`

---

## PHASE 3 — Foodie Account & Social

> **8 screens | 5 overhaul/refresh + 3 new**

### 3.1 Edit Profile Foodie — REFRESH (Medium effort)
- **Existing:** `lib/pages/edit_profile_foodie/`
- **Design:** "Edit Profile" header, profile photo with "CHANGE PHOTO" overlay, Personal Details card (Full Name, Phone Number with country code, Email Address), Delivery Address (Home Address field), Preferences bento grid (Cuisine type: Mediterranean, Preferred Time: Dinner 7PM), gradient "SAVE CHANGES" button, bottom nav (Explore, Favourites, Payments, Profile)
- **Work:** Update layout with warm tactile cards, add preferences bento grid, update inputs
- **Reuse:** `ProfileFoodieCubit`, `UserRepository`, `image_picker`
- **Gap:** Cuisine preferences and preferred time fields (may need API update)

### 3.2 My Orders — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/miorders/` (basic ListTile list)
- **Design:** "My Orders" heading, **Ongoing/Past Orders** segmented tabs, order cards with:
  - Kitchen image (circular)
  - Kitchen name + date
  - Status badge (IN PROGRESS / Completed / Cancelled with colors)
  - Total amount
  - Action buttons: "Track Order" (ongoing) / "Reorder" (past) / "Order Details" / "Download Receipt"
- **Work:** Complete rebuild with segmented tabs, visual order cards, action buttons
- **Reuse:** `MiOrdersRepository`, order models
- **New:** Tab state management, order card widget, reorder functionality
- **Gap:** Reorder API, download receipt functionality

### 3.3 Order Details (Foodie View) — MAJOR OVERHAUL (High effort)
- **Existing:** Route exists (`/OrderDetails`)
- **Design (order_details shows COOK view):** Order #MC-8291, "IN PREPARATION" status badge, Customer Info (Eleanor Shellstrop, phone), Delivery Method (Doorstep Delivery, address), Order Items with images + prices + quantities, Subtotal + Delivery Fee = Total ($73.65), Cancel Order / Mark Ready buttons
- **Note:** The `order_details` design is actually the **cook-side** order detail view (has "Mark Ready" and "Cancel Order" buttons). The foodie-side order detail would be accessed from My Orders.
- **Work:** Build cook-side order detail view matching design; also ensure foodie-side has appropriate view
- **Reuse:** Order models, existing route arguments pattern

### 3.4 Favourites — MAJOR OVERHAUL (Medium effort)
- **Existing:** `lib/pages/favourites/` (basic ListTile list)
- **Design:** "Saved Kitchens" heading with subtitle, cook cards with:
  - Hero food image
  - Kitchen name + description
  - Rating (4.7)
  - Heart/unfavorite button
- "Looking for more?" CTA section with "Explore Now" button
- **Work:** Replace list with rich cook cards, add empty/CTA section
- **Reuse:** `FavouritesRepository`, `CookCard` widget (from Phase 0)

### 3.5 Payments — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages/payments/` (basic ListTile list + FAB)
- **Design:**
  - "miFoodi Rewards" section at top
  - **Visual credit cards** with gradients, card numbers (masked), bank names
  - Multiple cards in horizontal scroll
  - "Add New Card" button
  - "Recent Transactions" list with merchant icons, amounts, dates
  - "Save with miFoodi Card" promo banner
  - "Purchase Protection" badge
- **Work:** Complete rebuild — visual card carousel, transactions list, rewards section
- **Reuse:** `PaymentsRepository`, Stripe integration
- **New widgets:** Visual credit card widget, transaction list item
- **Gap:** Rewards system API, transaction history API (if not existing)

### 3.6 Add Payment Method — NEW SCREEN (Medium effort)
- **Existing:** `lib/pages/common/view/stripe_payment_method_page.dart` (different — webview-based)
- **Design:** "Add New Card" heading, "BANK-LEVEL SECURITY" badge, visual card preview (gradient card showing entered number), Card Number input (formatted XXXX XXXX XXXX XXXX), Expiry Date / CVC row, Cardholder Name, "Set as default payment method" checkbox, gradient "Save Card Securely" button, Visa/Mastercard/Stripe trust logos, "ENCRYPTED CONNECTION" footer
- **Work:** Native card input form (not webview), visual card preview that updates as user types
- **Reuse:** Stripe SDK for tokenization
- **Route:** Add `/AddPaymentMethod` to `route_generator.dart`

### 3.7 Submit a Review — NEW SCREEN (Medium effort)
- **Existing:** None
- **Design:** "How was the meal?" heading, Kitchen photo + name (Maria's Oaxacan Kitchen, Order #8821), **5-star** interactive selector with label ("Great"), "Write your experience" textarea, "Add photos" upload section, gradient "Submit Review" button, bottom nav
- **Work:** Create review form with interactive star rating, text input, photo upload
- **Reuse:** `StarRating` widget (make interactive/tappable), `image_picker`
- **New:** `ReviewCubit`, `ReviewRepository`
- **Route:** Add `/SubmitReview` to `route_generator.dart`
- **Gap:** Review submission API endpoint

### 3.8 Notification Center — NEW SCREEN (High effort)
- **Existing:** None
- **Design:** "Notifications" heading with "Stay updated with your culinary journey", "MARK ALL AS READ" button, notifications with:
  - Category badges: MI FOOD (orange), MI COOK (green)
  - Timestamps (2h ago, 45m ago)
  - Rich content (order accepted, new review, payout processing)
  - Icons per notification type
- **Weekly Digest** card: "You hosted 4 dinners this week. See your performance analytics." + "View Report" button
- Bottom nav: HOME, ORDERS, INBOX (active), PROFILE
- **Work:** Build notification list with categorization, read/unread state, weekly digest
- **Reuse:** `NotificationService` (FCM), existing notification models
- **New:** `NotificationCubit`, `NotificationRepository`
- **Route:** Add `/NotificationCenter` to `route_generator.dart`
- **Gap:** Notification history API, read/unread state API, weekly digest API

---

## PHASE 4 — Cook Onboarding

> **3 screens | 1 refresh + 2 new**

### 4.1 Become a miCook (Step 1/3) — REFRESH (Medium effort)
- **Existing:** `lib/pages/profile_signup_cook/`
- **Design:** "Step 1 of 3" header, "The Culinary Atelier Starts Here." heading, Kitchen Name input, Kitchen Story textarea, Cuisine Style selector (Artisan, Traditional, Fusion, Home-Comfort), Kitchen Specs selector (health certifications and safety standards), hero image with photo upload, progress bar (35% complete), "Next: Setup Payout >" button
- **Work:** Update styling, progress indicator, step navigation flow
- **Reuse:** `CookProfileCubit`, `UserRepository.startCookOnboarding()`
- **Note:** Design shows clear 3-step flow: 1) Kitchen Info → 2) Setup Payout → 3) Certification

### 4.2 Setup Payouts (Step 2/3) — NEW SCREEN (High effort)
- **Existing:** None
- **Design:** "STEP 2 COMPLETE" badge area, "Get paid for your Culinary Creations" heading, Stripe integration note, coins/bills hero image, **Identity** section (personal verification), **Bank Details** section (account info), **Verification** section with illustrated character (Zane), "Connect with Stripe" CTA
- **Work:** Stripe Connect onboarding flow — identity verification, bank account entry
- **Reuse:** `UserRepository.completeCookVendorAccountStep()`
- **Route:** Add `/SetupPayouts` to `route_generator.dart`
- **Gap:** Stripe Connect API integration, bank verification flow
- **New:** `PayoutSetupCubit`

### 4.3 Kitchen Certification (Step 3/3) — NEW SCREEN (Medium effort)
- **Existing:** None
- **Design:** "Kitchen Certification" heading, "Submit your kitchen compliance documents...", **Drag & drop file upload** area ("Drop your certifications here", supported formats, 10MB max), **Required Checklist** (Health & Safety Registration, Tax Residency, Food Building Certificate, Insurance, Product Certificate Labelling), **Uploaded Files** section, "Browse Files" button
- **Work:** File upload screen with document checklist, file picker
- **Reuse:** `image_picker` (for file picking), `UserRepository`
- **Route:** Add `/KitchenCertification` to `route_generator.dart`
- **Gap:** Document upload API endpoint, certification status tracking
- **New:** `CertificationCubit`, `CertificationRepository`
- **New dependency:** May need `file_picker` package for non-image documents

---

## PHASE 5 — Cook Dashboard & Operations

> **7 screens | 4 refresh/overhaul + 3 new**

### 5.1 Cook Dashboard — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages_cook/dashboard_cook/` (basic stats display)
- **Design:** **"Kitchen Live"** toggle (green dot, "Accepting orders"), metrics row: Active Orders (3) + Today's Earnings ($84.50), **Cooking Queue** with order tickets:
  - Ticket #042: Alex Rivera, 14:02 elapsed, Pickup 12pm, 2x Mole Poblano + 1x Elote Loco, Delay/Mark Ready buttons
  - Ticket #041: Sarah J., **3/15 elapsed** (DELAYED state, red accent), Pickup 12pm, drive-thru eating
  - Ticket #043: Michael T., 03:02 elapsed, Delivery, 1x Family Taco Pack, Chiles Refinance
- "Accept Order" button at bottom
- Bottom nav: Dashboard, Menu, Earnings, Profile
- **Work:** Complete rebuild — live toggle, metric cards, cooking queue ticket system with timer, color-coded states
- **Reuse:** `DashboardCookCubit` (extend significantly), `UserRepository.getDashboardData()`
- **New widgets:** `OrderTicketCard` (with timer, states: normal/delayed/just-in), `KitchenLiveToggle`
- **Gaps:**
  - Kitchen Live toggle API
  - Real-time cooking queue data (WebSocket/polling)
  - Order timer/elapsed tracking
  - Delay notification API

### 5.2 Order Requests — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/requests/`
- **Design:** "Order Requests" heading with subtitle, request cards with:
  - Customer avatar + name
  - Order items preview (Truffle Tagliatelle x4, Burrata Salad x1)
  - Total Amount ($64.00)
  - Reject (outline) / Accept (filled gradient) buttons
  - Multiple cards stacked
- **Work:** Update card design, button styling, avatar integration
- **Reuse:** `RequestsCubit`, `BookingsRepository`, `AcceptRejectDialog`

### 5.3 Order Rejection Reason — NEW SCREEN (Low effort)
- **Existing:** None
- **Design:** "Reject Order #1234" heading, "Please select a reason for declining this request", radio buttons: Kitchen too busy / Out of ingredients / Other, "MESSAGE TO THE FOODIE" textarea, "Confirm Rejection" gradient button, info notice about visibility impact
- **Work:** Simple form screen with radio selection + textarea
- **Reuse:** `RequestsCubit` (extend with rejection reason), existing reject flow
- **Route:** Add `/OrderRejectionReason` or implement as bottom sheet modal

### 5.4 Upcoming Bookings — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/upcoming_bookings/`
- **Design:** "Upcoming Bookings" heading with subtitle, booking cards with:
  - Customer avatar + name
  - Items preview icons (food images)
  - Amount ($77.14)
  - Status badge ("Paid to Progress")
  - Expand/action button
- **Work:** Update card design with avatar, image previews, status badges
- **Reuse:** `BookingsRepository.getUpcomingBookings()`, booking models

### 5.5 Past Bookings / History — MAJOR OVERHAUL (High effort)
- **Existing:** `lib/pages_cook/bookings/` (basic list)
- **Design:** "History" heading, booking history cards with customer name, items, price, date, rating. **Monthly Performance** card ($8,450 earnings summary), **Top Dishes** ranking with earnings per dish (Vegan Brunch $X, Seafood Pasta Nights $X, etc.), "Customer History" section
- **Work:** Rebuild with history cards + analytics summary + top dishes
- **Reuse:** `BookingsCubit`, `BookingsRepository.getBookings()`
- **Gap:** Monthly performance API, top dishes analytics API, earnings per dish

### 5.6 Revenue Analytics — NEW SCREEN (High effort)
- **Existing:** None
- **Design:** "Revenue Analytics" heading, **Monthly/Yearly** toggle tabs, total revenue ($12,482.50), "vs last month" comparison, **Orders chart** (bar chart, 1,240 orders), average order ($48.30), **Top Dishes** list with earnings, **Transaction History** list with date/amount
- **Work:** Full analytics dashboard with charts, metrics, transaction list
- **Reuse:** Dashboard data models (`dashboard_data.dart`)
- **New:** `RevenueCubit`, `AnalyticsRepository`
- **Route:** Add `/RevenueAnalytics` to `route_generator.dart`
- **Gap:** Analytics API endpoints, chart data format
- **New dependency:** `fl_chart` package for bar/line charts

### 5.7 Settings (Cook) — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/settings_page/`
- **Design:** "Chef Maria" profile header with avatar + "The Culinary Atelier" subtitle + ACTIVE/PRO TIER badges, **Account Preferences** (Personal Information, Language: English (United States), Login & Security), **Notifications** (Push Notifications toggle, Email Marketing toggle), **Support** (Help Center, Contact Support, Privacy Policy), gradient "Save All Changes" button, "Logout" link
- **Work:** Update settings sections with proper grouping, add language selector, notification toggles, support links
- **Reuse:** `SettingsCookCubit`, existing settings logic

---

## PHASE 6 — Cook Menu & Profile Management

> **5 screens | all refresh/overhaul**

### 6.1 Add Menu Item — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/add_menu_item/`
- **Design:** "Edit Menu Item" header with avatar, **Item Photography** section (4 photo slots with bento grid layout, MAX 4 PHOTOS label), Food Name input, Description textarea, Price ($) input, **Cooking Style & Dietary** section with chips (Home-style, Wood-fired, Slow-cooked, Fermented + Vegan, Gluten-free, Dairy-free, Nut-free), **Service Availability** toggles (Dine-in Experience ON, Take-away OFF), "Save Item" / "Discard" buttons
- **Work:** Update photo grid to bento layout, chip styling, toggle switches, button styling
- **Reuse:** `AddMenuCubit`, `CookRepository.addMenuItem()`, `SpecialDietCubit`, `cooking_style_dialog`

### 6.2 Kitchen Profile Settings — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/edit_kitchen_profile/`
- **Design:** "Edit Kitchen Profile" heading, subtitle "Manage how your culinary appears to 52...", cover photo, **General Information** (Kitchen Name, Location), **Round Space** indicator, **Kitchen Story** textarea, **Kitchen Gallery** image grid, **Operating Hours** link section, gradient save button
- **Work:** Update layout with warm tactile styling, gallery section, operating hours link
- **Reuse:** `EditKitchenProfileCubit`, existing kitchen profile logic

### 6.3 Operating Hours — MAJOR OVERHAUL (High effort)
- **Existing:** `timing_edit.dart` / `timing_dialog.dart` (basic time picker dialog)
- **Design:** Full "Operating Hours" page — per-day rows with:
  - Day label (MON, TUE, etc.)
  - Open/Closed toggle switch
  - Start Time / End Time pickers
  - **"Add break"** button (adds afternoon break slot)
  - Break display (e.g., "AFTERNOON BREAK" between time slots)
- **Quick Status** card: Weekly Total (54 Hours), Status (LIVE NOW)
- **Availability Density** mini chart (M-T-W-T-F-S-S bar chart)
- Pro tip about afternoon breaks
- **Work:** Complete rebuild — full page (not dialog), per-day configuration, break management, status summary, density chart
- **Reuse:** `timing_model.dart` (extend for breaks), existing timing logic
- **Gap:** Break time model fields, weekly hours calculation, availability density data
- **New dependency:** May need mini chart component (or custom painter)

### 6.4 Customer Reviews — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/customer_reviews/`
- **Design:** "miCook Vendor" header, **Overall Rating** (4.9, 5 stars, 128 reviews), star distribution bars (5★ to 1★), "Sort by Date" dropdown, **Latest Feedback** review cards with:
  - Customer avatar + name
  - Star rating + date
  - Review text
  - Dish tags (partially visible)
- **Work:** Add rating distribution bars, sort functionality, update review cards with avatars
- **Reuse:** Existing review page, `StarRating` widget

### 6.5 User Details — REFRESH (Medium effort)
- **Existing:** `lib/pages_cook/user_details_page/`
- **Design:** Customer profile — "Jameson Carter" with avatar, "Valued Customer" badge, "Savings Foodie" tag, stats (24 orders, Avg Rating 4.9), **Favorite Dishes** list with images + names, **Customer Preferences** chips (Spice Level 3/5, Gluten-Free, Dairy-Free, Crispy & Fried, Comfort, Weekend Diner), "Order #1014" bottom reference
- **Work:** Update with badges, stats display, favorite dishes section, preference chips
- **Reuse:** Existing user details logic, user models

---

## PHASE 7 — Cross-Cutting Concerns

> **1 screen**

### 7.1 Offline State — NEW FULL SCREEN (Low effort)
- **Existing:** `lib/helper/offline_error_widget.dart` (inline banner widget)
- **Design:** Full standalone screen — chef illustration (wearing hat, arms crossed), "Oops! It looks like you're offline." heading, "Please check your internet connection and try again." subtitle, gradient "Retry" button, outline "BACK TO DASHBOARD" button
- **Work:** Create new `OfflineStatePage` as a full-screen experience. Keep existing `OfflineErrorWidget` banner for inline use.
- **Reuse:** `ConnectivityService` for detection, existing retry logic
- **New:** Custom chef illustration asset (or use existing/generate), `OfflineStatePage`

---

## Identified Gaps & New Dependencies

### New Flutter Packages Required

| Package | Purpose | Phase | Priority |
|---|---|---|---|
| `fl_chart` | Revenue analytics charts, availability density | 5, 6 | Medium |
| `google_maps_flutter` | Order tracking map view | 2 | High |
| `file_picker` | Kitchen certification document upload | 4 | Medium |
| `google_sign_in` | Social login (Google) | 1 | Medium |
| `sign_in_with_apple` | Social login (Apple) | 1 | Medium |
| `flutter_facebook_auth` | Social login (Facebook) | 1 | Low |
| `shimmer` (optional) | Loading skeleton placeholders | 0 | Low |

### New API Endpoints Required

| Endpoint | Purpose | Phase |
|---|---|---|
| POST `/api/v2/reviews` | Submit review with rating, text, photos | 3 |
| GET `/api/v2/notifications` | Notification history list | 3 |
| PUT `/api/v2/notifications/read` | Mark notifications read | 3 |
| GET `/api/v2/notifications/digest` | Weekly digest summary | 3 |
| GET `/api/v2/orders/{id}/tracking` | Real-time order status | 2 |
| GET `/api/v2/analytics/revenue` | Revenue data by period | 5 |
| GET `/api/v2/analytics/top-dishes` | Top performing dishes | 5 |
| GET `/api/v2/analytics/monthly-performance` | Monthly earnings summary | 5 |
| POST `/api/v2/certifications` | Upload certification documents | 4 |
| POST `/api/v2/payouts/setup` | Stripe Connect payout setup | 4 |
| PUT `/api/v2/kitchen/live-status` | Toggle kitchen live/offline | 5 |
| POST `/api/v2/orders/{id}/reject` | Reject order with reason | 5 |
| GET `/api/v2/orders/{id}/queue` | Cooking queue data | 5 |
| POST `/api/v2/orders/{id}/delay` | Mark order delayed | 5 |
| POST `/api/v2/orders/{id}/ready` | Mark order ready | 5 |
| GET `/api/v2/search` | Search cooks/dishes | 2 |
| GET `/api/v2/categories` | Cuisine categories with images | 2 |
| POST `/api/v2/auth/social` | Social login (Google/Apple/FB) | 1 |

### New Repositories to Create

| Repository | Purpose | Phase |
|---|---|---|
| `ReviewRepository` | Submit/fetch reviews | 3 |
| `NotificationRepository` | Notification history, read state, digest | 3 |
| `AnalyticsRepository` | Revenue data, top dishes, performance | 5 |
| `CertificationRepository` | Document upload, checklist status | 4 |
| `SearchRepository` | Search and advanced filtering | 2 |

### New Cubits to Create

| Cubit | Purpose | Phase |
|---|---|---|
| `SignUpFoodieCubit` | Foodie-specific signup with address | 1 |
| `SearchFiltersCubit` | Full-screen filter state | 2 |
| `MenuItemDetailsCubit` | Menu item detail view | 2 |
| `OrderTrackingCubit` | Real-time order tracking | 2 |
| `OrderConfirmationCubit` | Post-order confirmation state | 2 |
| `ReviewCubit` | Review submission flow | 3 |
| `NotificationCubit` | Notification list management | 3 |
| `PayoutSetupCubit` | Payout onboarding flow | 4 |
| `CertificationCubit` | Certification upload flow | 4 |
| `RevenueCubit` | Analytics data & period filtering | 5 |
| `CookingQueueCubit` | Real-time cooking queue | 5 |

### New Routes to Register in `route_generator.dart`

```
/SignUpFoodie
/ResetLinkSent
/OTPEmailPage (or parameterize existing)
/SearchFilters
/MenuItemDetails
/OrderConfirmation
/OrderTracking
/AddPaymentMethod
/SubmitReview
/NotificationCenter
/SetupPayouts
/KitchenCertification
/OrderRejectionReason
/RevenueAnalytics
/OfflineState
/OperatingHours (full page, not dialog)
```

---

## Execution Order & Dependencies

```
PHASE 0 (Foundation) ──────────────────────────► MUST complete first
    │                                             Creates shared widgets,
    │                                             theme, bottom nav shell
    │
    ├── PHASE 1 (Auth & Onboarding) ───────────► Independent, start here
    │       │
    │       ├── PHASE 2 (Foodie Core) ─────────► Depends on Phase 1
    │       │       │                             Discovery, ordering flow
    │       │       │
    │       │       └── PHASE 3 (Foodie Account)► Depends on Phase 2
    │       │                                     Profile, orders, reviews
    │       │
    │       ├── PHASE 4 (Cook Onboarding) ─────► Depends on Phase 1
    │       │       │                             3-step cook setup
    │       │       │
    │       │       ├── PHASE 5 (Cook Ops) ────► Depends on Phase 4
    │       │       │                             Dashboard, queue, analytics
    │       │       │
    │       │       └── PHASE 6 (Cook Menu) ───► Depends on Phase 4
    │       │                                     Menu, profile, hours
    │       │
    │       └── PHASE 7 (Cross-cutting) ───────► Can run anytime after Phase 0
    │                                             Offline state
```

**Parallelization opportunities:**
- Phases 2 and 4 can run in parallel (Foodie vs Cook tracks)
- Phases 3, 5, and 6 can run in parallel after their prerequisites
- Phase 7 can run anytime after Phase 0

---

## Reuse Opportunities

### Existing Code to Preserve and Extend

| Component | Location | Reuse Strategy |
|---|---|---|
| All Cubits | `lib/pages/*/cubit/` | Extend with new fields/methods, don't replace |
| All Repositories | `lib/repos/` | Add methods, don't restructure |
| Form validation models | `lib/model/email.dart`, `password.dart`, etc. | Reuse across all new forms |
| `AuthAwareHttpClient` | `lib/repos/auth_aware_http_client.dart` | All new repos must use this |
| `ConnectivityService` | `lib/helper/connectivity_service.dart` | Wrap all new screens |
| `NotificationService` | `lib/helper/notification_service.dart` | Add new notification types |
| `BiometricService` | `lib/helper/biometric_service.dart` | Already integrated |
| `DeepLinkService` | `lib/helper/deep_link_service.dart` | Add new deep link routes |
| `RouteArguments` | `lib/helper/route_arguement.dart` | Use for all new route params |
| `FormzStatus` pattern | All cubits | Continue using for new cubits |
| `ApiContract` | `lib/helper/api_contract.dart` | Add new endpoint paths |
| `AppBlocObserver` | `lib/helper/app_bloc_observer.dart` | Works with all new cubits |

### Design System Anti-Patterns to Remove

| Current Pattern | Replace With |
|---|---|
| Drop shadows on cards | Tonal layering (surface-container-lowest on surface-container-low) |
| 1px divider lines between list items | 1.4rem spacing gaps or alternating background tints |
| Standard 4px/8px border radius | 20px (cards) or 100px pill (buttons) |
| Pure black (#000000) text | `on-surface` (#1C1C19) |
| Bottom border on inputs | Filled inputs with no border, surface-container-low background |
| MaterialButton | `MitablButton` with gradient pill shape |

---

## Estimated Effort Summary

| Phase | Screens | New | Overhaul | Refresh | Effort |
|---|---|---|---|---|---|
| **Phase 0** | Foundation | — | — | — | **High** (blockers all phases) |
| **Phase 1** | 11 | 3 | 1 | 7 | **Medium-High** |
| **Phase 2** | 7 | 3 | 4 | 0 | **Very High** |
| **Phase 3** | 8 | 3 | 4 | 1 | **High** |
| **Phase 4** | 3 | 2 | 0 | 1 | **Medium** |
| **Phase 5** | 7 | 3 | 2 | 2 | **Very High** |
| **Phase 6** | 5 | 0 | 1 | 4 | **Medium** |
| **Phase 7** | 1 | 1 | 0 | 0 | **Low** |
| **TOTAL** | **42** | **15** | **12** | **15** | |

---

## How to Use This Plan

1. **Start with Phase 0** — no exceptions. Every screen depends on the foundation.
2. **For each screen**, open the corresponding `screen.png` for visual reference and `code.html` for HTML structure hints.
3. **Check existing code first** — read the current implementation before writing new code.
4. **Create shared widgets once** — `MitablCard`, `MitablButton`, etc. should be built in Phase 0 and reused everywhere.
5. **Extend, don't replace** — keep existing cubits and repositories, add to them.
6. **Verify API availability** — check backend API before building screens that need new endpoints. Flag gaps to backend team.

> **Design Reference:** Always consult `design-artifacts/D-Design-System/mobile-appdesign/warm_tactile_mitabl/DESIGN.md` for design tokens, principles, and anti-patterns.
