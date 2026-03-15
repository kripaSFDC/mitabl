# 



# Mobile App Code Quality + Bugs - (FIXED Usman):

### **Missing Features - Implemented**

* **No push notifications** — no `firebase_messaging` or APNs integration. No booking/order alerts.
* **No biometric authentication** — `flutter_secure_storage` is in place but no fingerprint/FaceID unlock layer.
* **No deep linking / universal links** — `url_launcher` is available but no incoming link handling is wired.
* **No app update check** — no version-gate to prompt users to upgrade when the API changes.
* **No offline error handling** — when the device loses connectivity, all API calls throw and show a generic "something went wrong" toast with no retry button.
* **No accessibility / semantics** — no `Semantics` wrappers on interactive elements. Screen readers will struggle.
* **Essentially no tests** — test/widget_test.dart contains only a commented-out smoke test that tests a non-existent counter. Zero meaningful unit, widget, or integration tests exist.



### 1. Security Issues

| #   | Issue                                                                                                                                                                                                                          | Severity | Location                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------------------------------- |
| S1  | **`android:allowBackup` not disabled** — absent from AndroidManifest.xml, so it defaults to `true`. An attacker with ADB or a malicious backup agent can extract `SharedPreferences` data.                                     | High     | android/app/src/main/AndroidManifest.xml |
| S2  | **No certificate pinning / network security config** — no `android:networkSecurityConfig` set. The app has no defence against MITM attacks on compromised devices.                                                             | High     | AndroidManifest.xml                      |
| S3  | **`minSdkVersion 17`** — Android 4.2 (2012). No modern security primitives. `flutter_secure_storage` degrades to insecure storage on very old OS versions. Modern apps should use `minSdkVersion 23` (Android 6, Marshmallow). | Medium   | build.gradle:53                          |
| S4  | **No token refresh mechanism** — if the JWT expires mid-session, all API calls silently fail with a thrown exception. There is no interceptor, no refresh-token flow, and no re-login prompt.                                  | Medium   | All repositories                         |

**Files with bare `print()` leaks:** forgot_cubit.dart, login_form.dart, requests_page.dart, timing_edit.dart, profile_cook_cubit.dart, add_menu_page.dart, and others.

* * *

### 2. Performance Issues

| #   | Issue                                                                                                                                                                                                                                                                                                                               | Location |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| P1  | **`timeDilation = 0.4` in `build()` method** — this globally slows every animation in the app by 2.5× and is called on every rebuild. Active in signup_page.dart:60 and forgot_page.dart:55. Debug testing artefact shipped to production.                                                                                          |          |
| P2  | **Sequential home feed fetches** — `_fetchHomeFeeds()` in home_cubit.dart runs `await onRecommendedRestaurants(); await onNearByRestaurants(); await onTopRatedRestaurants()` sequentially. These are independent API calls and should be parallelised with `Future.wait()`.                                                        |          |
| P3  | **`google_fonts: 2.3.2` pinned to an old version** — old versions download fonts at runtime by default (`allowRuntimeFetching = true`). This causes first-load network requests for fonts as well as potential failures offline. Should upgrade to 6.x and bundle fonts, or call `GoogleFonts.config.allowRuntimeFetching = false`. |          |
| P4  | **No pagination on home feeds** — `topRatedRestaurants` hardcodes `{'page': 1, 'limit': 20}` and `nearByRestaurants` does the same. As data grows, this will load all 20 items at once with no lazy loading.                                                                                                                        |          |
| P5  | **`HomeCubit` creates its own `HomeRepository` and `CookRepository`** — these are not shared/disposed via the DI tree, so HTTP connections are duplicated.                                                                                                                                                                          |          |

* * *

### 3. Functionality Issues

