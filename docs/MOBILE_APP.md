# Mitabl Mobile App — Enterprise Overview

## 1) Executive Summary

The Mitabl mobile application (`mobile-app/`) is a Flutter-based, role-aware client that supports two primary personas in one codebase:

- **Foodie (customer)** experiences for discovery and profile management.
- **Cook/Restaurant (vendor)** experiences for onboarding, kitchen/profile management, menu operations, bookings/requests, and operational settings.

The app is built with a **BLoC/Cubit + repository** architecture, stores session identity in `SharedPreferences`, and communicates with a Laravel-style backend API via JSON and multipart HTTP requests.

At a strategic level, the app is already structured around reusable modules and clear route boundaries; however, from an enterprise-readiness standpoint it still has modernization opportunities around security hardening, observability, testing depth, and release governance.

---

## 2) Product Scope & User Journeys

## 2.1 Primary user personas

1. **Foodie user**
   - Sign up/login/OTP verification.
   - Browse recommended, top-rated, and nearby kitchens.
   - Manage profile.

2. **Cook/Vendor user**
   - Sign up/login/OTP verification.
   - Complete kitchen profile onboarding.
   - Access dashboard, menu management, incoming requests, bookings, profile/settings.
   - Use support-ticket workflows from settings.

## 2.2 Route-level feature map

Named routes are centrally generated in `RouteGenerator` and include:

- Auth/onboarding: `/Splash`, `/LandingPage`, `/LoginPage`, `/SignUpPage`, `/ForgotPage`, `/OTPPage`, `/CookProfile`.
- Foodie: `/HomePage`, `/ProfileFoodie`, `/EditProfileFoodie`.
- Cook: `/DashboardCook`, `/SettingsCook`, `/ProfileCook`, `/EditKitchenProfile`, `/CustomerReviewPage`, `/AddMenuPage`, `/Bookings`, `/UpcomingBookings`, `/MenuDetails`, `/UserDetails`, `/OrderDetails`.

This gives the product a single navigation contract, making route governance straightforward for future module expansion.

---

## 3) Technical Architecture

## 3.1 Runtime composition

Entry and app composition:

- `main.dart` initializes Flutter bindings and loads runtime config (`assets/cfg/configuration.json`) via `global_configuration`.
- `App` wires repositories + BLoCs through `MultiRepositoryProvider` and `MultiBlocProvider`.
- `AuthenticationBloc` listens to `AuthenticationRepository.status` and drives top-level navigation through a global `navigatorKey`.

## 3.2 Architectural pattern

The app follows a layered structure:

- **Presentation layer**: widgets/pages (`lib/pages`, `lib/pages_cook`).
- **State layer**: Cubits/BLoC (`lib/**/cubit`, `lib/auth_bloc`).
- **Data access layer**: repositories (`lib/repos`).
- **Domain transport layer**: DTO-style models (`lib/model`).
- **Utility layer**: helpers/constants/config (`lib/helper`).

This is close to a pragmatic clean architecture, though domain boundaries are still lightweight (models and repository contracts are tightly bound to transport payloads).

## 3.3 State management strategy

State is managed with:

- `AuthenticationBloc` for application-wide auth status.
- Feature-specific cubits (e.g., `LoginCubit`, `SignUpCubit`, `HomeCubit`, `DashboardCookCubit`, `BookingsCubit`, `RequestsCubit`, `AddMenuCubit`, etc.).
- `Formz` for input validation and submission status transitions.

This enables predictable state transitions and straightforward UI binding, with clear opportunities to standardize failure handling and telemetry hooks.

---

## 4) Codebase Topology

High-level package layout:

- `lib/auth_bloc/` — global authentication state.
- `lib/helper/` — constants, responsive sizing, API URI builder, utility widgets.
- `lib/model/` — request/response models.
- `lib/pages/` — foodie + common/auth pages.
- `lib/pages_cook/` — cook-side operational pages.
- `lib/repos/` — API and persistence repositories.
- `assets/cfg/` — runtime environment config.
- `android/`, `ios/` — native wrappers and permissions.

This structure is understandable for multi-team ownership and supports incremental decomposition into internal packages if needed at scale.

---

## 5) Authentication, Session, and Identity Flow

## 5.1 Auth lifecycle

- `AuthenticationRepository.status` waits ~3 seconds and checks `current_user` from `SharedPreferences`.
- If found, app becomes `authenticated`; otherwise `unauthenticated`.
- Login/signup/OTP flows eventually persist the full user payload and push auth status events.

## 5.2 Token handling

- Access token is read from `UserModel.data.accessToken` and attached as bearer token for protected calls.
- Repository methods guard token retrieval and throw when absent in some paths.

## 5.3 Session storage

- User session is serialized as JSON into `SharedPreferences` key: `current_user`.
- Logout clears this key and emits unauthenticated status.

### Enterprise note
`SharedPreferences` is convenient but not a hardened secret store. For enterprise security, migrate tokens to platform-secure storage (`flutter_secure_storage` + OS keystore/keychain policies).

