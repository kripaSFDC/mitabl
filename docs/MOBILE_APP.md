# Mitabl Mobile App - Technical Overview

## Document intent

This document is a **deep, engineering-grade overview** of the `mobile-app/` codebase for architecture review, onboarding, security assessment, platform operations, QA planning, and modernization roadmapping.

It reflects a code-first audit across app entry points, routing, feature modules, state management, repositories, models, native wrappers, configuration, and tests.

---

## 1. System snapshot

- **Platform**: Flutter (single codebase with Android + iOS wrappers).
- **App package name**: `mitabl_user`.
- **User personas**:
  - Foodie (consumer)
  - Cook/Restaurant (vendor)
- **Runtime style**: Route-driven app with `BLoC/Cubit` state and repository-based data access.
- **Session persistence**: `SharedPreferences` with serialized `current_user` payload.
- **Environment config**: Runtime JSON config (`assets/cfg/configuration.json`) loaded on startup.

### Scale indicators

- `118` Dart source files.
- `~24,060` lines of Dart.
- `6` repositories.
- `21` model files.
- `18` Bloc/Cubit state-management files.

---

## 2. Startup, app shell, and navigation model

## 2.1 Boot sequence

1. `main.dart`
   
   - Calls `WidgetsFlutterBinding.ensureInitialized()`.
   - Loads `GlobalConfiguration().loadFromAsset('configuration')`.
   - Starts `App(authenticationRepository, userRepository)`.

2. `app.dart`
   
   - Registers repositories globally (`AuthenticationRepository`, `UserRepository`, `SupportTicketRepository`).
   - Registers cross-cutting blocs/cubits (`AuthenticationBloc`, `LoginCubit`, `DashboardCookCubit`, `ProfileCookCubit`, `ProfileFoodieCubit`, `AddMenuCubit`).
   - Configures a global `MaterialApp` with `RouteGenerator` and app theme.
   - Locks orientation to portrait (`SystemChrome.setPreferredOrientations`).

3. `AuthenticationBloc` + `navigatorKey`
   
   - Auth status stream controls root navigation:
     - authenticated + role=Restaurant → `/DashboardCook`
     - authenticated + non-cook → `/HomePage`
     - unauthenticated → `/LandingPage`

## 2.2 Route registry contract

`lib/route_generator.dart` is the single route dispatcher.

### Registered route map

| Domain               | Routes                                                                                                                                                                                             |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Launch/auth          | `/Splash`, `/LandingPage`, `/LoginPage`, `/SignUpPage`, `/ForgotPage`, `/OTPPage`                                                                                                                  |
| Shared profile setup | `/CookProfile`                                                                                                                                                                                     |
| Foodie               | `/HomePage`, `/EditProfileFoodie`, `/ProfileFoodie`                                                                                                                                                |
| Cook shell & ops     | `/DashboardCook`, `/SettingsCook`, `/ProfileCook`, `/EditKitchenProfile`, `/CustomerReviewPage`, `/AddMenuPage`, `/Bookings`, `/UpcomingBookings`, `/MenuDetails`, `/UserDetails`, `/OrderDetails` |

### Observations

- Centralized named route control is good for governance.
- Several routes require `RouteArguments` cast at runtime; bad payload types can crash at navigation boundaries.

---

## 3. Complete source inventory (code-facing files)

This section captures **every major code/config file class** under `mobile-app/` (excluding binary image/font/icon payloads).

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

- `lib/helper/api_contract.dart`
- `lib/helper/app_config.dart`
- `lib/helper/appconstants.dart`
- `lib/helper/common_appbar.dart`
- `lib/helper/common_progress.dart`
- `lib/helper/helper.dart`
- `lib/helper/no_data_widget.dart`
- `lib/helper/route_arguement.dart`
- `lib/helper/shape_custom.dart`

## 3.4 Data repositories

- `lib/repos/authentication_repository.dart`
- `lib/repos/bookings_repository.dart`
- `lib/repos/cook_repository.dart`
- `lib/repos/home_repository.dart`
- `lib/repos/support_ticket_repository.dart`
- `lib/repos/user_repository.dart`