| #   | Issue                                                                                                                                                                                                                                                                                | Location                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- |
| F1  | **`DashboardCookCubit.getDashBoardData()` missing `dart:convert` import** — `jsonDecode` is called but the import is missing. This will cause a compile error.                                                                                                                       | dashboard_cook_cubit.dart:33 |
| F2  | **`getDashBoardData()` silent failure** — the `else` branch is empty; API failures are swallowed with no state update or user feedback.                                                                                                                                              | dashboard_cook_cubit.dart:37 |
| F3  | **`SplashPage` has no navigation logic** — `initState` is empty. The splash screen displays the logo but never navigates anywhere. Navigation is presumably driven by the `AuthenticationBloc` upstream, but there's no timeout/fallback if that doesn't emit.                       | splash.dart                  |
| F4  | **`LoginCubit` double-provisioned** — `LoginCubit` is created in the global `MultiBlocProvider` in app.dart AND again in `LoginPage.route()`. The route-scoped one shadows the global one, which is never disposed.                                                                  |                              |
| F5  | **`AddMenuCubit.cookRepository` is nullable** — declared as `CookRepository?` and force-unwrapped with `!` throughout. Any code path that creates `AddMenuCubit` without a repository will crash at runtime with a null dereference.                                                 | add_menu_cubit.dart          |
| F6  | **`AuthenticationBloc` has redundant null assertions** — `assert(authenticationRepository != null)` on `required` non-nullable parameters. In sound null safety these are never `null`, so the asserts are dead code but add confusion.                                              | authentication_bloc.dart:18  |
| F7  | **ABN / Certificate fields wired but ignored** — `abnNoTextEditor` and `certificateTextEditor` are initialized and disposed but their listeners do nothing (commented out). The fields appear in the UI but their data is never submitted.                                           | edit_kitchen_profile.dart:68 |
| F8  | **No error state for `AddMenuCubit.getFoodMenu()`** — the `on Exception` catch block doesn't rethrow or show any user message; the spinner just stays forever on failure.                                                                                                            | add_menu_cubit.dart:79       |
| F9  | **`BookingRepository.updateOrderStatus` sends body as `Map<String, dynamic>` not JSON** — it passes `body: data` (a `Map`) directly to an `http.post`, which uses URL-encoded form encoding, but the `Accept` header is `application/json`. This will mismatch with a JSON-only API. | bookings_repository.dart:60  |

* * *

### 4. Code Quality / Architecture Issues

| #   | Issue                                                                                                                                                                                                                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Q1  | **Pervasive use of old Dart style** — all model classes use `new Map<String, dynamic>()`, `new Data.fromJson()`, and `new List()`. Dart 2+ does not require `new`; this is all over the model/ directory.                                                                                   |
| Q2  | **Deprecated `TextTheme` API everywhere** — `headline5`, `headline6`, `bodyText1`, `bodyText2` were replaced in Flutter 3.x with `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`. All deprecated names are used in app.dart:164, menu_page.dart:41, requests_page.dart:44, and more. |
| Q3  | **Dead commented-out code blocks** — large swaths of commented-out `mapEventToState`, `BlocProvider` wrappers, `timeDilation` calls, and business logic exist throughout the codebase adding significant noise.                                                                             |
| Q4  | **`_accessToken()` logic duplicated in every repository** — the identical pattern exists in `UserRepository`, `CookRepository`, `BookingRepository`, `HomeRepository`, `AuthenticationRepository`. A shared base class or an HTTP client interceptor would eliminate this.                  |
| Q5  | **No global `BlocObserver`** — there is no error monitoring or analytics hook. In production you'd want to log transitions to Sentry/Firebase Crashlytics or similar.                                                                                                                       |
| Q6  | **`AppLogger` suppresses all errors in release mode** — `AppLogger.error()` wraps all output in `if (kDebugMode)`, meaning production crashes produce no logs at all. An error-reporting SDK (e.g., Firebase Crashlytics, Sentry) should capture non-debug errors.                          |
| Q7  | **`linter` rules are all commented out** — analysis_options.yaml has no active custom rules beyond the base `flutter_lints` set. The `avoid_print` rule in particular should be enabled to catch the 20+ bare `print()` calls.                                                              |



------



# Backend Code Quality Issues - (FIXED Usman)

