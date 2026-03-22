# Mitabl Mobile App — Architecture & User Flow Document

> **Document Type:** Technical Architecture + UX Flow Specification
> **Platform:** Flutter (iOS & Android)
> **Last Updated:** 2026-03-19
> **Contributors:** Architect Agent, UX Designer Agent

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [User Roles & Personas](#2-user-roles--personas)
3. [Application Architecture](#3-application-architecture)
4. [Screen Inventory](#4-screen-inventory)
5. [Navigation & Routing](#5-navigation--routing)
6. [User Flows — miFoodi (Customer)](#6-user-flows--mifoodi-customer)
7. [User Flows — miCook (Vendor)](#7-user-flows--micook-vendor)
8. [Cross-Role Flows](#8-cross-role-flows)
9. [State Management](#9-state-management)
10. [API Integration Map](#10-api-integration-map)
11. [Data Models](#11-data-models)
12. [Security & Session Management](#12-security--session-management)
13. [Platform Features](#13-platform-features)
14. [Current Gaps & Opportunities](#14-current-gaps--opportunities)

---

## 1. Product Overview

**Mitabl** is a two-sided home-cooked food marketplace connecting home cooks (miCooks) with food enthusiasts (miFoodis). The mobile app is the primary customer-facing interface, supporting both roles within a single binary with role-based navigation switching.

**Core Value Proposition:**
- Authentic home cooking discovery (not restaurant/delivery aggregation)
- Community-focused connection between cooks and diners
- Flexible dining: Dine-in at home kitchens or Take-away
- Cook empowerment with business management tools

**Tech Stack:**
- Flutter (cross-platform), Dart
- BLoC/Cubit state management
- JWT authentication
- Stripe payment processing
- Firebase Cloud Messaging (push notifications)

---

## 2. User Roles & Personas

### 2.1 miFoodi (Customer) — Role ID: 3

| Attribute | Detail |
|-----------|--------|
| **Primary Goal** | Discover and order authentic home-cooked food |
| **Key Actions** | Browse kitchens, order food, pay, rate & review |
| **Entry Point** | Home/Discovery page after login |
| **Service Types** | Dine-in, Take-away |

### 2.2 miCook (Vendor) — Role ID: 2

| Attribute | Detail |
|-----------|--------|
| **Primary Goal** | Run a micro-kitchen business from home |
| **Key Actions** | Manage menu, accept/reject orders, track earnings |
| **Entry Point** | Dashboard with bottom navigation after login |
| **Business Tools** | Menu management, booking management, analytics |

### 2.3 Role Switching

Users can hold **both roles simultaneously** and switch between them in-app via `POST /api/v2/account/switch-role`. The switch changes the entire navigation shell — from the foodie discovery layout to the cook dashboard and vice versa.

---

## 3. Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        main.dart                             │
│               (Firebase init, Repository setup)              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                        app.dart                              │
│      (MultiRepositoryProvider, AuthenticationBloc,           │
│       MaterialApp, Theme, Route Generator)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
     ┌────────▼────────┐  ┌────────▼────────┐
     │   pages/         │  │  pages_cook/     │
     │   (miFoodi UI)   │  │  (miCook UI)     │
     └────────┬────────┘  └────────┬────────┘
              │                     │
     ┌────────▼────────┐  ┌────────▼────────┐
     │   cubit/         │  │   cubit/         │
     │   (State mgmt)   │  │   (State mgmt)   │
     └────────┬────────┘  └────────┬────────┘
              │                     │
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │     repos/           │
              │  (Data repositories, │
              │   HTTP client,       │
              │   Auth headers)      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Backend API        │
              │   (Laravel / JWT)    │
              └──────────────────────┘
```

**Key Architectural Patterns:**
- **Clean separation**: `pages/` (miFoodi screens) vs `pages_cook/` (miCook screens)
- **BLoC/Cubit pattern**: Each feature has its own Cubit for state management
- **Repository pattern**: All API calls abstracted behind repository interfaces
- **Auth-aware HTTP**: `AuthAwareHttpClient` auto-injects JWT tokens on every request
- **Session monitoring**: `SessionRepository` watches for 401s and triggers auto-logout

---

## 4. Screen Inventory

### 4.1 Shared / Authentication Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Splash | `/Splash` | App launch, update check, auth status detection |
| Landing Page | `/LandingPage` | Welcome screen with Login/Sign Up options |
| Login | `/LoginPage` | Phone/email + password authentication |
| Sign Up | `/SignUpPage` | New account registration |
| OTP Verification | `/OTPPage` | Email OTP verification post-registration |
| Forgot Password | `/ForgotPage` | Password reset flow |
| Biometric Lock | `/BiometricLockPage` | Fingerprint/Face ID lock screen |

### 4.2 miFoodi (Customer) Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Home / Discovery | `/HomePage` | Browse nearby, recommended, top-rated kitchens |
| Order Menu | `/OrderMenu` | Browse a kitchen's menu items |
| Order Cart | `/OrderCart` | Review cart, select dine-in/take-away, time slot |
| Order Checkout | `/OrderCheckout` | Payment method selection, place order |
| My Orders | `/MiOrders` | Order history and status tracking |
| Favourites | `/Favourites` | Saved/bookmarked kitchens |
| Payments | `/Payments` | Saved cards and payment history |
| Profile | `/ProfileFoodie` | View personal profile |
| Edit Profile | `/EditProfileFoodie` | Edit personal details |
| Cook Profile (view) | `/CookProfile` | View a cook's public profile from discovery |
| Stripe Payment Method | `/StripePaymentMethod` | Add/manage Stripe payment methods |

### 4.3 miCook (Vendor) Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Dashboard | `/DashboardCook` | Main hub — 4-tab bottom navigation |
| — Tab 1: Dashboard | (tab) | Revenue analytics, metrics overview |
| — Tab 2: Menu | (tab) | List of all menu items |
| — Tab 3: Requests | (tab) | Incoming orders to accept/reject |
| — Tab 4: Profile | (tab) | Cook profile overview |
| Add/Edit Menu Item | `/AddMenuPage` | Create or edit a food item |
| Menu Item Details | `/MenuDetails` | View single menu item |
| Profile Cook | `/ProfileCook` | Personal + Kitchen tabs |
| Edit Profile Cook | `/EditProfileCook` | Edit personal details |
| Edit Kitchen Profile | `/EditKitchenProfile` | Edit miKitchn settings |
| Bookings (Past) | `/Bookings` | Completed order history |
| Upcoming Bookings | `/UpcomingBookings` | Scheduled future orders |
| Customer Reviews | `/CustomerReviewPage` | View customer feedback |
| User Details | `/UserDetails` | View customer info for an order |
| Order Details | `/OrderDetails` | Full order details |
| Settings | `/SettingsCook` | Account settings |

---

## 5. Navigation & Routing

### 5.1 App Entry Decision Tree

```
APP LAUNCH
    │
    ▼
┌─────────┐
│ Splash   │──→ Check app version (update gate)
└────┬────┘
     │
     ▼
 ┌───────────────┐
 │ Auth Status?   │
 └───┬───────┬───┘
     │       │
 (Logged In) (Not Logged In)
     │       │
     ▼       ▼
 ┌────────┐ ┌──────────┐
 │ Role?  │ │ Landing  │
 └─┬────┬─┘ │ Page     │
   │    │   └──────────┘
   │    │
(Cook) (Foodi)
   │    │
   ▼    ▼
┌────┐ ┌──────┐
│Dash│ │ Home │
│Cook│ │ Page │
└────┘ └──────┘
```

### 5.2 Role Detection Logic

The app determines the user's role using normalized lowercase matching:
- **Cook role**: `'restaurant'`, `'cook'`, `'micook'`, `'mikitchn'`, `'kitchen'`, `'vendor'` → routes to `/DashboardCook`
- **Foodie role**: All other values → routes to `/HomePage`

### 5.3 Bottom Navigation (Cook Dashboard)

```
┌────────────┬──────────┬──────────────┬──────────┐
│  Dashboard │   Menu   │   Requests   │ Profile  │
│  (Tab 0)   │ (Tab 1)  │   (Tab 2)    │ (Tab 3)  │
└────────────┴──────────┴──────────────┴──────────┘
```

---

## 6. User Flows — miFoodi (Customer)

### 6.1 Registration & Onboarding

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Landing  │───→│ Sign Up  │───→│   OTP    │───→│  Home    │
│ Page     │    │ Page     │    │ Verify   │    │ (Discov) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                     │
                 Collects:
                 - Name
                 - Email/Phone
                 - Password
                 - Address
```

**Post-registration state:** User is authenticated with Role 3 (Foodie) and lands on the Discovery home page.

### 6.2 Login Flow

```
┌──────────┐    ┌──────────┐    ┌──────────────────┐
│ Landing  │───→│  Login   │───→│ Home (Foodie)    │
│ Page     │    │  Page    │    │   OR              │
└──────────┘    └──────────┘    │ Dashboard (Cook)  │
                     │          └──────────────────┘
                 Inputs:
                 - Phone/Email
                 - Password
```

**Branching:** After successful login, the app checks the user's active role and navigates accordingly.

### 6.3 Password Reset

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Login    │───→│ Forgot   │───→│  Reset   │───→│  Login   │
│ Page     │    │ Password │    │  (Email) │    │ Page     │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### 6.4 Discovery & Browsing (Core Loop)

```
┌───────────────────────────────────────────────────┐
│                 HOME PAGE                          │
│                                                    │
│  ┌─────────────────────────────────────────────┐  │
│  │  Search Bar (location-based)                │  │
│  └─────────────────────────────────────────────┘  │
│                                                    │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │   Nearest   │  │ Recommended  │  │Top Rated │ │
│  │   Kitchens  │  │   Kitchens   │  │ Kitchens │ │
│  └──────┬──────┘  └──────┬───────┘  └────┬─────┘ │
│         │                │               │        │
│         └────────────────┼───────────────┘        │
│                          │                         │
│                    Tap Kitchen                     │
│                          │                         │
└──────────────────────────┼─────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Cook Profile │ (public view)
                    │  - Kitchen info
                    │  - Rating
                    │  - Images
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  Order Menu  │
                    └──────────────┘
```

**Discovery Filters:**
- Cuisine / Cooking style
- Price range
- Rating
- Distance / Location
- Dietary restrictions (vegan, gluten-free, etc.)

**API Endpoints Used:**
- `GET /api/v2/discovery/nearest` — Geo-location based
- `GET /api/v2/discovery/recommended` — Personalized recommendations
- `GET /api/v2/discovery/top-rated` — Highest rated
- `GET /api/v2/discovery/search` — Text search
- `GET /api/v2/discovery/filtered` — Combined filters

### 6.5 Ordering Flow (Critical Path)

```
┌──────────────────────────────────────────────────────────────┐
│  STEP 1: MENU BROWSING (/OrderMenu)                          │
│                                                               │
│  Kitchen: "Nana's Kitchen" ★ 4.8                             │
│  ┌────────────────────────────────────┐                      │
│  │  🍲 Butter Chicken — $18.50       │  [+] Add to Cart     │
│  │  🥘 Dal Makhani — $14.00          │  [+] Add to Cart     │
│  │  🍚 Biryani — $22.00              │  [+] Add to Cart     │
│  └────────────────────────────────────┘                      │
│                                                               │
│  [View Cart (3 items — $54.50)]                              │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  STEP 2: CART REVIEW (/OrderCart)                             │
│                                                               │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Service Type:   ○ Dine-In    ○ Take-Away        │        │
│  └──────────────────────────────────────────────────┘        │
│                                                               │
│  IF DINE-IN:                                                  │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Select Time Slot:   [6:00 PM - 7:00 PM ▼]      │        │
│  │  Number of Persons:  [2 ▼]                        │        │
│  │  Available Seats:    4 remaining                   │        │
│  └──────────────────────────────────────────────────┘        │
│                                                               │
│  IF TAKE-AWAY:                                                │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Pickup Time:        [6:30 PM ▼]                  │        │
│  └──────────────────────────────────────────────────┘        │
│                                                               │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Items:         $54.50                            │        │
│  │  GST:           $5.45                             │        │
│  │  Total:         $59.95                            │        │
│  └──────────────────────────────────────────────────┘        │
│                                                               │
│  [Proceed to Checkout]                                        │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  STEP 3: CHECKOUT (/OrderCheckout)                            │
│                                                               │
│  Payment Method:                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │  ○ Visa ****4242 (saved)                          │        │
│  │  ○ Mastercard ****8888 (saved)                    │        │
│  │  ○ Add New Card                                   │        │
│  └──────────────────────────────────────────────────┘        │
│                                                               │
│  [Place Order — $59.95]                                       │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  STEP 4: ORDER CONFIRMATION                                   │
│                                                               │
│  "Order #1234 placed successfully!"                          │
│  Status: REQUESTED (awaiting kitchen confirmation)            │
│                                                               │
│  [Track Order in My Orders]                                   │
└──────────────────────────────────────────────────────────────┘
```

**Order State Machine (Customer View):**
```
REQUESTED ──→ CONFIRMED ──→ IN_PROGRESS ──→ COMPLETED
    │              │
    ▼              ▼
CANCELLED      CANCELLED
```

### 6.6 Order Management

```
┌──────────────────────────────────────────────────────────────┐
│  MY ORDERS (/MiOrders)                                        │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Order #1234 — Nana's Kitchen                      │      │
│  │  Status: CONFIRMED  |  Dine-in 6:00 PM            │      │
│  │  Total: $59.95      |  2 persons                   │      │
│  │  [View Details]  [Cancel]                          │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Order #1201 — Mama's Bistro                       │      │
│  │  Status: COMPLETED  |  Take-away                   │      │
│  │  Total: $35.00                                     │      │
│  │  [View Details]  [Rate & Review]                   │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### 6.7 Favourites

```
Home Page ──→ Tap Heart on Kitchen ──→ Saved to Favourites
                                            │
Favourites Page ◄───────────────────────────┘
    │
    ▼
Tap Kitchen ──→ Cook Profile ──→ Order Menu
```

### 6.8 Profile & Settings

```
┌──────────────────────────────────────────────────────────────┐
│  PROFILE (/ProfileFoodie)                                     │
│                                                               │
│  [Edit Profile]  → Name, Phone, Photo, Address               │
│  [Change Password]                                            │
│  [Biometric Auth]  → Enable/Disable fingerprint               │
│  [Payment Methods]  → Manage saved cards                      │
│  [Switch to miCook]  → Role switch                            │
│  [Logout]                                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## 7. User Flows — miCook (Vendor)

### 7.1 Cook Onboarding

```
┌──────────┐    ┌───────────────┐    ┌───────────────┐    ┌──────────────┐
│ Sign Up  │───→│ Complete      │───→│ Upload        │───→│ Setup Payout │
│ (Role 2) │    │ Kitchen       │    │ Kitchen       │    │ (Stripe      │
│          │    │ Profile       │    │ Certificate   │    │  Onboarding) │
└──────────┘    └───────────────┘    └───────────────┘    └──────┬───────┘
                     │                                            │
                 Collects:                                        ▼
                 - Kitchen name                           ┌──────────────┐
                 - Address/Location                       │  Dashboard   │
                 - Description                            │  (Activated) │
                 - Operating hours                        └──────────────┘
                 - Dine-in/Take-away
                 - Time slots & capacity
                 - Kitchen images
```

**Onboarding API Sequence:**
1. `POST /api/v2/onboarding/cook/start` — Begin onboarding
2. `POST /api/v2/mikitchn/store` — Create kitchen profile
3. `POST /api/v2/onboarding/cook/vendor-account` — Setup Stripe vendor
4. `POST /api/v2/roles/cook/activate` — Activate cook role

### 7.2 Dashboard (Daily Operations Hub)

```
┌──────────────────────────────────────────────────────────────┐
│  DASHBOARD (/DashboardCook)                                   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  TAB 1: DASHBOARD (Analytics)                         │    │
│  │                                                       │    │
│  │  Total Earnings:  $2,450.00                           │    │
│  │  Orders This Week: 23                                 │    │
│  │  Average Rating:   4.7 ★                              │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  TAB 2: MENU                                          │    │
│  │                                                       │    │
│  │  [+ Add New Item]                                     │    │
│  │  Butter Chicken — $18.50  [Edit] [Delete]             │    │
│  │  Dal Makhani — $14.00     [Edit] [Delete]             │    │
│  │  Biryani — $22.00         [Edit] [Delete]             │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  TAB 3: REQUESTS (Incoming Orders)                    │    │
│  │                                                       │    │
│  │  NEW REQUEST #1234                                    │    │
│  │  Customer: John D.  |  Dine-in 6:00 PM               │    │
│  │  Items: 3  |  Total: $59.95                           │    │
│  │  [Accept]  [Reject]                                   │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  TAB 4: PROFILE                                       │    │
│  │                                                       │    │
│  │  Kitchen: "Nana's Kitchen"                            │    │
│  │  Rating: 4.8 ★  |  Reviews: 45                        │    │
│  │  [Edit Personal]  [Edit Kitchen]  [Settings]          │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌─────────┬─────────┬──────────┬─────────┐                 │
│  │Dashboard│  Menu   │ Requests │ Profile │  ← Bottom Nav   │
│  └─────────┴─────────┴──────────┴─────────┘                 │
└──────────────────────────────────────────────────────────────┘
```

### 7.3 Menu Management Flow

```
Dashboard (Menu Tab)
    │
    ├───→ [+ Add New Item] ──→ /AddMenuPage
    │                              │
    │                          Collects:
    │                          - Food name
    │                          - Description
    │                          - Price
    │                          - Photos (multiple)
    │                          - Cooking style
    │                          - Dietary options
    │                          - Available days
    │                          - Available hours
    │                          - Dine-in / Take-away toggle
    │                              │
    │                              ▼
    │                          [Save Item]
    │                              │
    │                              ▼
    │                          Return to Menu Tab
    │
    ├───→ [Edit] on existing item ──→ /AddMenuPage (edit mode)
    │
    └───→ [Tap item] ──→ /MenuDetails (read-only view)
```

### 7.4 Order Fulfillment Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Push        │────→│ Requests Tab │────→│ Order Details    │
│  Notification│     │ (new order)  │     │ (/OrderDetails)  │
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                    │
                                          ┌─────────┼─────────┐
                                          │                    │
                                     [Accept]             [Reject]
                                          │                    │
                                          ▼                    ▼
                                   ┌──────────────┐    ┌──────────────┐
                                   │ CONFIRMED    │    │ CANCELLED    │
                                   │ → Upcoming   │    │ (with reason)│
                                   │   Bookings   │    └──────────────┘
                                   └──────┬───────┘
                                          │
                                   (Prepare food)
                                          │
                                          ▼
                                   ┌──────────────┐
                                   │ IN_PROGRESS  │
                                   └──────┬───────┘
                                          │
                                   (Serve/hand off)
                                          │
                                          ▼
                                   ┌──────────────┐
                                   │ COMPLETED    │
                                   │ → Bookings   │
                                   │   (history)  │
                                   └──────────────┘
```

**Order Status Codes:**
| Code | Status | Description |
|------|--------|-------------|
| 0 | LEGACY_CANCELLED | Legacy cancelled state |
| 1 | COMPLETED | Order fulfilled |
| 2 | REQUESTED | Awaiting kitchen acceptance |
| 3 | CONFIRMED | Accepted by kitchen |
| 4 | CANCELLED | Cancelled (either party) |
| 5 | IN_PROGRESS | Being prepared |

### 7.5 Kitchen Profile Management

```
Profile Tab
    │
    ├───→ Personal Tab
    │        │
    │        └───→ [Edit] ──→ /EditProfileCook
    │                          - Name, Phone, Photo
    │
    └───→ Kitchen Tab
             │
             └───→ [Edit] ──→ /EditKitchenProfile
                                - Kitchen name
                                - Address / Location
                                - Description
                                - Operating hours (per day)
                                - Dine-in toggle + slots
                                - Take-away toggle
                                - Seat capacity
                                - Kitchen images
                                - GST/ABN certification
```

### 7.6 Booking Management

```
┌──────────────────────────────────────────────────────────────┐
│  UPCOMING BOOKINGS (/UpcomingBookings)                        │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Order #1234 — John D.                             │      │
│  │  Dine-in | 6:00 PM - 7:00 PM | 2 persons          │      │
│  │  Items: Butter Chicken, Dal, Biryani               │      │
│  │  Total: $59.95  |  Status: CONFIRMED               │      │
│  │  [View Details]  [Mark In Progress]                │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  PAST BOOKINGS (/Bookings)                                    │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Order #1201 — Sarah M.                            │      │
│  │  Take-away | Completed Mar 18                      │      │
│  │  Total: $35.00  |  Paid: Yes                       │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

---

## 8. Cross-Role Flows

### 8.1 Role Switching

```
miFoodi Profile                      miCook Dashboard
┌──────────────┐                    ┌──────────────┐
│ [Switch to   │───── API Call ────→│ Dashboard    │
│  miCook]     │  switch-role       │ (Cook View)  │
└──────────────┘                    └──────────────┘

miCook Profile                       miFoodi Home
┌──────────────┐                    ┌──────────────┐
│ [Switch to   │───── API Call ────→│ Home Page    │
│  miFoodi]    │  switch-role       │ (Discovery)  │
└──────────────┘                    └──────────────┘
```

**Important:** If a user has never been a cook, switching to cook triggers the onboarding flow (Section 7.1).

### 8.2 Become a Cook (Foodie → Cook Registration)

```
Foodie Profile
    │
    └───→ [Become a miCook] ──→ /ProfileSignupCook
                                    │
                                Collects:
                                - Kitchen details
                                - Certification
                                - Payout info
                                    │
                                    ▼
                              Cook Onboarding
                              (Section 7.1)
```

---

## 9. State Management

### 9.1 Architecture: BLoC/Cubit Pattern

```
┌───────────────┐     ┌──────────┐     ┌──────────────┐
│  UI (Widget)  │────→│  Cubit   │────→│  Repository  │
│  (Listens to  │     │  (Logic) │     │  (Data)      │
│   state)      │◄────│  (Emits  │◄────│  (API calls) │
│               │     │   state) │     │              │
└───────────────┘     └──────────┘     └──────────────┘
```

### 9.2 Key State Managers

| Cubit/Bloc | Scope | Manages |
|-----------|-------|---------|
| `AuthenticationBloc` | Global | Auth state, user session, login/logout |
| `HomeCubit` | miFoodi | Discovery data, filters, search results |
| `ProfileFoodieCubit` | miFoodi | Customer profile data |
| `DashboardCookCubit` | miCook | Tab selection, dashboard metrics |
| `ProfileCookCubit` | miCook | Cook + kitchen profile data |
| `AddMenuCubit` | miCook | Menu item form state |
| `RequestsCubit` | miCook | Incoming order requests |
| `BookingsCubit` | miCook | Booking history data |
| `LoginCubit` | Auth | Login form validation |
| `SignUpCubit` | Auth | Registration form validation |
| `OtpCubit` | Auth | OTP verification state |

### 9.3 Form Validation

Uses `formz` package for declarative form validation with `FormzStatus`:
- `pure` — untouched
- `valid` / `invalid` — validation state
- `submissionInProgress` — loading
- `submissionSuccess` / `submissionFailure` — result

---

## 10. API Integration Map

### 10.1 Authentication APIs

| Action | Method | Endpoint |
|--------|--------|----------|
| Register | POST | `/api/register` |
| Verify OTP | POST | `/api/verifyOtp` |
| Resend OTP | POST | `/api/resendotp` |
| Login | POST | `/api/login` |
| Logout | POST | `/api/v2/logout` |
| Refresh Token | POST | `/api/token/refresh` |
| Reset Password | POST | `/api/password/reset` |

### 10.2 miFoodi (Customer) APIs

| Action | Method | Endpoint |
|--------|--------|----------|
| Get Profile | GET | `/api/v2/account/profile` |
| Update Profile | PUT | `/api/v2/account/profile` |
| Nearest Kitchens | GET | `/api/v2/discovery/nearest` |
| Recommended | GET | `/api/v2/discovery/recommended` |
| Top Rated | GET | `/api/v2/discovery/top-rated` |
| Search | GET | `/api/v2/discovery/search` |
| Filtered Results | GET | `/api/v2/discovery/filtered` |
| Restaurant Details | GET | `/api/v2/discovery/restaurants/{id}` |
| Restaurant Menu | GET | `/api/v2/discovery/restaurants/{id}/menu` |
| Dine-in Slots | GET | `/api/v2/discovery/restaurants/{id}/dine-in-slots` |
| Place Order | POST | `/api/v2/orders` |
| My Orders | GET | `/api/v2/account/orders` |
| Favourites | GET | `/api/v2/account/favorites` |
| Toggle Favourite | POST | `/api/v2/account/favorites/toggle` |
| Payment Cards | GET | `/api/v2/payments/cards` |
| Add Card | POST | `/api/v2/payments/cards` |
| Payment Intent | POST | `/api/v2/payments/intent` |
| Confirm Payment | POST | `/api/v2/payments/intent/confirm` |
| Payment History | GET | `/api/v2/account/payments/history` |

### 10.3 miCook (Vendor) APIs

| Action | Method | Endpoint |
|--------|--------|----------|
| Create Kitchen | POST | `/api/v2/mikitchn/store` |
| Edit Kitchen | POST | `/api/v2/mikitchn/editkitchen` |
| Get Kitchen Profile | GET | `/api/v2/getprofile` |
| My Menu | GET | `/api/v2/mymenu` |
| Add Food | POST | `/api/v2/food/add` |
| Edit Food | POST | `/api/v2/food/editfood` |
| Delete Food | DELETE | `/api/v2/food/{id}` |
| Order Requests | GET | `/api/v2/kitchenorderrequest` |
| Upcoming Orders | GET | `/api/v2/kitchenupcomingorders` |
| All Orders | GET | `/api/v2/allorders` |
| Update Order Status | POST | `/api/v2/updateorderstatus` |
| Dashboard Data | GET | `/api/v2/account/dashboard` |
| Activate Cook Role | POST | `/api/v2/roles/cook/activate` |
| Start Onboarding | POST | `/api/v2/onboarding/cook/start` |
| Vendor Account | POST | `/api/v2/onboarding/cook/vendor-account` |
| Vendor Bank Account | POST | `/api/v2/payments/vendor/bank-account` |
| Stripe Onboarding Link | GET | `/api/v2/payments/vendor/onboarding-link` |

---

## 11. Data Models

### 11.1 Core Entities

```
┌────────────┐       ┌─────────────┐       ┌────────────┐
│   User     │──1:N─→│  UserRole   │──N:1─→│   Role     │
│            │       │ (status)    │       │ (Cook,     │
│ - id       │       └─────────────┘       │  Foodie)   │
│ - name     │                              └────────────┘
│ - email    │
│ - phone    │       ┌─────────────┐
│ - address  │──1:1─→│  Mikitchn   │
│ - role     │       │ (Kitchen)   │
└────────────┘       │ - name      │
                     │ - address   │
                     │ - lat/lng   │
                     │ - dine_in   │
                     │ - take_away │
                     │ - rating    │
                     │ - images[]  │
                     │ - timings[] │
                     └──────┬──────┘
                            │
                         1:N│
                            ▼
                     ┌─────────────┐
                     │   Foods     │
                     │ - name      │
                     │ - price     │
                     │ - desc      │
                     │ - images[]  │
                     │ - diets[]   │
                     │ - styles[]  │
                     │ - days[]    │
                     │ - hours     │
                     └──────┬──────┘
                            │
                         N:M│ (via OrderData)
                            ▼
                     ┌─────────────┐       ┌─────────────┐
                     │   Order     │──1:1─→│  Payment    │
                     │ - status    │       │ - stripe_id │
                     │ - type      │       │ - amount    │
                     │ - date/time │       │ - status    │
                     │ - persons   │       └─────────────┘
                     │ - total     │
                     │ - customer  │       ┌─────────────┐
                     │ - kitchen   │──1:N─→│  Review     │
                     └─────────────┘       │ - rating    │
                                           │ - comment   │
                                           └─────────────┘
```

### 11.2 Supporting Entities

| Entity | Purpose |
|--------|---------|
| `CookingStyle` | Cuisine categories (Italian, Indian, etc.) |
| `SpecialDiet` | Dietary tags (Vegan, Gluten-free, Halal, etc.) |
| `DineInSlot` | Time slots with seat capacity for dine-in bookings |
| `Certificate` | Kitchen certifications (ABN, GST) |
| `Image` | Polymorphic image storage for kitchens & foods |
| `Timing` | Kitchen operating hours per day |
| `Favorite` | User-kitchen bookmark associations |
| `PromoCode` | Discount codes with validity windows |
| `SupportTicket` | Help desk tickets with SLA tracking |
| `Card` | Saved Stripe payment cards |
| `Transfer` | Vendor payout records |
| `Refund` | Order refund tracking |

---

## 12. Security & Session Management

### 12.1 Authentication Architecture

```
┌──────────┐    ┌──────────────────┐    ┌──────────────────┐
│  Login   │───→│ JWT Token        │───→│ Secure Storage   │
│          │    │ (access_token)   │    │ (FlutterSecure   │
│          │    │                  │    │  Storage)         │
└──────────┘    └──────────────────┘    └──────────────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ AuthAwareHttp    │ ← Injects Bearer token
                │ Client           │   on every API request
                └────────┬─────────┘
                         │
                    On 401 Response
                         │
                         ▼
                ┌──────────────────┐
                │ SessionRepository│ ← Triggers logout
                │ (monitors auth)  │   & redirect to Landing
                └──────────────────┘
```

### 12.2 Security Features

| Feature | Implementation |
|---------|---------------|
| **Token Storage** | `FlutterSecureStorage` (encrypted) |
| **Auto-logout** | 401 response detection via `SessionRepository` |
| **Biometric Auth** | Optional fingerprint/Face ID via `local_auth` |
| **Biometric Lock** | Lock screen shown on app resume if enabled |
| **Token Migration** | One-time migration from `SharedPreferences` to secure storage |
| **Rate Limiting** | Server-side on login, OTP, token refresh endpoints |
| **Role Guards** | Server middleware: `customer`, `restaurant`, `api.user.active` |

---

## 13. Platform Features

### 13.1 Push Notifications

```
Firebase Cloud Messaging
    │
    ├──→ New order request (Cook)
    ├──→ Order status update (Foodie)
    ├──→ Order accepted/rejected (Foodie)
    └──→ Deep link to specific screen
```

- Device token synced via `POST /api/v2/account/device-token`
- Notification preferences configurable
- Deep linking from notification tap to relevant screen

### 13.2 Offline Handling

- `ConnectivityService` monitors network status in real-time
- Offline banner displayed at top of app when disconnected
- Graceful error handling on failed API calls
- Retry mechanisms available

### 13.3 Deep Linking

- `DeepLinkService` handles incoming deep links
- Navigation to specific orders, kitchens, profiles
- Works from cold start and foreground state

### 13.4 App Update Gate

- `UpdateCheckService` checks `GET /api/app/version` on splash
- Non-blocking prompt if update available
- Can enforce critical updates

---

## 14. Current Gaps & Opportunities

### 14.1 Identified Gaps (from gap analysis)

| Area | Gap |
|------|-----|
| **Ordering** | No real-time order tracking beyond status polling |
| **Payments** | Limited refund flow in mobile app |
| **Search** | No advanced text search for individual food items |
| **Reviews** | Review submission flow exists but limited UX |
| **Notifications** | No in-app notification centre (relies on push only) |
| **Cancellation** | Limited cancellation policy enforcement in UI |
| **Chat** | No in-app messaging between cook and foodie |

### 14.2 UX Opportunities

| Opportunity | Impact |
|-------------|--------|
| **Onboarding tutorial** | First-time user guidance for both roles |
| **Order tracking timeline** | Visual progress indicator for order status |
| **Cook availability calendar** | Weekly view of kitchen operating schedule |
| **Menu item recommendations** | AI-powered "you might like" suggestions |
| **Reorder functionality** | Quick reorder from past orders |
| **Scheduled ordering** | Book future meals in advance |
| **Social proof** | Show live activity ("3 people ordered in the last hour") |

---

## Appendix: Complete Flow Diagram

```
                        ┌──────────────┐
                        │   APP START  │
                        │   (Splash)   │
                        └──────┬───────┘
                               │
                     ┌─────────┴─────────┐
                     │                   │
                (Authenticated)    (Not Authenticated)
                     │                   │
                     │            ┌──────▼───────┐
                     │            │ Landing Page │
                     │            └───┬──────┬───┘
                     │                │      │
                     │          [Login]  [Sign Up]
                     │                │      │
                     │          ┌─────▼─┐  ┌─▼──────┐
                     │          │ Login │  │Sign Up │
                     │          └───┬───┘  └───┬────┘
                     │              │          │
                     │              │     ┌────▼────┐
                     │              │     │  OTP    │
                     │              │     │ Verify  │
                     │              │     └────┬────┘
                     │              │          │
                     └──────────────┼──────────┘
                                   │
                          ┌────────▼────────┐
                          │   ROLE CHECK    │
                          └───┬─────────┬───┘
                              │         │
                         (FOODI)    (COOK)
                              │         │
                    ┌─────────▼──┐  ┌───▼──────────┐
                    │  HOME PAGE │  │  DASHBOARD   │
                    │ (Discovery)│  │  (4 Tabs)    │
                    └─────┬──────┘  └───┬──────────┘
                          │             │
            ┌─────────────┼──────┐      ├─── Dashboard (Analytics)
            │             │      │      ├─── Menu Management
            ▼             ▼      ▼      ├─── Order Requests
        ┌────────┐  ┌────────┐ ┌──────┐ └─── Profile & Kitchen
        │Nearest │  │Recomm. │ │Top   │
        │Kitchns │  │Kitchns │ │Rated │
        └───┬────┘  └───┬────┘ └──┬───┘
            └────────────┼────────┘
                         │
                    ┌────▼─────┐
                    │  Kitchen │
                    │  Profile │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │  Order   │
                    │  Menu    │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │  Order   │
                    │  Cart    │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ Checkout │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │  Order   │
                    │ Complete │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │My Orders │
                    │(History) │
                    └──────────┘
```

---

*Document generated by analyzing the live codebase — all screens, routes, APIs, and flows reflect the current implementation as of 2026-03-19.*
