# Mitabl Mobile App - Technical Overview

## Document intent

This document is a **code-first, implementation-accurate** technical overview of the `mobile-app/` project for onboarding, architecture reviews, QA planning, operations, and modernization decisions.

It has been updated to match the **current repository state** and focuses on real runtime behavior from Flutter app wiring, repositories, cubits/blocs, route contracts, API usage, native wrappers, and tests.

---

## 1. System snapshot

- **Platform**: Flutter (single codebase; Android + iOS wrappers).
- **App package**: `mitabl_user`.
- **Primary personas**:
  - Foodie (consumer)
  - Cook/Restaurant (vendor)
- **State management mix**:
  - App-wide auth state: `AuthenticationBloc`
  - Feature/local state: `Cubit`-based modules
- **HTTP architecture**:
  - Shared `AuthAwareHttpClient` wraps `http.Client`
  - Automatic 401 handling + token refresh retry via `SessionRepository`
- **Runtime config**:
  - `GlobalConfiguration().loadFromAsset('configuration')`
  - Config file: `assets/cfg/configuration.json`
- **Session persistence**:
  - Primary store: `flutter_secure_storage` (`current_user_secure`)
  - Legacy migration path from `SharedPreferences` (`current_user`) remains for backward compatibility.

### FAQ content source policy

- The FAQ source used by mobile is website-owned: `https://mitabl.com/faq`.
- The app displays FAQ via a dedicated webview page (`FaqWebviewPage`) and enforces host/scheme restrictions.
- Mobile should not maintain duplicate hardcoded FAQ copy.

### Current scale indicators

- `129` Dart files under `lib/`.
- `9` repositories under `lib/repos/`.
- `5` repo-focused tests under `test/` (including auth headers/http/repo tests + default widget test).

---

## 2. Startup, app shell, and navigation model

## 2.1 Boot sequence

1. `lib/main.dart`
   - Initializes Flutter binding.
   - Loads runtime configuration.
   - Disables Google Fonts runtime fetching.
   - Installs `AppBlocObserver`.
   - Creates:
     - `SessionRepository`
     - shared `AuthAwareHttpClient`
     - `UserRepository` using shared client
     - `AuthenticationRepository` using shared client + user/session repositories
   - Attaches `UserRepository` into `SessionRepository` for token refresh operations.

2. `lib/app.dart`
   - Registers app-level repositories:
     - `AuthenticationRepository`
     - `UserRepository`
     - `SessionRepository`
     - `SupportTicketRepository`
   - Registers global feature blocs/cubits:
     - `AuthenticationBloc`
     - `DashboardCookCubit`
     - `ProfileCookCubit`
     - `ProfileFoodieCubit`
     - `AddMenuCubit`
   - Forces portrait orientation (up/down).
   - Builds `MaterialApp` + `RouteGenerator`.

3. Authentication-driven root routing
   - `AuthenticationBloc` listens to `AuthenticationRepository.status`.
   - Auth state transitions route users using `navigatorKey`:
     - authenticated cook: `/DashboardCook`
     - authenticated foodie: `/HomePage`
     - unauthenticated: `/LandingPage`
   - Splash fallback sends unknown state to landing after 3 seconds.

## 2.2 Route registry contract

`lib/route_generator.dart` remains the centralized route dispatcher.

### Route families

| Domain | Routes |
|---|---|
| Launch/auth | `/Splash`, `/LandingPage`, `/LoginPage`, `/SignUpPage`, `/ForgotPage`, `/OTPPage` |
| Shared onboarding/profile | `/CookProfile` |
| Foodie | `/HomePage`, `/EditProfileFoodie`, `/ProfileFoodie` |
| Cook shell + operations | `/DashboardCook`, `/SettingsCook`, `/ProfileCook`, `/EditKitchenProfile`, `/CustomerReviewPage`, `/AddMenuPage`, `/Bookings`, `/UpcomingBookings`, `/MenuDetails`, `/UserDetails`, `/OrderDetails` |

### Runtime route safety posture