## 3.5 Transport/domain model files

- `lib/model/bookings.dart`
- `lib/model/confirmpassword.dart`
- `lib/model/cooking_style.dart`
- `lib/model/dashboard_data.dart`
- `lib/model/email.dart`
- `lib/model/food_menu.dart`
- `lib/model/get_profile_model.dart`
- `lib/model/kitchen_profile.dart`
- `lib/model/name.dart`
- `lib/model/near_by_restaurants_response.dart`
- `lib/model/otp.dart`
- `lib/model/otp_response.dart`
- `lib/model/password.dart`
- `lib/model/phone.dart`
- `lib/model/recommended_rest_response.dart`
- `lib/model/requests.dart`
- `lib/model/signup_response.dart`
- `lib/model/special_diet.dart`
- `lib/model/timing_model.dart`
- `lib/model/top_rated_rest_response.dart`
- `lib/model/user_model.dart`

## 3.6 Foodie/auth/profile features

- `lib/pages/landing_page/landing_page.dart`
- `lib/pages/login/view/login_page.dart`, `lib/pages/login/view/login_form.dart`
- `lib/pages/login/cubit/login_cubit.dart`, `lib/pages/login/cubit/login_state.dart`
- `lib/pages/signup/view/signup_page.dart`
- `lib/pages/signup/cubit/sign_up_cubit.dart`, `lib/pages/signup/cubit/sign_up_state.dart`
- `lib/pages/forgot/view/forgot_page.dart`
- `lib/pages/forgot/cubit/forgot_cubit.dart`, `lib/pages/forgot/cubit/forgot_state.dart`
- `lib/pages/otp/view/otp_page.dart`
- `lib/pages/otp/cubit/otp_cubit.dart`, `lib/pages/otp/cubit/otp_state.dart`
- `lib/pages/home/view/home_page.dart`
- `lib/pages/home/cubit/home_cubit.dart`, `lib/pages/home/cubit/home_state.dart`
- `lib/pages/home/element/filter_dialog.dart`
- `lib/pages/home/element/near_by_restaurant.dart`
- `lib/pages/home/element/near_by_widget.dart`
- `lib/pages/home/element/recomm_rest_widget.dart`
- `lib/pages/home/element/top_rated.dart`
- `lib/pages/profile_foodie/view/profile_foodie_page.dart`
- `lib/pages/profile_foodie/cubit/profile_foodie_cubit.dart`, `lib/pages/profile_foodie/cubit/profile_foodie_state.dart`
- `lib/pages/edit_profile_foodie/view/edit_profile_foodie_page.dart`
- `lib/pages/profile_signup_cook/cook_profile/cook_profile_page.dart`
- `lib/pages/profile_signup_cook/cook_profile/cubit/cook_profile_cubit.dart`
- `lib/pages/profile_signup_cook/cook_profile/cubit/cook_profile_state.dart`
- `lib/pages/profile_signup_cook/cook_profile/element/timing_dialog.dart`

## 3.7 Cook operations features

- Dashboard/home/menu/requests shell:
  
  - `lib/pages_cook/dashboard_cook/view/dashboard_cook_page.dart`
  - `lib/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart`
  - `lib/pages_cook/dashboard_cook/cubit/dashboard_cook_state.dart`
  - `lib/pages_cook/home_page/view/home_cook_page.dart`
  - `lib/pages_cook/home_page/element/home_cook_header.dart`
  - `lib/pages_cook/menu/view/menu_page.dart`
  - `lib/pages_cook/menu/cubit/menu_cubit.dart`
  - `lib/pages_cook/menu/cubit/menu_state.dart`
  - `lib/pages_cook/menu_detail/view/menu_detail.dart`

