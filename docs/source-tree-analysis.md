# mitabl — Source Tree Analysis

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive

---

## Complete Project Structure

```
mitabl/                                    # Monorepo root
├── backend/                               # Laravel 12 API + Filament Admin Panel
│   ├── app/
│   │   ├── Console/
│   │   │   └── Commands/                  # Artisan commands (cron jobs, reconciliation)
│   │   ├── Events/                        # Domain events (CancelOrderRefund, MakeOrderPayment)
│   │   ├── Exceptions/                    # Exception handler
│   │   ├── Filament/                      # Admin panel (Filament v3)
│   │   │   ├── Pages/                     # Admin pages (Login, CRM Workspace, Health, IAM, etc.)
│   │   │   │   └── Auth/                  # Custom admin authentication page
│   │   │   ├── Resources/                 # CRUD resources (12 total)
│   │   │   │   ├── AdminActionLogResource/  # Immutable audit log viewer
│   │   │   │   ├── CertificateResource/     # Kitchen certificate review
│   │   │   │   ├── MicookResource/          # Cook user management
│   │   │   │   ├── MifoodieResource/        # Foodie user management
│   │   │   │   ├── MikitchnResource/        # Kitchen management
│   │   │   │   ├── OrderResource/           # Order management
│   │   │   │   ├── PaymentResource/         # Payment visibility
│   │   │   │   ├── PolicyResource/          # Policy version governance
│   │   │   │   ├── PreRegistrationResource/ # Lead management
│   │   │   │   ├── PromoCodeResource/       # Promo code CRUD
│   │   │   │   ├── SupportTicketResource/   # CRM ticket management
│   │   │   │   ├── TemplateResource/        # Communication templates
│   │   │   │   └── UserResource/            # User management
│   │   │   └── Widgets/                   # Dashboard widgets (9 total)
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   │   └── Api/                   # API controllers
│   │   │   │       ├── User/              # Auth, profile, payments
│   │   │   │       ├── V2/               # V2 controllers (Account, Discovery, Payments)
│   │   │   │       ├── FoodsController    # Menu item CRUD
│   │   │   │       ├── MikitchnController # Kitchen management
│   │   │   │       ├── OrderController    # Order lifecycle
│   │   │   │       ├── ReviewController   # Reviews
│   │   │   │       ├── FavoriteController # Favorites
│   │   │   │       ├── FcmController      # Push notifications
│   │   │   │       ├── StripeWebhookController  # Payment webhooks
│   │   │   │       └── SupportTicketController  # Support ticket API
│   │   │   ├── Middleware/                # Custom middleware (Customer, Restaurant, ApiUserActive, etc.)
│   │   │   ├── Resources/                # API response transformers
│   │   │   │   ├── Order/                # Order, OrderData, CancelReason resources
│   │   │   │   ├── Restaurant/           # Restaurant, Food, Review resources
│   │   │   │   ├── Reviews/              # Reviews resource
│   │   │   │   └── User/                 # User, CookingStyle, SpecialDiet resources
│   │   │   └── Responses/
│   │   │       └── Auth/                 # Custom auth responses
│   │   ├── Jobs/                          # Queued jobs (SLA escalation, certificate notification)
│   │   ├── Listeners/                     # Event listeners (refund, vendor payment, FCM, CRM)
│   │   ├── Mail/                          # Mailable classes (10 total)
│   │   ├── Models/                        # Eloquent models (30+ models)
│   │   ├── Notifications/                 # Notification classes (6 total)
│   │   ├── Observers/                     # Model observers (6 total)
│   │   ├── Providers/
│   │   │   └── Filament/                  # Filament panel provider
│   │   ├── Services/                      # Business logic services (15+ services)
│   │   └── Traits/                        # Controller traits (HandlesUserAuthentication, HandlesUserPayments)
│   ├── bootstrap/                         # Laravel bootstrap
│   ├── config/                            # Configuration files (auth, cors, stripe, horizon, support, etc.)
│   ├── database/
│   │   ├── factories/                     # Model factories
│   │   ├── migrations/                    # Database migrations (40+ files)
│   │   └── seeders/                       # Database seeders (roles, permissions, admin users, reference data)
│   ├── nginx/                             # Container nginx config (port 8000)
│   ├── public/                            # Public assets (images, Filament assets)
│   ├── resources/
│   │   ├── css/                           # Stylesheets
│   │   ├── js/                            # JavaScript
│   │   ├── lang/en/                       # English translations
│   │   └── views/                         # Blade templates (Filament overrides, email templates)
│   ├── routes/
│   │   ├── api.php                        # ★ API route definitions (all mobile/public endpoints)
│   │   └── web.php                        # Web routes (password reset form)
│   ├── scripts/                           # Build scripts (coverage checker)
│   ├── storage/                           # Laravel storage (logs, cache, sessions, api-docs)
│   └── tests/
│       ├── Feature/                       # Feature tests (33 files)
│       │   └── Api/                       # API contract tests
│       └── Unit/                          # Unit tests (13 files)
│
├── mobile-app/                            # Flutter Mobile App (iOS + Android)
│   ├── android/
│   │   ├── app/src/main/
│   │   │   └── AndroidManifest.xml        # Permissions, deep links, network security
│   │   └── keystore/                      # Release signing keys
│   ├── assets/
│   │   ├── cfg/
│   │   │   └── configuration.json         # ★ API endpoint configuration
│   │   ├── fonts/                         # ITC Avant Garde Gothic Std
│   │   └── img/                           # App icons and illustrations (30 assets)
│   ├── integration_test/                  # Integration tests (app smoke test)
│   ├── ios/
│   │   └── Runner/                        # iOS config (Info.plist, deep links, permissions)
│   ├── lib/
│   │   ├── main.dart                      # ★ App entry point
│   │   ├── app.dart                       # App widget tree, theme, providers
│   │   ├── route_generator.dart           # Named route wiring (25 routes)
│   │   ├── splash.dart                    # Splash screen with update check
│   │   ├── auth_bloc/
│   │   │   └── authentication/            # Auth BLoC (states, events, bloc logic)
│   │   ├── helper/                        # Utilities (API contract, config, constants, logger, etc.)
│   │   ├── model/                         # Data models/DTOs (user, kitchen, booking, food, etc.)
│   │   ├── repos/                         # Repository layer (API communication)
│   │   ├── pages/                         # ★ Foodie-facing features
│   │   │   ├── common/view/              # Shared widgets (biometric lock, update gate, FAQs)
│   │   │   ├── edit_profile_foodie/      # Foodie profile editing
│   │   │   ├── forgot/                   # Password reset
│   │   │   ├── home/                     # ★ Discovery feed (recommended, top-rated, nearby)
│   │   │   ├── landing_page/             # Login/signup landing
│   │   │   ├── login/                    # Email/password login
│   │   │   ├── otp/                      # OTP verification
│   │   │   ├── profile_foodie/           # Foodie profile & settings
│   │   │   ├── profile_signup_cook/      # Cook onboarding flow
│   │   │   └── signup/                   # User registration
│   │   └── pages_cook/                    # ★ Cook-facing features
│   │       ├── add_menu_item/            # Food item add/edit
│   │       ├── bookings/                 # Booking management
│   │       ├── customer_reviews/         # Review display
│   │       ├── dashboard_cook/           # ★ Cook dashboard (bottom nav hub)
│   │       ├── edit_kitchen_profile/     # Kitchen profile editing
│   │       ├── edit_profile_cook/        # Cook personal profile editing
│   │       ├── home_page/               # Cook home (stats, quick actions)
│   │       ├── menu/                    # Menu listing
│   │       ├── menu_detail/             # Food item detail view
│   │       ├── profile_cook/            # Cook profile (personal + kitchen tabs)
│   │       ├── requests/                # Incoming order requests
│   │       ├── settings_page/           # Cook settings (role switch, logout, biometric)
│   │       ├── upcoming_bookings/       # Upcoming order view
│   │       └── user_details_page/       # Customer detail view
│   └── test/                              # Unit tests (14 files)
│       ├── helper/                        # Helper utility tests
│       ├── pages/                         # Page/cubit tests
│       └── repos/                         # Repository tests
│
├── website/                               # Static Marketing Website
│   ├── build-static-site.js               # Custom SSG build script
│   ├── Dockerfile                         # Nginx container for dev
│   ├── nginx.conf                         # Dev reverse proxy config
│   ├── package.json                       # Build scripts only (zero dependencies)
│   ├── public/
│   │   ├── frontend/
│   │   │   ├── css/                       # Bootstrap + custom styles
│   │   │   └── images/                    # Marketing images (19 assets)
│   │   ├── favicon.ico
│   │   └── robots.txt
│   └── src/
│       ├── templates.js                   # Shared header/footer/modal templates
│       └── pages/                         # HTML page partials (6 pages)
│
├── deploy/                                # Deployment Infrastructure
│   ├── Dockerfile.backend.unified         # ★ Production Dockerfile (2-stage: composer → PHP-FPM+nginx)
│   ├── docker-compose.prod.contabo.yml    # Production compose (Contabo VPS)
│   ├── docker-compose.test.windows.yml    # Windows test compose
│   ├── environments/
│   │   ├── dev/backend-api.env            # Development environment
│   │   ├── staging/backend-api.env        # Staging template
│   │   └── prod/backend-api.env           # Production environment
│   ├── load-tests/                        # k6 admin page load tests
│   ├── nginx/
│   │   └── mitabl.host.unified.conf       # ★ Host-level nginx (SSL termination, proxy)
│   └── scripts/                           # Ops scripts (diagnostics, backup validation, legacy check)
│
├── design-artifacts/                      # Product design scaffolding (empty)
│   ├── A-Product-Brief/
│   ├── B-Trigger-Map/
│   ├── C-UX-Scenarios/
│   ├── D-Design-System/
│   ├── E-PRD/
│   ├── F-Testing/
│   └── G-Product-Development/
│
├── docs/                                  # Operational documentation
│   ├── CRM_PLAYBOOK.md                    # CRM SOPs and training
│   ├── deployment.md                      # Deployment guide
│   ├── PLATFORM_ADMIN.md                  # Admin platform docs
│   ├── MOBILE_APP.md                      # Mobile app docs
│   ├── mitabl_WEBSITE.md                  # Website docs
│   ├── FIREBASE_SETUP.md                  # Firebase configuration
│   ├── APK_BUILDER.md                     # APK build instructions
│   ├── ENV_VARIABLES_SECRETS_ROTATION.md  # Secrets management
│   └── config_requirement.md              # Config requirements
│
├── .github/workflows/
│   └── ci-cd.yml                          # ★ CI pipeline (secret scan, backend, mobile, website)
│
├── docker-compose.yml                     # ★ Dev orchestration (backend, queue, scheduler, db, redis)
├── README.md                              # ★ Comprehensive project documentation
└── config_requirement.pdf                 # Configuration requirements (PDF)
```