- `RouteArguments` are validated in the route generator for routes that require payload.
- Missing/invalid arguments now fail with explicit route-error screens instead of unchecked force-casts.

---

## 3. Complete source inventory (code-facing files)

This section captures major source categories that are currently active.

## 3.1 Core entry and wiring

- `lib/main.dart`
- `lib/app.dart`
- `lib/route_generator.dart`
- `lib/splash.dart`

## 3.2 Authentication bloc

- `lib/auth_bloc/authentication/authentication_bloc.dart`
- `lib/auth_bloc/authentication/authentication_event.dart`
- `lib/auth_bloc/authentication/authentication_state.dart`

## 3.3 Helper/util layer

- Includes API contract, logging, app constants, routing arguments, UI helpers, and bloc observer.
- Notable files:
  - `lib/helper/api_contract.dart`
  - `lib/helper/app_logger.dart`
  - `lib/helper/app_bloc_observer.dart`
  - `lib/helper/route_arguement.dart`

## 3.4 Data repositories (current)

- `lib/repos/authentication_repository.dart`
- `lib/repos/session_repository.dart`
- `lib/repos/auth_aware_http_client.dart`
- `lib/repos/auth_headers.dart`
- `lib/repos/user_repository.dart`
- `lib/repos/home_repository.dart`
- `lib/repos/cook_repository.dart`
- `lib/repos/bookings_repository.dart`
- `lib/repos/support_ticket_repository.dart`
- `lib/repos/mobile_contact_repository.dart`

## 3.5 Models

- User/account/auth: `user_model.dart`, `signup_response.dart`, `otp_response.dart`, etc.
- Discovery/menu/order/profile: `recommended_rest_response.dart`, `top_rated_rest_response.dart`, `near_by_restaurants_response.dart`, `food_menu.dart`, `bookings.dart`, `requests.dart`, `kitchen_profile.dart`, and related request models.

## 3.6 Foodie/auth/profile features

- Auth journeys: login/signup/forgot/otp pages + cubits.
- Home discovery:
  - `pages/home/...` with filter dialog/widgets.
- Foodie profile + edit pages.
- Shared FAQ webview page:
  - `lib/pages/common/view/faq_webview_page.dart`.

## 3.7 Cook operations features

- Dashboard shell with tabbed cook experience.
- Menu listing/add/edit/status.
- Requests/bookings/upcoming flows and order detail views.
- Cook profile, personal details, kitchen profile editing, settings.

## 3.8 Test files

- `test/repos/auth_headers_test.dart`
- `test/repos/auth_aware_http_client_test.dart`
- `test/repos/bookings_repository_test.dart`
- `test/repos/support_ticket_repository_test.dart`
- `test/widget_test.dart`

## 3.9 Android layer

- Manifest + gradle stack + kotlin activity wrapper.
- Network security config is active and cleartext traffic is disabled.

## 3.10 iOS layer

- `Info.plist`, `AppDelegate.swift`, launch/main storyboards, Xcode project files.
- Portrait-only orientation in plist aligns with Flutter runtime orientation lock.

## 3.11 Build/runtime metadata

- `pubspec.yaml`
- `analysis_options.yaml`
- `Dockerfile`
- `assets/cfg/configuration.json`

---

## 4. Domain architecture and behavior

## 4.1 Authentication and account lifecycle

- `AuthenticationRepository` handles:
  - login (`login`)
  - signup (`register`)
  - otp verify (`verifyOtp`)
  - password reset (`password/reset`)
  - logout (`v2/logout`)
  - cook kitchen upload (`v2/mikitchn/store`)
- `AuthenticationBloc` emits `unknown/authenticated/unauthenticated` from repository stream.
- Unauthorized session events from `SessionRepository` trigger:
  - user data clear
  - user-facing session-expired toast
  - auth state transition to unauthenticated.

### End-to-end auth flow

1. App boots into `/Splash`.
2. Authentication status resolves from persisted user payload.
3. Unknown state fallback routes to `/LandingPage` after 3s.
4. Successful login/signup/otp stores normalized user payload.
5. Role-aware navigation sends cook to dashboard and foodie to home.