- Add/edit menu and food metadata:
  
  - `lib/pages_cook/add_menu_item/view/add_menu_page.dart`
  - `lib/pages_cook/add_menu_item/cubit/add_menu_cubit.dart`
  - `lib/pages_cook/add_menu_item/cubit/add_menu_state.dart`
  - `lib/pages_cook/add_menu_item/elements/cooking_style_dialog.dart`
  - `lib/pages_cook/add_menu_item/elements/special_diet/special_diet_dialog.dart`
  - `lib/pages_cook/add_menu_item/elements/special_diet/cubit/special_diet_cubit.dart`
  - `lib/pages_cook/add_menu_item/elements/special_diet/cubit/special_diet_state.dart`

- Requests/bookings/order actions:
  
  - `lib/pages_cook/requests/view/requests_page.dart`
  - `lib/pages_cook/requests/cubit/requests_cubit.dart`
  - `lib/pages_cook/requests/cubit/requests_state.dart`
  - `lib/pages_cook/requests/elements/accept_reject_dialog.dart`
  - `lib/pages_cook/requests/elements/order_details_view.dart`
  - `lib/pages_cook/bookings/view/bookings_page.dart`
  - `lib/pages_cook/bookings/cubit/bookings_cubit.dart`
  - `lib/pages_cook/bookings/cubit/bookings_state.dart`
  - `lib/pages_cook/bookings/elements/booking_filter_dialog.dart`
  - `lib/pages_cook/bookings/elements/order_details_booking.dart`
  - `lib/pages_cook/upcoming_bookings/view/upcoming_bookings.dart`

- Cook profile and kitchen profile:
  
  - `lib/pages_cook/profile_cook/view/profile_cook_page.dart`
  - `lib/pages_cook/profile_cook/view/personal_view.dart`
  - `lib/pages_cook/profile_cook/view/mikitchn_view.dart`
  - `lib/pages_cook/profile_cook/cubit/profile_cook_cubit.dart`
  - `lib/pages_cook/profile_cook/cubit/profile_cook_state.dart`
  - `lib/pages_cook/profile_cook/elements/timing_view.dart`
  - `lib/pages_cook/edit_profile_cook/view/edit_profile_cook_page.dart`
  - `lib/pages_cook/edit_profile_cook/cubit/edit_profile_cook_cubit.dart`
  - `lib/pages_cook/edit_profile_cook/cubit/edit_profile_cook_state.dart`
  - `lib/pages_cook/edit_kitchen_profile/view/edit_kitchen_profile.dart`
  - `lib/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_cubit.dart`
  - `lib/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_state.dart`
  - `lib/pages_cook/edit_kitchen_profile/elements/timing_edit.dart`

- Other cook pages:
  
  - `lib/pages_cook/settings_page/view/settings_page_cook.dart`
  - `lib/pages_cook/settings_page/cubit/settings_cook_cubit.dart`
  - `lib/pages_cook/settings_page/cubit/settings_cook_state.dart`
  - `lib/pages_cook/customer_reviews/view/customer_review_page.dart`
  - `lib/pages_cook/user_details_page/user_details.dart`

## 3.8 Test files

- `test/repos/support_ticket_repository_test.dart`
- `test/widget_test.dart`

## 3.9 Android layer

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/mitabl/user/mitabl_user/MainActivity.kt`
- `android/app/build.gradle`
- `android/build.gradle`
- `android/settings.gradle`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.properties`

## 3.10 iOS layer

- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Base.lproj/Main.storyboard`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `ios/Flutter/AppFrameworkInfo.plist`

## 3.11 Build/runtime metadata

- `pubspec.yaml`
- `analysis_options.yaml`
- `Dockerfile`
- `assets/cfg/configuration.json`

---

## 4. Domain architecture and behavior

## 4.1 Authentication and account lifecycle

- `AuthenticationRepository` provides login, signup, OTP verify, forgot password, logout API, and kitchen onboarding upload.
- `AuthenticationBloc` subscribes to repository auth stream and emits `unknown/authenticated/unauthenticated`.
- Session user payload is persisted/loaded by `UserRepository` from `SharedPreferences`.

### End-to-end auth flow

1. Launch in `/Splash`.
2. `AuthenticationRepository.status` checks session after delay.
3. If no user, route to `/LandingPage`.
4. Login/signup flows issue API calls and persist response.
5. Auth event propagates through `AuthenticationBloc` to route user based on role.

## 4.2 Foodie discovery and profile

- `HomeCubit` orchestrates:
  - recommended restaurants
  - top-rated restaurants
  - nearby restaurants
  - filter toggles (dine-in / take-away, cooking style, distance)
- Home network operations are in `HomeRepository`.
- Foodie profile fetch/update paths are in `ProfileFoodieCubit` + `UserRepository`.

## 4.3 Cook/vendor operations

- `DashBoardCookPage` hosts 4-tab shell: home/menu/requests/profile.
- Menu management:
  - listing (`mymenu`), special diets, cooking styles, add/edit food, food active/inactive toggle.
  - image uploads via multipart requests.
- Order operations:
  - requests list, bookings list/upcoming list, status updates.
- Profile/kitchen updates:
  - profile edit and avatar update.
  - kitchen details and timings update.

## 4.4 Settings and support workflow

- Settings includes:
  - profile navigation
  - notification toggle UI placeholder
  - support bottom sheet with create/get/reply ticket actions
  - delete-account placeholder row
- Support workflow uses dedicated `SupportTicketRepository` and channel headers.

---

## 5. API and backend contract map

## 5.1 Endpoint families

### Auth

- `POST login`
- `POST register`
- `POST verifyOtp`
- `POST password/reset`
- `POST v1/logout`

### Kitchen and profile

- `POST v1/mikitchn/store`
- `POST v1/mikitchn/editkitchen`
- `GET v1/getprofile`
- `GET v1/getcustomerprofile`
- `POST v1/editprofile`
- `POST v1/deleteimage`

### Discovery

- `POST v1/recommendedrestaurant`
- `POST v1/topRatedRestaurant`
- `POST v1/nearestRestaurant`

### Menu

- `GET v1/mymenu`
- `GET v1/getspecialdiets`
- `GET v1/getcookingstyles`
- `POST v1/food/add`
- `POST v1/food/editfood`
- `GET v1/food/status/{id}`

### Orders

- `POST v1/allorders`
- `POST v1/kitchenupcomingorders`
- `GET v1/kitchenorderrequest`
- `POST v1/updateorderstatus`

### Support

- `POST /support/ticket`
- `GET /support/ticket/{id}`
- `POST /support/ticket/{id}/reply`

## 5.2 API client posture

Strengths:

- Central URI helper (`ApiContract.uri`) handles path/query normalization.
- Modern support ticket repository has better header + parsing discipline.

Weak points:

- Widespread `dynamic` response contracts.
- Inconsistent use of `http.Client` lifecycle handling.
- Limited unified exception taxonomy.
- Verbose `print` logging in production paths.

---

## 6. Data/state design

## 6.1 State-management inventory

- 1 global bloc (`AuthenticationBloc`).
- 17 feature cubits for auth/forms/home/cook/menu/requests/bookings/profile.
- Validation largely uses `Formz` for form states.

## 6.2 Data modeling

- 21 explicit model files cover auth payloads, restaurants, menu, bookings, requests, profiles, and validation wrappers.
- Model layer is largely API-DTO oriented (tight coupling with current backend responses).

### Enterprise recommendation

Add a domain abstraction layer for high-change business domains (orders/menu/support), leaving DTO transformations at repository boundaries.

---

## 7. Security, privacy, and compliance review

## 7.1 Security positives

- Bearer token used for authenticated endpoints.
- Support channel headers (`X-Authenticated-Channel`, `X-Client-Channel`) provide backend channel context.

## 7.2 Material risks

- Access token persisted in `SharedPreferences` instead of secure keystore/keychain storage.
- Android manifest enables `usesCleartextTraffic=true`.
- Legacy storage permissions still requested (`WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, legacy external storage mode).
- Production code logs request/response details via `print`, risking sensitive data exposure.
- Permission UX appears partial (dialog helper exists, but not all permission lifecycles are centrally managed).

