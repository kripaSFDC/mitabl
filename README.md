# mitabl

**mitabl** is a marketplace platform that revolutionises home cooking by connecting foodies (customers) with home cooks who operate virtual kitchens ("miKitchens"). Customers can discover nearby home-cooked meals, book time slots, order food, and pay securely while cooks manage their kitchen profile, menu, bookings, and earnings from a single app.

> Note: Salesforce integration has been removed in Phase 5 cutover. Current cutover evidence and release controls are in `docs/phase5_validation_report.md` and `docs/phase5_release_runbook.md`.

---

## Repository Structure

```
mitabl/
├── backend/        # Laravel REST API :  core business logic and mobile API
├── mobile-app/     # Flutter cross-platform app : iOS & Android for foodies and cooks
└── website/        # Laravel marketing website : public-facing web presence
```

---

## 1. `backend/`  REST API Server

### Functional Overview

The backend is the central engine of the mitabl platform. It exposes a JSON REST API consumed by the mobile app. It handles all business logic including user registration and authentication (with OTP verification), kitchen (miKitchen) profile management, food menu CRUD, order lifecycle management (request → accept → complete → pay out), Stripe payment processing, review and rating collection, push notifications, and internal CRM intake workflows plus Filament-based operations/admin modules.

### Tech Stack

| Layer              | Technology                                           |
| ------------------ | ---------------------------------------------------- |
| Language           | PHP 7.3 / 8.0                                        |
| Framework          | Laravel 8                                            |
| Authentication     | JWT (`tymon/jwt-auth` v1)                            |
| Payments           | Stripe SDK (`stripe/stripe-php` v8) + Stripe Connect |
| API Documentation  | Swagger / OpenAPI (`darkaonline/l5-swagger` v8)      |
| CORS               | `fruitcake/laravel-cors`                             |
| Favourites         | `overtrue/laravel-favorite` v4                       |
| Database           | MySQL (via `pdo_mysql`)                              |
| ORM                | Laravel Eloquent                                     |
| HTTP Client        | Guzzle 7                                             |
| Queue / Events     | Laravel Queue, Events, Listeners                     |
| Push Notifications | Firebase Cloud Messaging (FCM)                       |
| Container          | Docker (PHP 7.4-FPM image)                           |
| Testing            | PHPUnit 9                                            |

### Architecture

The backend follows the standard **Laravel MVC** pattern with an additional Resource layer for API response shaping:

```
routes/api.php
    └── Middleware (JwtMiddleware, Customer, Restaurant)
        └── Http/Controllers/Api/
            ├── User/UserController          # Auth, profile, Stripe account
            ├── MikitchnController           # Kitchen profile, dashboard, search
            ├── FoodsController              # Menu item CRUD
            ├── OrderController              # Full order lifecycle
            ├── PaymentController            # Stripe payment helpers
            ├── ReviewController             # Reviews ↔ foodies & cooks
            ├── FavoriteController           # Favourite kitchens
            ├── FcmController                # Push notification retrieval
            ├── ForgotPasswordController     # Password reset flow
            └── WebApiToCurlController       # Pre-registration / contact proxy
```

**Middleware roles:**

- `JwtMiddleware`  validates JWT token on every authenticated route
- `Customer`  gates routes to foodie users only
- `Restaurant`  gates routes to kitchen operator users only

**API response shaping** uses Laravel API Resources (`Http/Resources/`) split into `User/`, `Restaurant/`, `Order/`, and `Reviews/` namespaces to keep response contracts clean.

### Key Functional Components

#### Authentication & Users (`User` model, `UserController`)

- OTP-based phone/email verification at registration (`verifyOtps` table)
- JWT token issuance/refresh/logout
- Dual-role accounts: a user can be both a **Foodie** (customer) and a **Cook** (kitchen operator) and switch between roles (`becomecook` / `becomefoodie` endpoints)
- Device token management for FCM push messages
- Password reset via email link