## 4.2 Foodie discovery and profile

- `HomeCubit` responsibilities include:
  - discovery feed orchestration (recommended/top-rated/nearby)
  - filter state management (dine-in, take-away, cooking style, distance)
  - request de-duplication using request tokens
  - debounced filter execution
  - cache hydration and 10-minute TTL cache persistence via `SharedPreferences`
  - best-effort retry for server/network failures
  - coordinate resolution using geolocator + optional geocoding label
- `HomeRepository` executes discovery API requests with auth headers.
- Foodie profile fetch/update flows run through `UserRepository` + foodie profile cubit.

## 4.3 Cook/vendor operations

- `DashBoardCookPage` is the cook shell.
- Menu operations:
  - menu fetch
  - special diet/cooking style metadata
  - add/edit food
  - toggle food active status
  - multipart image upload support
- Orders:
  - requests, bookings, upcoming bookings
  - status updates (`v2/updateorderstatus`)
- Profile/kitchen:
  - account profile read/update
  - kitchen edit + timing/image update support.

## 4.4 Settings and support workflow

- Settings now has live backend-wired actions:
  - edit profile navigation (foodie/cook context aware)
  - notification preference toggle with optimistic UI + rollback on failure
  - support ticket bottom sheet (create/get/reply)
  - delete-account confirmation + API call + logout on success
- Notification preference persists locally in settings key and syncs to backend endpoint.

---

## 5. API and backend contract map

## 5.1 Endpoint families

### Auth

- `POST /api/login`
- `POST /api/token/refresh`
- `POST /api/register`
- `POST /api/verifyOtp`
- `POST /api/password/reset`
- `POST /api/v2/logout`

### Account/Profile/Kitchen

- `GET /api/v2/account/profile`
- `PUT /api/v2/account/profile` (effective profile update also via multipart `POST /api/v2/editprofile` in current client)
- `GET /api/v2/account/dashboard`
- `POST /api/v2/account/notification-preferences`
- `DELETE /api/v2/account/delete` (with POST fallback if backend does not support DELETE)
- `POST /api/v2/deleteimage`
- `POST /api/v2/editprofile`
- `POST /api/v2/mikitchn/store`
- `POST /api/v2/mikitchn/editkitchen`

### Discovery

- `GET /api/v2/discovery/recommended`
- `GET /api/v2/discovery/top-rated`
- `GET /api/v2/discovery/nearest`

### Menu

- `GET /api/v2/mymenu`
- `GET /api/v2/getspecialdiets`
- `GET /api/v2/getcookingstyles`
- `POST /api/v2/food/add`
- `POST /api/v2/food/editfood`
- `POST /api/v2/food/status/{id}`

### Orders

- `GET /api/v2/allorders`
- `GET /api/v2/kitchenupcomingorders`
- `GET /api/v2/kitchenorderrequest`
- `POST /api/v2/updateorderstatus`

### Support

- `POST /api/support/ticket`
- `GET /api/support/ticket/{id}`
- `POST /api/support/ticket/{id}/reply`

### Mobile contact

- `GET /api/v2/mob-contact`

## 5.2 API client posture

Current strengths:

- Shared URI normalization via `ApiContract.uri`.
- Shared auth header helpers (`auth_headers.dart`).
- Request timeout baseline (`15s`) centralized in `ApiContract`.
- Auto-refresh + retry path for authorized requests through `AuthAwareHttpClient` + `SessionRepository`.
- Repository constructors generally accept injected `http.Client` for testability.

Current tradeoffs / remaining technical debt:

- Several response boundaries still use loosely typed maps in UI workflows.
- Some feature modules still parse raw dynamic payloads in cubits/pages.
- No global circuit-breaker or advanced retry policy beyond selective local retries.

---

## 6. Data model and state-management details

## 6.1 State model

- Auth lifecycle: event/state bloc (`AuthenticationBloc`).
- Feature modules: cubits with immutable `copyWith` state patterns.
- Home feed state tracks:
  - independent status flags per feed
  - filter values
  - pagination state
  - location/label fields
  - cached payload hydration signals.