## 7.3 Enterprise controls to prioritize

1. Migrate auth token/session secret material to secure storage.
2. Enforce HTTPS-only transport and remove cleartext if not required.
3. Minimize Android permissions to current scoped-storage standards.
4. Introduce redaction-safe structured logging.
5. Add mobile security checks to CI (SCA, manifest linting, secret scanning).

---

## 8. Platform engineering audit

## 8.1 Android

- `applicationId`: `com.mitabl.user.mitabl_user`
- `minSdkVersion`: 17
- Permissions include internet, camera, phone state, external storage read/write.
- `requestLegacyExternalStorage=true` present.
- Build stack includes older Android Gradle plugin/Kotlin combinations.

## 8.2 iOS

- `Info.plist` includes camera/photo usage descriptions and URL query schemes (`sms`, `tel`).
- iOS supports landscape orientations in plist, while Flutter runtime forces portrait; alignment should be clarified.
- Standard Flutter `AppDelegate` plugin registration pattern is in place.

## 8.3 Environment config

- Base URLs are runtime-loaded from `assets/cfg/configuration.json`.
- Current file points to hosted production-like endpoints.
- No explicit environment flavor strategy documented in-app (dev/stage/prod variants should be formalized).

---

## 9. UX and product implementation notes

- Theme is globally defined with custom font family + color helpers.
- Extensive icon/asset library under `assets/img`.
- Core UX implemented for both personas with rich cook operations.
- Some UI controls are placeholders (e.g., notification toggle behavior, delete account action wiring).

---

## 10. Testing and quality posture

Current automated test reality:

- `test/repos/support_ticket_repository_test.dart` provides meaningful repository contract tests (headers/path/body behavior).
- `test/widget_test.dart` is still scaffold boilerplate and not representative of the real app shell.

### Enterprise quality roadmap

- Add bloc/cubit unit tests for each critical state machine.
- Add repository tests for all endpoint families (auth/menu/orders/profile).
- Add widget/golden tests for primary screens and important states.
- Add integration tests for top journeys:
  - login and role routing
  - signup + OTP
  - cook add/edit menu with image handling
  - booking/request status transitions
  - support ticket create/read/reply

---

## 11. Observability and operability

Current:

- No central telemetry abstraction.
- No crash/performance pipeline described in code.
- Diagnostic output mostly raw `print` calls.

Required for enterprise operation:

- Structured logs with environment-aware levels.
- Crash analytics + performance instrumentation.
- Correlation IDs for API requests.
- Runtime health toggles/feature flags for safe rollout and incident response.

---

## 12. Delivery and governance readiness

- Containerized build helper exists (`Dockerfile`).
- Project lint policy uses Flutter lints (`analysis_options.yaml`).

To move to enterprise delivery:

1. Introduce build flavors and environment segregation.
2. Require CI gates: format, analyze, tests, dependency audit.
3. Enforce release checklist: security review, API compatibility, store policy validation, rollback plan.
4. Maintain architecture decision records for major module changes.

---

## 13. Priority modernization plan

## Phase 1 (Immediate hardening)

- Secure storage migration.
- Remove cleartext transport and legacy storage where possible.
- Standardize HTTP timeout/error handling.
- Replace sensitive `print` logging.

## Phase 2 (Reliability + quality)

- Expand test suite (bloc, repository, widget, integration).
- Introduce typed result wrappers and API error taxonomy.
- Add retry/backoff and offline-aware UX for key flows.

## Phase 3 (Scale + governance)

- Split into clearer feature modules/packages where appropriate.
- Add observability stack and release analytics.
- Add formal SDLC controls around mobile security and compliance.

---

## 14. Conclusion

The Mitabl mobile app is a substantial dual-persona Flutter application with clear functional breadth and a workable architecture foundation. It is production-capable but not yet enterprise-optimized. The highest-value improvements are concentrated in security hardening, reliability controls, test depth, and operational governance.

This document is intended to be the baseline reference for executing that transition.