1. **High - Authorization gaps on order actions let authenticated users act on other users’ orders.**  
   [OrderController.php:97](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:341](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:393](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:144](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:146](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:195](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

2. **High - Booking availability logic is incorrect: seat checks are not scoped to the target kitchen.**  
   checkBookedTimeByDate queries all dine-in orders without mikitchn_id filtering.  
   [OrderController.php:311](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

3. **High - SQL injection risk via raw distance SQL built from request coordinates.**  
   Lat/lon are interpolated into raw SQL strings without strict numeric validation/binding.  
   [Mikitchn.php:113](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:168](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:356](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

4. **High - Password reset flow has implementation errors likely to break or misroute requests.**  
   Array passed where scalar email is expected; catch block won’t catch global exceptions as intended in this namespace pattern.  
   [ResetPasswordController.php:66](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:76](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:99](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:103](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

5. **High - Payment flow is not idempotent and is non-transactional, enabling duplicate/inconsistent payment records.**  
   Repeated payment attempts create new rows; order and payment updates are separate operations; no unique guard on payments.order_id.  
   [OrderController.php:457](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:461](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:477](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Order.php:81](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [2026_03_02_000100_harden_orders_and_payments_schema.php:165](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

6. **High - Order creation path lacks required validation and transaction boundaries, risking 500s and partial writes.**  
   Controller forwards raw payload; service assumes required keys and parses times directly.  
   [OrderController.php:494](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:19](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:46](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

7. **Medium - OTP/auth hardening is weak (4-digit OTP, no expiry enforcement, limited brute-force resistance).**  
   No OTP freshness check in verification path; resend can be triggered by user id input.  
   [AuthService.php:12](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:435](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:359](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:60](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:61](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

8. **Medium - Several state-changing operations are exposed as GET, which is unsafe for caches/crawlers and semantics.**  
   [api.php:153](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:180](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:207](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:265](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:262](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

9. **Medium - Discovery queries are expensive and redundant under load.**  
   Correlated subquery + join/grouping + extra withAvg + subquery-based count on each call.  
   [DiscoveryService.php:172](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:177](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:237](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

10. **Medium - API and web concerns are mixed in API controllers (views/redirect/session in API class).**  
    These methods are not API-shaped and contain unresolved imports for web types.  
    [ReviewController.php:113](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:126](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:145](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

11. **Medium - Duplicate legacy logic and thin V2 wrappers preserve old flaws and increase maintenance cost.**  
    [AccountController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentsController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:217](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:281](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

12. **Medium - Data deletion logic is manual and non-atomic, with mixed ORM/raw operations.**  
    Risk of partial cleanup and harder invariants.  
    [User.php:191](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Mikitchn.php:152](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

13. **Low - Time-difference helper uses wrong format tokens (H:s:i), which can skew cancellation/refund timing logic.**  
    [Controller.php:160](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Controller.php:168](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

14. **Low - Test suite around API behavior is largely string-contract assertions, not behavioral/integration coverage.**  
    This leaves many runtime/security regressions untested.  
    [ModuleEightNineTenContractTest.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [AdminIdentityBoundaryRegressionTest.php:23](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [StripeIntegrationContractTest.php:29](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

15. **Critical: OTP verification can create orphan Stripe accounts on every retry**
    
    * In OTP verification, Stripe account creation is executed **before** checking whether a Stripe account already exists for the user, so repeated verify calls can create external orphan accounts.
    * References: [UserController.php:510](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:513](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:521](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:524](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

16. **Critical: Order pricing is client-trusted (tamperable financial amounts)**
    
    * Server persists item_total_price, taxes, total_price, and per-item price from request payload without server-side recalculation from canonical food prices.
    * References: [OrderService.php:38](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:41](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:58](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:75](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

17. **Critical: Refund side effects are non-idempotent and dispatched before cancellation persistence**
    
    * Refund event is emitted before order/cancel-reason persistence; if save fails, financial side effects may still happen.
    * Refund listener issues Stripe refund/transfer calls without idempotency keys, so queue retries can duplicate payouts/refunds.
    * References: [OrderController.php:401](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:414](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:416](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [CancelOrderRefundListener.php:45](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [CancelOrderRefundListener.php:52](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentService.php:223](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

18. **High: Review integrity checks are missing**
    
    * Customer can submit review for any restaurant_id/order_id combination (no ownership/status linkage check).
    * Kitchen can submit foodie reviews for arbitrary user_id with no order relationship validation.
    * References: [ReviewController.php:19](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:33](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:75](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:88](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

19. **High: Password reset token is stored and compared in plaintext**
    
    * Reset token is inserted/updated as raw value and later matched raw, increasing takeover risk if DB contents leak.
    * References: [ResetPasswordController.php:82](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:91](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:97](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ForgotPasswordController.php:44](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

20. **High: Discovery queries are fragile under strict SQL and expensive**
    
    * Queries select mikitchns.* while grouping only by mikitchns.id; with strict SQL (ONLY_FULL_GROUP_BY) this can fail.
    * Recommended endpoint fetches all results without pagination cap.
    * References: [DiscoveryService.php:30](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:31](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:160](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [config/database.php:59](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

21. **Medium: Excessive relation loading in order list/detail paths**
    
    * Order APIs load deep relation graph including full review relations for kitchen and user on listing endpoints, which is costly at scale.
    * References: [OrderController.php:552](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:557](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:558](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

22. **Medium: Duplicate business logic between v1 and v2 APIs**
    
    * Payments/account logic is duplicated across UserController and V2 controllers, increasing regression drift risk.
    * References: [UserController.php:791](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentsController.php:31](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:930](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentsController.php:75](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:703](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [AccountController.php:20](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

23. **Medium: Authentication hardening gap on login route**
    
    * login has no explicit validation and no route-level throttle, unlike OTP endpoints.
    * References: [api.php:58](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:60](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:102](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

24. **Medium: File deletion path handling is likely incorrect**
    
    * Uploaded file path is stored via storage disk, but deletion uses File::exists($image->path) directly, which may not map to physical disk path and can leak files.
    * References: [Controller.php:61](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Controller.php:114](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:423](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

25. **Medium: Dashboard endpoint can be slow/costly due to full Stripe transfer fetch**
    
    * Vendor earnings sums all transfers every call; no pagination windowing/caching per request path.
    * References: [MikitchnController.php:542](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:547](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentService.php:236](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

26. **Low-Medium: verify_otps schema lacks uniqueness for user_id**
    
    * Logic assumes one OTP row/user, but table schema doesn’t enforce it; this can cause ambiguous reads (first()).
    * References: [2022_05_18_104229_create_verify_otps_table.php:18](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [AuthService.php:15](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:451](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

27. **Low-Medium: Some “regression” tests are implementation-string assertions, not behavior tests**
    
    * Multiple tests only assert file content strings, so runtime regressions can pass undetected.
    * References: [ModuleEightNineTenContractTest.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ModuleEightNineTenContractTest.php:23](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [AdminDesignComplianceRegressionTest.php:22](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

28. **Low: Minor performance/cleanliness anti-patterns repeated**
    
    * Frequent ->get()->first() and similar patterns in hot paths add unnecessary overhead and code noise.
    * References: [FoodsController.php:168](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:315](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [SupportTicketService.php:45](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

29. **Critical: mobile/backend contract mismatch on food status endpoint (live failure).**  
    Mobile calls GET /api/v2/food/status/{id} in [cook_repository.dart (line 174)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [cook_repository.dart (line 183)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), but backend only supports POST [api.php (line 131)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and explicitly returns 405 for GET [api.php (line 215)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#).

30. **Critical: auth tokens are printed to logs in mobile repository code.**  
    Access tokens are printed directly in [cook_repository.dart (line 18)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [cook_repository.dart (line 45)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [cook_repository.dart (line 72)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [cook_repository.dart (line 180)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#).

31. **High: OTP is stored in plaintext and email sending is synchronous in request path.**  
    OTP is persisted directly via updateOrCreate [AuthService.php (line 15)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and sent inline with Mail::send [AuthService.php (line 29)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), which is both security- and latency-sensitive.

32. **High: broad exception masking in payments flow hides root causes and conflates error/data types.**  
    PaymentService::safely returns exception message strings [PaymentService.php (line 341)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 346)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), forcing controllers to do fragile type checks and making observability/debugging harder.

33. **High: mobile repositories swallow exceptions and return nullable/dynamic, while callers assume response objects.**  
    Patterns in [cook_repository.dart (line 12)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [cook_repository.dart (line 34)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [bookings_repository.dart (line 18)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [bookings_repository.dart (line 54)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) can return null; cubits then dereference response.statusCode directly (for example [bookings_cubit.dart (line 28)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [requests_cubit.dart (line 27)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)).

34. **High: repeated http.Client() creation without closing (resource leak pattern).**  
    Per-call clients are created in [cook_repository.dart (line 19)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [bookings_repository.dart (line 39)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [bookings_repository.dart (line 67)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [bookings_repository.dart (line 98)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and never closed.

35. **High: kitchen creation/update path is non-transactional with multi-step DB + file operations.**  
    store() performs multiple dependent writes (kitchen, timings, images, deletions) without transaction boundaries [MikitchnController.php (line 139)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), creating partial-write risk on failure.

36. **Medium: unsafe JSON handling in kitchen store can throw on malformed input.**  
    json_decode($request->timings)->days is accessed directly in [MikitchnController.php (line 167)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) with no structural validation.

37. **Medium: incorrect/fragile specialDiet serialization format in food store.**  
    $specialdiets = '['.json_encode(implode(',', $request->specialDiet)).']'; in [FoodsController.php (line 111)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) stores an odd encoded string instead of a clean array/JSON structure.

38. **Medium: significant duplication across API versions and controllers increases maintenance/regression risk.**  
    Duplicated v1/v2 route blocks in [api.php (line 88)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and [api.php (line 155)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#); duplicated discovery methods in [MikitchnController.php (line 54)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) vs [V2/DiscoveryController.php (line 20)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#); duplicated profile update methods in [user_repository.dart (line 151)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and [user_repository.dart (line 178)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#).

39. **Medium: discovery endpoints do expensive repeated work per request (count subquery + favorites lookup).**  
    Each call does an extra count via subquery [DiscoveryService.php (line 234)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [DiscoveryService.php (line 238)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#) and fetches favorite IDs each time [DiscoveryService.php (line 241)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [DiscoveryService.php (line 251)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), which can become costly as data grows.

40. **Low: route generation does unchecked argument casting and debug printing.**  
    Potential runtime cast crashes and noisy logs in [route_generator.dart (line 30)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [route_generator.dart (line 48)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [route_generator.dart (line 94)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#).

41. **Critical: Stripe connected-account update can target arbitrary account IDs**
    
    * updateConnectedAccount accepts account_id from request and passes it directly to Stripe without verifying ownership against the authenticated vendor account. A vendor user can attempt to mutate another connected account.
    * Ref: [UserController.php (line 929)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 935)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 941)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

42. **Critical: Vendor transfer endpoint trusts client-supplied financial values**
    
    * vendorTransfer takes amount and percent directly from request and executes transfer with no server-side reconciliation to captured payment amount, no one-time transfer guard, and no idempotency enforcement at controller level. This enables over/duplicate payouts.
    * Ref: [PaymentsController.php (line 149)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentsController.php (line 151)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentsController.php (line 153)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentsController.php (line 174)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 307)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 318)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

43. **High: Account deletion is immediate hard-delete from mobile API without re-auth challenge**
    
    * delete() force-deletes the authenticated user directly; no password/step-up check, no soft-delete retention path in endpoint behavior.
    * Ref: [UserController.php (line 782)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 785)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

44. **High: DB transaction holds row locks while performing external Stripe calls**
    
    * OTP verification runs in DB::transaction with lockForUpdate, then calls ensureStripeAccountForRole, which calls Stripe APIs. This can extend lock duration and amplify contention/timeouts under load.
    * Ref: [UserController.php (line 458)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 459)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 490)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 515)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 1006)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 1014)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

45. **High: Potential null dereference after bank-account add**
    
    * After saving StripeBankAccount, code assumes Auth::user()->restaurant exists and dereferences it unguarded. Vendor user without restaurant record will cause server error.
    * Ref: [UserController.php (line 767)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 768)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

46. **Medium: Completed orders can be inserted repeatedly**
    
    * Setting status to completed always inserts a new CompletedOrder row; no dedupe/unique protection in controller flow.
    * Ref: [OrderController.php (line 155)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [OrderController.php (line 156)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [OrderController.php (line 159)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

47. **Medium: Discount threshold likely off-by-one**
    
    * Discount applies when completed orders <= 5; that grants discount on the 6th order creation path, which is usually unintended if policy is “first 5 orders”.
    * Ref: [OrderService.php (line 92)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [OrderService.php (line 93)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

48. **Medium: Unsafe indexing into Stripe external accounts**
    
    * external_accounts->data[0] is used without existence checks. Vendors without bank accounts can trigger runtime errors.
    * Ref: [PaymentService.php (line 275)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 281)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 286)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [PaymentService.php (line 290)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

49. **Medium: Mobile token stored in plaintext local storage**
    
    * Full current_user JSON (including access token) is persisted in SharedPreferences without secure storage.
    * Ref: [user_repository.dart (line 35)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [user_repository.dart (line 51)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

50. **Medium: Forced 3-second auth startup delay**
    
    * Authentication stream intentionally delays startup by 3 seconds, adding avoidable app-launch latency.
    * Ref: [authentication_repository.dart (line 39)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [authentication_repository.dart (line 40)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

51. **Low/Medium: Duplicated legacy API surface and controller proxying increase maintenance risk**
    
    * Legacy route bundle is mounted in both v1 and v2, and UserController proxies many methods to V2 controllers. This duplicates behavior paths and increases drift/regression risk.
    * Ref: [api.php (line 81)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [api.php (line 114)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [api.php (line 159)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 688)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 797)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [UserController.php (line 817)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

52. **Low: Excess debug logging in mobile app includes request/response payloads**
    
    * Active print statements log internal state and raw response bodies in production code, increasing PII leakage/noise risk.
    * Ref: [edit_kitchen_profile_cubit.dart (line 159)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [edit_kitchen_profile_cubit.dart (line 169)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#), [login_form.dart (line 179)](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/#)

53. Architecture / Design Problems
    ---------------------
    
    **1. God Controller — `UserController` (1,103 lines)**  
    UserController.php handles: authentication, OTP, registration, profile update, password change, role switching, Stripe customer/vendor provisioning, bank account management, onboarding, notifications, and card management. Every new payment or auth concern ends up here.
    **2. Controller-injecting-Controller anti-pattern**  
    `UserController` constructor injects `V2AccountController` and `V2PaymentsController` and then delegates to them:
    Six methods in `UserController` are pure pass-throughs to V2 controllers. Controller-to-controller coupling should be resolved by pushing shared logic down into services, not by injecting controllers into other controllers.
    **3. `mikitchn/store` and `mikitchn/editkitchen` share one method**  
    Both routes api.php:88-89 point to `MikitchnController@store`, which branches internally. Similarly `food/add` and `food/editfood` both hit `FoodsController@store`. These should be separate Create/Update methods. The internal branching (`if ($existFood && !empty($request->food_id))`) makes validation and intent ambiguous.
    **4. Dead proxy methods in `MikitchnController`**  
    `recommendedRestaurant`, `nearestRestaurant`, `topRatedRestaurant`, `filterRestaurant` in MikitchnController.php:55-73 each instantiate `V2DiscoveryController` via `app()` just to forward the call. These are route-level orphans — the routes aren't registered for them in api.php, they exist as dead code.
    **5. Legacy route closure registered inside V2 group**  
    The `$registerLegacyMobileRoutes` closure at api.php:83-104 is registered inside the `v2` prefix group, meaning all the old unversioned-style routes (`editprofile`, `mymenu`, `food/add`, etc.) live at `/api/v2/editprofile`. This is confusing naming — these are semantically v1 routes that happen to require v2 auth middleware, not v2 endpoints.
    **6. Duplicate `is_kitchen` check**  
    The identical `Mikitchn::where('user_id', $user->id)->first()` + `$is_kitchen = 0/1` block appears in both the **verified** and **unverified** branch of `login()`, and again verbatim in `becomeCook()`. Three copies of the same code with no extraction. 
    
    ### 🔴 Performance Bottlenecks
    
    **7. N+1 on `getIsAvailableAttribute` in `Mikitchn`**  
    Mikitchn.php:35-41:
    This fires a `COUNT` query per kitchen in a list. Any list endpoint that accesses `is_available` on a collection triggers N+1.
    **8. N+1 on `getIsFavouritedAttribute` in `Mikitchn`**  
    Mikitchn.php:90-92:
    One query per kitchen per user per list — pure N+1. `DiscoveryService::annotateFavorites()` exists specifically to batch this, but the attribute still exists and will fire if called outside that path.
    **9. `getRatingCountAttribute` loads all reviews into memory**  
    Mikitchn.php:76-79 calls `$this->reviews->avg('rating')`, which hydrates all `Review` models for the kitchen, then computes the average in PHP. The discovery queries already use `withAvg('reviews', 'rating')` for this, but if this accessor triggers elsewhere it's a silent memory hog.
    **10. Double query in `DiscoveryService` for pagination**  
    All four discovery methods (`recommended`, `nearest`, `topRated`, `filtered`) in DiscoveryService.php call `$this->countRows($query)` followed by `$query->offset()->limit()->get()`. This runs the expensive Haversine/distance calculation SQL **twice** per request. Laravel's built-in `paginate()` handles both in a single context and avoids this.
    **11. `getBookedDates` does date logic in PHP**  
    OrderController.php:310-360 fetches all upcoming confirmed orders and then iterates in PHP to determine which dates are fully booked (comparing `bookedmins` against `avail_minutes`). This should be a single SQL query filtering at the database level.
    **12. `getCookingStyles` and `getSpecialDiets` return ALL records**  
    No pagination, no caching — will silently degrade as records grow.
    **13. `completedOrderCountForUser` in `OrderService` is a scalar query inside a transaction**  
    OrderService.php:16-18 runs a separate `COUNT` query to determine discount eligibility, inside the order creation transaction, without any locking. A user placing concurrent orders could get the discount applied multiple times.
    
    ### 🔴 Security Issues
    
    **14. Password validation missing on `register`**  
    UserController.php:329-335: `'password' => 'required'` only. The `login()` method enforces `min:8` but registration does not. A user can register with a 1-character password. implement a simple and easy password validation i.e. 6 char long only with all caps, all small etc.
    **15. OTP verification dual-path is fragile**  
    UserController.php:470:
    If the OTP is stored as a bcrypt hash, `Hash::check` does the right thing and `hash_equals` on BCrypt text would always fail (safe). If it's stored as plaintext, `Hash::check` always returns false and it falls to `hash_equals` (safe but inconsistent). The dual path means you can't tell which mode is active without inspecting the database — a future change to OTP storage can silently break one branch.
    **16. `delete()` returns the deleted user object**  
    UserController.php:815-820 returns `$user` (soft-deleted model) in the response body. This leaks PII (name, email, phone, address, role_id, device_token) via the delete confirmation response.
    **17. `updateDeviceToken` returns the full user model**  
    `AccountController::updateDeviceToken()` returns `$this->responser($user, 'Device Token Updated.')` — the full model, not just a confirmation. Any internal fields on `$user` not in `$hidden` are exposed.
    **18. Bank account validation has no format checks**  
    `addBankAccToVendor` validates `bsb` and `number` as `required` but applies no numeric or format validation. Any string is passed directly to Stripe.
    **19. `completedOnBoarding` has no role guard**  
    Any authenticated user (customer) can call `/v2/mikitchn/editkitchen`-adjacent paths and trigger `completedOnBoarding`. It only fails gracefully because `Auth::user()->restaurant` returns null for non-cooks, but the endpoint has no explicit middleware role check.
    #21 — public $data = [] mutable instance propertyStill declared in FoodsController.php:17, OrderController.php:31, ReviewController.php:15, and MikitchnController.php:32. Not a runtime risk in Laravel's per-request lifecycle, but remains a code smell.
    #27 — Inconsistent HTTP response formatThe majority goes through $this->responser(), but login still builds its own array and uses return $this->responser([...], ''); — the success message is an empty string. Minor, but the response contract for login differs from every other endpoint (no status key in successful payload).
    #42 — Mobile still calls legacy v2 aliasesuser_repository.dart still calls v2/getprofile, v2/getcustomerprofile, v2/getdashboarddata — the legacy unversioned aliases living under /v2, not the proper v2/account/profile endpoint. The canonical V2 AccountController routes exist but the mobile client hasn't been migrated to them.
    
    
    
    
    
    

    ### 🟡 Code Quality Issues
    
    
    
    
    
    ## MOBILE APP
    
    ### 🔴 Architecture / Design Problems
    
    **31. Hardcoded fallback GPS coordinates pointing to Chandigarh, India**  
    home_cubit.dart:38-39:
    
    On first load, and whenever the user hasn't entered coordinates, all discovery requests are centred on a hardcoded Indian city. Irrelevant for any non-Indian user and reveals the origin geography of the app.
    
    **33. `BookingRepository._accessToken()` is synchronous with no storage fallback**  
    bookings_repository.dart:17-21:
    
    This is non-async and only works if `user` is already in memory. Cold-start app states (returned from background) where memory was cleared will throw.
    **34. `HomeRepository` creates its own HTTP client by default**  
    home_cubit.dart:31:
    
    `HomeRepository()` creates `http.Client()` unless explicitly provided. The shared client from main.dart reaches `AuthenticationRepository` and `UserRepository`, but `HomeRepository` and `CookRepository` default to their own clients, fragmenting connection pooling.
    **35. Token read from secure storage on every API call**  
    `HomeCubit.onRecommendedRestaurants`, `onTopratedRestaurants`, `onNearByRestaurants` each call `await userRepository.getUser()` before every network request. This reads from `FlutterSecureStorage` on every invocation, adding latency and unnecessary I/O.
    **36. Three identical discovery API call patterns — no abstraction**  
    `onRecommendedRestaurants`, `onTopratedRestaurants`, `onNearByRestaurants` in home_cubit.dart follow the same pattern verbatim: emit loading, call API, decode JSON, emit success or failure with a toast. Extracting a generic `_fetchDiscoveryFeed` method would remove ~60 lines of duplication.
    **37. Request-token cancellation applied inconsistently**  
    `onTopratedRestaurants` checks `if (requestToken != _requestToken) return;` to handle stale responses. `onRecommendedRestaurants` and `onNearByRestaurants` do NOT have this guard, creating a race condition where stale responses from these can overwrite fresh state.
    **38. `userRepository.getUser()` called in `_fetchHomeFeeds` with result discarded**  
    home_cubit.dart:48: `await userRepository.getUser();` result is not used. The feeds are fetched unconditionally. This is a wasted async storage read on every home page load.
    **39. Global mutable `navigatorKey` variables in repositories**  
    Both authentication_repository.dart:18 and user_repository.dart:11 declare module-level global `GlobalKey<NavigatorState>` variables. Repository classes should not own navigation state. These are likely remnants of an old navigation pattern that was partially migrated.
    **40. `UserRepository.user` is a public mutable field**  
    Other repositories access `userRepository?.user` directly (bookings_repository.dart:18, cook_repository.dart:22). This bypasses the repository abstraction — callers depend on in-memory state being freshly populated, with no guarantee.
    
    
    
    ### 🔴 API Contract Issues
    
    **41. Discovery endpoints use POST for read-only operations**  
    `POST /v2/discovery/recommended`, `POST /v2/discovery/nearest`, `POST /v2/discovery/top-rated`, `POST /v2/discovery/filtered` are all pure read operations with no side effects. Using POST prevents HTTP-level caching (CDN, browser, proxy) and violates REST semantics. These should be GET with query params.
    **42. Mobile client still calls legacy unversioned route aliases**  
    user_repository.dart:
    
    * `v2/getprofile` — legacy alias pointing to `UserController::myProfile`
    * `v2/getcustomerprofile` — same
    * `v2/getdashboarddata` — legacy alias
    
    These are the `$registerLegacyMobileRoutes` paths registered inside the v2 group. The V2 equivalents (`v2/account/profile`) exist but are not yet used by the app.
    **43. `saveMenuItem` in `CookRepository` uses `food/add` vs `food/editfood` branches**  
    cook_repository.dart:76-78:
    
    Two separate non-RESTful POST endpoints for what should be `POST /foods` and `PUT /foods/{id}`.
    
    
    
    ### 🟡 UX / State Management Issues
    
    **45. Empty carousel auto-plays**  
    home_page.dart:86-101: `CarouselSlider` is always rendered with `autoPlay: true`. When the restaurant list is empty (on failure or empty data), the carousel still ticks at 3-second intervals — polling UI that renders nothing.
    **46. All API errors show "Something went wrong..."**  
    3xx, 4xx, and 5xx responses all produce the same toast: `Helper.showToast('Something went wrong...')`. No distinction between auth failures (401), rate limiting (429), server errors (500), or connectivity issues. Users cannot take informed action.
    **47. No offline mode, no retry, no local cache**  
    No `dio` interceptor retry, no `hive`/`drift` local store, no cached state between sessions. Every cold start fires three separate network requests to the backend before showing anything. If any fails (poor signal), the section shows empty with a generic error.
    **48. `HomeState` cannot reset individual status fields**  
    `HomeState.copyWith` uses `?? this.field` null-coalescing, meaning you can never explicitly clear a field back to `null` using `copyWith`. To reset `nearByRestaurants` to null you'd need to reconstruct the state object manually.