## 6.2 Persistence boundaries

- **Secure session payload**:
  - `flutter_secure_storage` key `current_user_secure`.
- **Legacy compatibility**:
  - one-time migration from `SharedPreferences.current_user` if present.
- **Feature cache/settings**:
  - home feed cache keys with per-user prefixes + timestamps.
  - cook settings notification toggle key in shared preferences.

---

## 7. Security posture and risks

## 7.1 Positive security controls now present

- `usesCleartextTraffic="false"` in Android manifest.
- App uses Android `networkSecurityConfig`.
- Session payload migrated to secure storage for primary persistence.
- FAQ webview restricts navigation to HTTPS + approved hosts and disables JavaScript.
- Unauthorized handling is centralized through session event pipeline.

## 7.2 Remaining risks / hardening opportunities

- Token refresh relies on access token semantics; dedicated refresh-token lifecycle is backend-dependent and not modeled separately in client storage.
- Some user-facing/server errors still surfaced via generic exception strings.
- No built-in jailbreak/root detection or anti-tampering checks in current code.
- Structured log redaction strategy is partial (improved but not fully formalized).

## 7.3 Enterprise controls to prioritize

1. Formalize token/credential lifecycle and backend refresh guarantees.
2. Define log schema with PII redaction standards.
3. Add client hardening checks (device integrity, secure screenshots policy where needed).
4. Add security CI checks for mobile manifests/plists/dependencies.

---

## 8. Platform engineering audit

## 8.1 Android

- Application ID: `com.mitabl.user.mitabl_user`.
- Build uses modern Android Gradle + Kotlin plugin configuration and Java 17 targets.
- Active permissions include:
  - internet
  - camera
  - coarse/fine location
- Legacy external storage permissions are no longer present in current manifest.

## 8.2 iOS

- Usage descriptions present for camera, photo library, and in-use location.
- URL query schemes include `sms` and `tel`.
- Supported orientation is portrait (iPhone/iPad), aligned with Flutter runtime lock.

## 8.3 Environment config

- Runtime config loaded from `assets/cfg/configuration.json`.
- Current default config:
  - `base_url`: `https://mitabl.com/`
  - `api_base_url`: `https://mitabl.com/api/`
  - `image_base_url`: `https://mitabl.com/`
- No multi-flavor environment wiring is currently implemented in code.

---

## 9. UX and product implementation notes

- App has a custom theming baseline + bundled assets and fonts.
- Landing page links Terms/Privacy to website routes using external browser launching.
- FAQ entry opens in in-app webview with constrained navigation policy.
- Cook and foodie profile surfaces include contact-us flows, support ticket actions, and profile editing.
- Discovery screens support filter-driven feed updates with location support.

---

## 10. Testing and quality posture

Current automated tests include:

- `auth_headers` contract tests.
- `AuthAwareHttpClient` behavior tests.
- `BookingsRepository` tests.
- `SupportTicketRepository` tests.
- default Flutter widget smoke test scaffold.

### Quality roadmap

- Expand cubit/bloc unit tests (auth transitions, home filters/pagination, settings actions).
- Add integration tests for role routing and critical user journeys.
- Add golden/widget tests for core pages and edge states.
- Add API contract tests for all repositories with representative backend payload fixtures.

---

## 11. Observability and operability

Current:

- `AppLogger` is available as a central logging abstraction.
- `AppBlocObserver` is active, improving bloc/cubit transition visibility.
- No integrated crash analytics/performance product is wired in repo.

Needed:

- Production-grade structured logging.
- Crash + performance instrumentation.
- Request correlation IDs and API call tracing.
- Runtime feature flags for safer rollout and incident mitigation.

---


## 11.1 Release automation vs manual requirements (Play Store / App Store)

### What is already automated in code/repo

- Push notification runtime wiring is code-complete (Firebase initialization, token sync, foreground/background handlers, and route handling).
- Android/iOS manifests/plists/entitlements include notification-related capabilities and permissions.
- The app now degrades gracefully when Firebase is not configured (app still starts, notifications are disabled).