#### miKitchen Profiles (`Mikitchn` model, `MikitchnController`)

- Cooks create a kitchen profile with name, address, images, cooking styles, special diets, opening hours (`Timing` model), and dine-in availability
- Kitchen availability toggle (`updateopenmikitchen`)
- Certificate upload & ABN/GST fields with local approval workflows
- Dashboard data endpoint aggregating revenue, order counts, and ratings

#### Food Menu (`Foods` model, `FoodsController`)

- Cooks add/edit/delete menu items with images, price, and availability status
- Customers retrieve paginated menus per kitchen

#### Order Lifecycle (`Order`, `OrderData`, `CompletedOrder` models, `OrderController`)

- Foodies create an order with a selected date/time slot
- `getBookedDates` / `checkBookedTimeByDate` prevent double-booking
- Status machine: `requested → accepted/rejected → completed`
- Promo code validation (`PromoCode` model) with discounted-user tracking
- Completed orders archived to `completed_orders` table

#### Payments (`Payment`, `Transfer`, `Refund`, `Card`, `StripeAccount`, `StripeBankAccount` models)

- Stripe Connect: cooks onboard via the Connect OAuth flow (`onboardingLink`)
- Customers pay via Stripe Payment Intents or Checkout sessions
- Funds held on platform; payout to cook via `transfertovendor`
- Full refund endpoint with `Refund` tracking
- Top-up capability for platform wallet
- Card management (add/list cards per customer)

#### Notifications (`FcmController`, `Mail/`, `Notifications/`)

- Firebase FCM push notifications for new orders, kitchen verification, and order status changes
- Email notifications: OTP, registration welcome, password reset, invoice, refund invoice, kitchen activation, account deletion confirmation
- In-app notification feed (stored in `notifications` table)

#### Reviews & Ratings (`Review` model, `ReviewController`)

- Foodies leave reviews on kitchens (linked to a completed order)
- Cooks leave reviews on foodies
- Reviews stored with `by_user` flag to distinguish direction

#### Favourites (`Favorite` model, `FavoriteController`)

- Toggle and list favourite kitchens per user (polymorphic via `overtrue/laravel-favorite`)

#### Discovery & Search (`MikitchnController`)

- `nearestRestaurant`  geo-proximity search
- `topRatedRestaurant`  sorted by aggregated review scores
- `recommendedRestaurant`  personalised recommendation feed
- `filterRestaurant`  filter by cooking style, special diet, etc.

#### CRM and Admin Operations (Post-Cutover)

- Salesforce dependencies were removed.
- Support/lead intake stays on compatibility endpoints (/api/preregister, /api/mobcontact) and persists locally.
- Internal approval and operations workflows are served through the Filament admin modules.

### Database Schema Highlights

50+ migrations covering: `users`, `roles`, `verify_otps`, `mikitchns`, `foods`, `cooking_styles`, `special_diets`, `timings`, `images`, `certificates`, `orders`, `order_data`, `completed_orders`, `promo_codes`, `payments`, `transfers`, `refunds`, `cards`, `stripe_accounts`, `stripe_bank_accounts`, `reviews`, `favorites`, `notifications`, `cancel_reasons`, `partners`, `user_auth_tokens`.

### Setup

```bash
composer update && npm install
cp .env.example .env
php artisan key:generate
php artisan jwt:secret
php artisan migrate
php artisan db:seed
php artisan optimize:clear
composer dump-autoload
# Permissions
chmod -R 777 storage bootstrap public
# Run
php artisan serve   # localhost:8000
```

**Docker:**

```bash
docker build -t mitabl-backend .
docker run -p 8000:8000 mitabl-backend
```

---

## 2. `mobile-app/`  Flutter Mobile App

### Functional Overview

A cross-platform Flutter application (iOS + Android) that serves both **Foodies** (customers discovering and ordering home-cooked meals) and **Cooks** (home kitchen operators managing their business). The app provides two distinct UX flows within a single binary, switchable at the account level.