---

## Critical Entry Points

| Part | Entry Point | Description |
|------|-------------|-------------|
| Backend API | `backend/routes/api.php` | All API route definitions |
| Backend Web | `backend/routes/web.php` | Password reset form routes |
| Backend Admin | `backend/app/Filament/` | Filament panel configuration |
| Backend Bootstrap | `backend/app/Providers/` | Service providers and boot logic |
| Mobile App | `mobile-app/lib/main.dart` | Flutter app initialization |
| Mobile Routing | `mobile-app/lib/route_generator.dart` | Named route definitions (25 routes) |
| Mobile API Config | `mobile-app/assets/cfg/configuration.json` | Backend URL configuration |
| Website Build | `website/build-static-site.js` | Static site generator |
| Website Templates | `website/src/templates.js` | Shared HTML templates |
| Deploy Prod | `deploy/Dockerfile.backend.unified` | Production container build |
| Deploy Compose | `docker-compose.yml` | Dev environment orchestration |
| CI/CD | `.github/workflows/ci-cd.yml` | GitHub Actions pipeline |

---

## Key Configuration Files

| File | Purpose |
|------|---------|
| `backend/config/auth.php` | Auth guards (web, admin, api/JWT) |
| `backend/config/cors.php` | CORS policy |
| `backend/config/stripe.php` | Stripe payment configuration |
| `backend/config/horizon.php` | Queue worker configuration |
| `backend/config/support.php` | Support ticket SLA and intake rules |
| `backend/config/permission.php` | Spatie permission tables (admin-prefixed) |
| `backend/config/admin_security.php` | Step-up re-auth window |
| `backend/.env.example` | Environment variable template |
| `deploy/environments/*/backend-api.env` | Per-environment configuration |