### What still requires manual setup (cannot be fully automated in-repo)

1. **Firebase project binding per app**
   - Run `flutterfire configure` for the target Firebase project.
   - This generates platform files (`google-services.json`, `GoogleService-Info.plist`) and a real `lib/firebase_options.dart`.
2. **Apple Developer portal / APNs configuration**
   - Push Notifications capability must be enabled for the App ID.
   - APNs key/certificate must be uploaded in Firebase Cloud Messaging settings.
3. **Store account actions**
   - App Store Connect and Google Play Console metadata, policy declarations, screenshots, and signing enrollment steps remain console-driven.
4. **Release signing assets**
   - Android upload keystore and iOS signing certificates/profiles must be provisioned and securely injected in CI secrets.

### Recommended automation boundary

- Fully automate **build/test/archive** in CI once secrets are available.
- Keep console/legal/compliance acknowledgements as a final human gate.
- Keep Firebase/native config validation as a CI preflight (fail build if required files/values are missing for release lanes).

## 12. Delivery and governance readiness

Current:

- Flutter lint baseline via `analysis_options.yaml`.
- Dockerfile exists for build/development workflows.
- Improved repository testability through injected HTTP clients.

Recommended governance enhancements:

1. Add CI gates for format/analyze/test + dependency audit.
2. Add release checklists (security, API compatibility, rollback strategy).
3. Introduce explicit environment flavors (dev/stage/prod).
4. Maintain architecture decision records for major client changes.

---

## 13. Priority modernization plan

## Phase 1 (Hardening + consistency)

- Complete typed API response/result wrappers in remaining dynamic paths.
- Standardize user-facing error mapping across repositories and cubits.
- Expand secure storage governance to all sensitive local data.

## Phase 2 (Reliability + QA depth)

- Increase coverage for cubits/repositories/routes.
- Add integration tests for auth, discovery filters, cook menu/order workflows.
- Introduce more robust retry/backoff strategies where business-critical.

## Phase 3 (Scale + operations)

- Strengthen observability stack.
- Formalize release channels/flavors.
- Improve modular boundaries as feature scope grows.

---

## 14. Conclusion

The Mitabl mobile app is a feature-rich dual-persona Flutter application with materially improved security and session handling compared to earlier baselines. It now includes secure session storage migration, centralized auth-aware HTTP behavior, stronger route argument guards, and expanded repository-level tests. The next major value comes from deeper test coverage, stricter typed contracts, and production observability.

---

## Contact endpoint migration (2026)

- **Current mobile contact endpoint in code**: `/api/v2/mob-contact`.
- No client calls to legacy `/api/mobcontact` or `/api/v1/mob-contact` remain in the current mobile repository.
- Backend-side deprecation behavior for old routes should remain documented in backend/API docs and communicated to older client versions.

---

## 15. Cook role transition and onboarding progression contract (v2)

Mobile clients should treat cook activation as a **progressive onboarding flow** rather than a blocking Stripe dependency.

### Endpoints

- `POST /api/v2/account/switch-role` with `role_id=2`
- `POST /api/v2/account/roles/cook/activate` (alias: `POST /api/v2/account/onboarding/cook/start`)
- `POST /api/v2/account/onboarding/cook/vendor-account` (dedicated vendor-account provisioning step)

### Expected behavior

- Switching to cook (`role_id=2`) **must not hard-fail** if Stripe vendor provisioning is unavailable.
- API returns `200` with:
  - `onboarding_required=true`
  - `role_transition.state="onboarding_required"`
  - `role_transition.missing` including `vendor_account` when no vendor Stripe account exists
  - `role_transition.next_required_step` preserved (typically `vendor_account` first)
- Mobile should continue onboarding step-by-step based on `role_transition` instead of expecting a hard error for temporary Stripe failures.
- Vendor Stripe provisioning is handled by the dedicated `vendor-account` onboarding step (or server-side retry mechanisms), not as a prerequisite for the role switch response.