### Tech Stack

| Layer            | Technology                       |
| ---------------- | -------------------------------- |
| Language         | Dart (SDK ≥2.16.2)               |
| Framework        | Flutter                          |
| State Management | BLoC / Cubit (`flutter_bloc` v8) |
| Value Equality   | `equatable` v2                   |
| Config           | `global_configuration`           |
| Local Storage    | `shared_preferences` v2          |
| Fonts            | `google_fonts` v2.3.2            |
| Form Validation  | `formz` v0.4                     |
| SVG Rendering    | `flutter_svg` v1                 |
| Toast Messages   | `fluttertoast` v8                |
| Image Picking    | `image_picker` v0.8              |
| Network Images   | `cached_network_image` v3        |
| OTP Input        | `pinput` v2                      |
| Rating Widget    | `flutter_rating_bar` v4          |
| Carousel         | `carousel_slider` v4             |
| Toggles          | `flutter_switch` v0.3            |
| Date/Time        | `intl` v0.17                     |
| URL Handling     | `url_launcher` v6                |
| Target Platforms | iOS, Android                     |

### Architecture

The app follows a **BLoC (Business Logic Component)** pattern with a clean separation of layers:

```
lib/
├── main.dart                  # App entry point, global config injection
├── app.dart                   # MaterialApp, theme, BLoC providers
├── splash.dart                # Splash screen
├── route_generator.dart       # Centralised named-route factory
│
├── auth_bloc/                 # Global authentication BLoC (token lifecycle)
│   └── authentication/
│
├── model/                     # Pure Dart data models (API response DTOs)
│
├── repos/                     # Repository layer  all API calls abstracted
│   ├── authentication_repository.dart
│   ├── home_repository.dart
│   ├── cook_repository.dart
│   ├── bookings_repository.dart
│   └── user_repository.dart
│
├── helper/                    # Shared utilities (route args, etc.)
│
├── pages/                     # Foodie (customer) screens
│   ├── landing_page/          # App entry / role selector
│   ├── login/                 # Login with JWT
│   ├── signup/                # Registration
│   ├── otp/                   # OTP verification
│   ├── forgot/                # Forgot password
│   ├── home/                  # Main discovery feed
│   ├── profile_foodie/        # Foodie public profile
│   ├── edit_profile_foodie/   # Edit foodie profile
│   └── profile_signup_cook/   # Cook profile onboarding
│
└── pages_cook/                # Cook (kitchen operator) screens
    ├── dashboard_cook/        # Revenue & stats dashboard
    ├── home_page/             # Cook home
    ├── menu/                  # Full menu list
    ├── menu_detail/           # Single item detail
    ├── add_menu_item/         # Add / edit menu item
    ├── edit_kitchen_profile/  # Edit miKitchen profile
    ├── edit_profile_cook/     # Edit cook personal profile
    ├── profile_cook/          # Cook public profile
    ├── requests/              # Incoming order requests
    ├── bookings/              # All bookings history
    ├── upcoming_bookings/     # Upcoming confirmed bookings
    ├── customer_reviews/      # Reviews left by foodies
    ├── user_details_page/     # Customer detail for a booking
    └── settings_page/         # Notification toggles, logout, etc.
```

### Key Functional Components

#### Global Auth BLoC (`auth_bloc/`)

Manages the JWT authentication state across the entire app. Persists tokens via `shared_preferences` and drives navigation between authenticated and unauthenticated states.

#### Repository Layer (`repos/`)

All network I/O is isolated here, keeping BLoC/Cubit classes free of HTTP concerns. Repositories map JSON responses to typed Dart model classes.

#### Data Models (`model/`)

Strongly-typed DTOs for all API entities: `UserModel`, `KitchenProfile`, `FoodMenu`, `NearByRestaurantsResponse`, `TopRatedRestResponse`, `RecommendedRestResponse`, `BookingsModel`, `RequestsModel`, `DashboardData`, `TimingModel`, `CookingStyle`, `SpecialDiet`, and more.