---

## 6) API Integration & Contract Surface

## 6.1 Base URL and URI normalization

- `ApiContract.uri()` normalizes base URL + endpoint path and filters empty query params.
- Base URLs are provided by `assets/cfg/configuration.json`:
  - `base_url`
  - `api_base_url`
  - `image_base_url`

## 6.2 API capability map

### Authentication & onboarding

- `POST /login`
- `POST /register`
- `POST /verifyOtp`
- `POST /password/reset`
- `POST /v1/logout`
- `POST /v1/mikitchn/store` (multipart cook onboarding)

### User/profile

- `GET /v1/getprofile`
- `GET /v1/getcustomerprofile`
- `POST /v1/editprofile` (multipart avatar/profile)
- `POST /v1/deleteimage`
- `POST /v1/mikitchn/editkitchen` (multipart kitchen update)

### Discovery (foodie)

- `POST /v1/recommendedrestaurant`
- `POST /v1/topRatedRestaurant?page=1&limit=20`
- `POST /v1/nearestRestaurant?page=1&limit=20`

### Cook menu/catalog

- `GET /v1/mymenu`
- `GET /v1/getspecialdiets`
- `GET /v1/getcookingstyles`
- `POST /v1/food/add` (multipart)
- `POST /v1/food/editfood` (multipart)
- `GET /v1/food/status/{foodId}`

### Requests/bookings

- `POST /v1/allorders` (paginated with filters)
- `POST /v1/kitchenupcomingorders` (paginated)
- `POST /v1/updateorderstatus`
- `GET /v1/kitchenorderrequest` (paginated)

### Support workflow

- `POST /support/ticket`
- `GET /support/ticket/{id}`
- `POST /support/ticket/{id}/reply`

Support APIs include channel headers:

- `X-Authenticated-Channel: mobile_app`
- `X-Client-Channel: mobile_app`
- Optional `X-Ticket-Token`

## 6.3 API robustness observations

Strengths:

- Centralized URI normalization exists.
- Modernized support-ticket repository returns parsed maps and supports optional auth.

Gaps to address:

- Inconsistent error handling and response typing across repositories.
- Frequent `dynamic` return types instead of sealed/result abstractions.
- Limited retry/backoff, request timeouts, and standardized exception mapping.

---

## 7) Feature Domains in Detail

## 7.1 Auth & onboarding domain

- `LoginCubit`, `SignUpCubit`, `OtpCubit`, `ForgotCubit` use `Formz` validations and repository calls.
- Role-based post-auth navigation:
  - Foodie → `/HomePage`
  - Cook → `/DashboardCook` after profile flow

## 7.2 Foodie domain

- `HomeCubit` orchestrates three restaurant feeds and filtering signals (dine-in/take-away, cooking style, distance).
- `ProfileFoodieCubit` supports profile retrieval and updates.

## 7.3 Cook operations domain

- `DashBoardCookPage` defines bottom-nav shell: dashboard, menu, requests, profile.
- `MenuCubit` + `AddMenuCubit` support CRUD-style menu operations, images, special diets, cooking style links, and status toggles.
- `BookingsCubit` and `RequestsCubit` manage order lifecycle interactions.
- `EditKitchenProfileCubit` and `EditProfileCookCubit` support vendor identity and kitchen edits.

## 7.4 Support & settings domain

- Settings includes a bottom-sheet support workflow for create/get/reply ticket actions.
- Notification toggle UI exists; backend integration is currently placeholder-level.
- Delete-account entry exists as a placeholder with no backend invocation.

---

## 8) Data Model Strategy

The app uses transport-facing model classes under `lib/model/` (e.g., `user_model`, `dashboard_data`, `food_menu`, `bookings`, `kitchen_profile`, `otp_response`, etc.).

### Enterprise implications

- Good: explicit DTOs reduce ad-hoc map access in UI.
- Improvement: introduce domain models where business logic is non-trivial, and separate API DTO from domain entities to reduce coupling and simplify future API evolution/versioning.

---

## 9) Platform, Permissions, and Native Wrappers

## 9.1 Android

Current Android manifest includes permissions/features:

- `INTERNET`
- `CAMERA`
- `READ_PHONE_STATE`
- `WRITE_EXTERNAL_STORAGE` / `READ_EXTERNAL_STORAGE`
- Camera feature marked `required=false`
- `android:usesCleartextTraffic="true"`
- `android:requestLegacyExternalStorage="true"`

Build config highlights:

- `minSdkVersion 17`
- Kotlin `1.6.10`
- Android Gradle Plugin `4.1.0`

## 9.2 iOS

- Camera and photo library usage descriptions are declared.
- Schemes queried: `sms`, `tel`.
- Landscape orientations enabled in `Info.plist` (while runtime Flutter app constrains orientation to portrait in `AppView`).

### Enterprise note
Platform configuration should be modernized (SDK/API levels, storage model, cleartext policy, and legacy permissions minimization) to meet current store/compliance baselines.