#### Foodie Flow

1. **Discovery** (`home/`)  carousel of recommended kitchens, nearby and top-rated lists, search/filter
2. **Kitchen detail**  view kitchen profile, menu, reviews, and availability
3. **Booking & Order**  select date and time slot, build cart, apply promo code
4. **Payment**  Stripe Payment Intent integration
5. **Reviews**  rate and review a kitchen after order completion
6. **Profile**  manage personal info and past orders
7. **Favourites**  save and revisit favourite kitchens

#### Cook Flow

1. **Onboarding**  complete kitchen profile, upload certificate, set cooking styles, special diets, and opening hours
2. **Dashboard** (`dashboard_cook/`)  earnings summary, order counts, rating snapshot
3. **Menu management** (`menu/`, `add_menu_item/`)  add/edit/delete items, toggle availability
4. **Order requests** (`requests/`)  accept or reject incoming foodie orders, view order details
5. **Bookings** (`bookings/`, `upcoming_bookings/`)  full booking history and upcoming schedule
6. **Reviews** (`customer_reviews/`)  view reviews left by foodies
7. **Settings** (`settings_page/`)  notification preferences, logout, account management

#### Assets (`assets/`)

- `cfg/`  global configuration files (API base URL, environment settings)
- `img/`  bundled image assets
- `fonts/`  custom font files

### Setup

```bash
flutter pub get
flutter run          # Connect a device or start an emulator first
flutter build apk    # Android release build
flutter build ios    # iOS release build
```

---

## 3. `website/`  Marketing Website

### Functional Overview

A Laravel-powered marketing and landing website for mitabl. It serves static and near-static public-facing pages to introduce the platform to prospective foodies and cooks, collect interest registrations, and provide legal documentation. It does not replicate the mobile app's functionality  its role is brand presence and customer acquisition.

### Tech Stack

| Layer              | Technology                     |
| ------------------ | ------------------------------ |
| Language           | PHP 7.3 / 8.0                  |
| Framework          | Laravel 8                      |
| Templating         | Blade                          |
| Payments (billing) | `laravel/cashier` v13 (Stripe) |
| Authentication     | JWT (`tymon/jwt-auth` v1)      |
| Favourites         | `overtrue/laravel-favorite` v4 |
| API Docs           | `darkaonline/l5-swagger` v8    |
| Frontend Build     | Laravel Mix / Webpack          |
| Testing            | PHPUnit 9                      |

### Architecture

The website follows standard **Laravel MVC** with Blade views. There is no SPA layer  all pages are server-rendered:

```
routes/web.php
    └── Blade views (resources/views/)
        ├── layouts/           # Shared layout templates (header, footer, nav)
        ├── includes/          # Reusable partials (hero sections, etc.)
        ├── frontend/          # Public page views
        │   ├── home.blade.php
        │   ├── about.blade.php
        │   ├── contact.blade.php
        │   └── registration.blade.php
        ├── mob/               # Mobile-specific contact page
        │   └── contact.blade.php
        ├── privacy.blade.php  # Privacy policy
        ├── terms.blade.php    # Terms & conditions
        ├── savecard.blade.php # Stripe card save flow (utility)
        └── savebank.blade.php # Stripe bank account save flow (utility)

routes/api.php
    └── Api/WebApiToCurlController
        ├── preRegister        # Proxy pre-registration interest form
        └── mobContact         # Proxy mobile contact form
```

### Key Functional Components

#### Public Pages

| Route             | View                    | Purpose                                      |
| ----------------- | ----------------------- | -------------------------------------------- |
| `/`               | `frontend/home`         | Hero landing page with platform introduction |
| `/about`          | `frontend/about`        | About mitabl story and mission               |
| `/register`       | `frontend/registration` | Pre-registration interest form for new users |
| `/contact`        | `frontend/contact`      | Contact form for web visitors                |
| `/mob-contact`    | `mob/contact`           | Contact form optimised for in-app WebView    |
| `/privacy-policy` | `privacy`               | GDPR / privacy policy document               |
| `/terms`          | `terms`                 | Terms and conditions document                |

#### API Proxy (`WebApiToCurlController`)

Two lightweight API endpoints proxy form submissions (pre-registration and mobile contact) to backend processing logic, enabling the marketing site to share logic with the main API.

#### Stripe Cashier Integration

`laravel/cashier` is included for potential Stripe billing and subscription management on the web  e.g., handling subscription callbacks or saving payment methods for web-initiated flows.

#### Data Models (shared subset)

The website shares a partial domain model with the backend for read-only context: `User`, `Mikitchn`, `Foods`, `Order`, `OrderData`, `Review`, `Favorite`, `CookingStyles`, `SpecialDiet`, `PromoCode`, `Role`, `verifyOtp`.

### Setup

```bash
composer install && npm install
cp .env.example .env
php artisan key:generate
php artisan optimize:clear
composer dump-autoload
chmod -R 777 storage bootstrap public
php artisan serve   # localhost:8000
```

---

## Platform Integration Map

```
┌─────────────────────┐         HTTPS / JSON API          ┌──────────────────────────┐
│   mobile-app/       │ ◄────────────────────────────────► │      backend/            │
│   Flutter App       │   JWT-authenticated REST calls      │   Laravel 8 REST API     │
│                     │                                     │                          │
│  Foodie screens     │                                     │  Auth (JWT + OTP)        │
│  Cook screens       │                                     │  miKitchen management    │
│  BLoC state mgmt    │                                     │  Order lifecycle         │
│  Stripe Pay Intent  │                                     │  Stripe Connect payouts  │
└─────────────────────┘                                     │  FCM push notifications  │
                                                            │  Swagger API docs        │
┌─────────────────────┐         HTTPS / JSON API           └──────────┬───────────────┘
│   website/          │ ◄─── preRegister / mobContact ────────────────┘
│   Laravel Website   │
│                     │
│  Marketing pages    │
│  Legal docs         │
│  Interest capture   │
└─────────────────────┘

       External Services used by backend/
       ├── Stripe  payments & Connect payouts
       ├── Firebase FCM  push notifications
       └── Filament Admin Portal  internal operations workflows
```

---

---

## 4. Salesforce Cutover Status

Salesforce has been fully removed from runtime integration paths.

Current state:
- No Salesforce-protected API routes remain in backend runtime.
- `/api/preregister` and `/api/mobcontact` are compatibility aliases to local persistence.
- Legacy Salesforce middleware/controller/listener/model artifacts are removed.
- `sales_kitchens` is dropped via cutover migration.
- Environment templates no longer include `SALESFORCE_*` secrets.

Operational evidence and release controls:
- `docs/phase5_validation_report.md`
- `docs/phase5_release_runbook.md`
- `deploy/scripts/verify-no-salesforce-traffic.ps1`
## Key Concepts Glossary

| Term                  | Meaning                                                        |
| --------------------- | -------------------------------------------------------------- |
| **miKitchen**         | A home cook's registered kitchen profile on the platform       |
| **Foodie**            | A customer who orders home-cooked meals                        |
| **Cook / Restaurant** | A miKitchen operator (same user, different role)               |
| **Ops Admin**         | Internal operations/admin users working in Filament portal     |
| **Booking**           | A time-slot reservation attached to an order                   |
| **Cooking Style**     | Cuisine category tag (e.g., Italian, Indian) set on a kitchen  |
| **Special Diet**      | Dietary tag (e.g., Vegan, Gluten-free) set on a kitchen        |
| **Promo Code**        | Discount code applicable at order checkout                     |
| **Stripe Connect**    | Split-payment mechanism that routes funds to kitchen operators |