---

## 10) UI/UX Architecture and Design System Signals

- Theme is centrally configured in `AppView` (`ThemeData`) with custom color/font families (`itc_avant_garde_gothic_std`) and responsive helper sizing.
- Asset strategy is broad (`assets/img`, `assets/fonts`, `assets/cfg`).
- UX is currently mobile portrait-focused.

### Improvement opportunities

- Introduce a formal design token layer and component library abstraction to reduce style drift.
- Standardize spacing/typography tokens and semantics for accessibility (contrast, scalable text, labels).

---

## 11) Observability, Logging, and Telemetry

Current status:

- Logging mostly via `print` statements.
- No structured app-level telemetry pipeline (crash reporting, distributed tracing correlation, performance timings).

Enterprise recommendation:

- Add structured logging facade and environment-aware log levels.
- Integrate crash + performance analytics (e.g., Firebase Crashlytics/Performance or equivalent enterprise observability stack).
- Add API correlation IDs and user/session context propagation where policy allows.

---

## 12) Security & Compliance Posture

## 12.1 Strengths

- Most protected calls use bearer token authorization.
- Support channel headers indicate backend channel-awareness.

## 12.2 Risks / gaps

- Token persisted in plain shared preferences (not secure enclave/keychain-backed).
- `usesCleartextTraffic=true` in Android manifest may permit non-TLS traffic if endpoints/config drift.
- Legacy storage permissions and `requestLegacyExternalStorage` increase attack surface.
- Limited client-side guardrails around replay mitigation, certificate pinning, and sensitive data redaction in logs.

## 12.3 Recommended controls

1. Move secrets to secure storage.
2. Enforce HTTPS-only transport and optionally certificate pinning.
3. Reduce runtime permissions to least-privilege.
4. Replace `print` with redaction-aware logging.
5. Add dependency and SCA checks in CI for Flutter and native wrappers.

---

## 13) Quality Engineering & Test Coverage

Existing tests:

- `test/repos/support_ticket_repository_test.dart` verifies request paths/headers/payload behavior via mocked HTTP client.
- `test/widget_test.dart` remains scaffold boilerplate and does not reflect app’s actual widget tree.

Enterprise-grade target state:

- Repository contract tests for all critical API domains.
- Cubit/BLoC state transition tests (success/failure/edge cases).
- Golden tests for critical visual states.
- Smoke/integration tests for core journeys (login → role routing, menu add/edit, bookings actions, support ticket flow).

---

## 14) Build, Environment, and Delivery

## 14.1 Runtime environment config

- Configuration loaded from asset file at startup, enabling simple environment parameterization.

## 14.2 Containerized development support

- A lightweight Flutter `Dockerfile` is provided for deterministic local build environments.

## 14.3 Release hardening recommendations

- Introduce flavor-based environment separation (dev/stage/prod) with compile-time constants and secure secret injection.
- Add CI gates: formatting, static analysis, unit/widget/integration tests, dependency audit, and signed artifact verification.
- Add release checklist for store compliance, privacy disclosure, and backward compatibility.

---

## 15) Operational Readiness Assessment (Enterprise Lens)

## 15.1 Current maturity snapshot

- **Architecture**: Moderate maturity (clear module boundaries, BLoC usage, repository separation).
- **Security**: Basic-to-moderate (auth present; storage and transport controls need hardening).
- **Quality**: Early-to-moderate (limited automated coverage).
- **Observability**: Early (no structured telemetry).
- **Release governance**: Early (needs stronger CI/CD and environment stratification).

## 15.2 Priority action plan (recommended order)

1. **Security uplift**: secure token storage, cleartext prohibition, permission minimization.
2. **Stability uplift**: unified error model, timeout/retry/circuit patterns.
3. **Quality uplift**: BLoC + repository tests across critical domains.
4. **Operational uplift**: crash/perf telemetry and structured logging.
5. **Delivery uplift**: flavors + CI policy gates + release runbooks.

---

## 16) Appendix — Key Technical Assets

- App entry: `lib/main.dart`, `lib/app.dart`
- Route registry: `lib/route_generator.dart`
- Global auth: `lib/auth_bloc/authentication/`
- Core repos: `lib/repos/*.dart`
- Settings support integration: `lib/pages_cook/settings_page/view/settings_page_cook.dart`
- Runtime config: `assets/cfg/configuration.json`
- Android permissions/config: `android/app/src/main/AndroidManifest.xml`
- iOS permissions/config: `ios/Runner/Info.plist`
- Build container: `Dockerfile`
- Tests: `test/repos/support_ticket_repository_test.dart`

---

## 17) Conclusion

The Mitabl mobile app has a solid functional foundation and a recognizable modular architecture suitable for ongoing growth. To become fully enterprise-grade, the next evolution should focus on **security hardening**, **operational observability**, **test depth**, and **release governance**. Executing the priority plan above will materially improve resilience, compliance posture, and maintainability for scaled production operations.
