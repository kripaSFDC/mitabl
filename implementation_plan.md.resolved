# Mobile App Gap Remediation

The Flutter mobile app (BLoC/Cubit architecture) has seven identified gaps. This plan addresses them in priority order — highest user‑impact / lowest risk first — so each phase can be shipped and validated independently.

> [!IMPORTANT]
> Phase 4 (Push Notifications) requires manual configuration steps: adding `google-services.json` / `GoogleService-Info.plist` to the project. These are excluded from automated implementation and flagged below.

---

## Proposed Changes

### Phase 1 — Offline Error Handling

Offline failures currently produce a generic `"Something went wrong"` toast with no retry path. The fix is a thin connectivity layer that wraps the existing [AuthAwareHttpClient](file:///c:/Code/mitabl/mobile-app/lib/repos/auth_aware_http_client.dart#9-106) and propagates a typed `OfflineException` to Cubits, which then emit a distinct state that the UI renders as an inline retry banner.

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add `connectivity_plus: ^6.0.3`.

#### [NEW] `lib/helper/connectivity_service.dart`
Singleton that exposes a `Stream<bool>` of online status using `connectivity_plus`. Also provides a synchronous `isOnline()` async check.

#### [NEW] `lib/helper/offline_error_widget.dart`
Stateless widget: offline icon + message + "Retry" `ElevatedButton`. Accepts an `onRetry` callback. Reusable across all pages.

#### [MODIFY] [auth_aware_http_client.dart](file:///c:/Code/mitabl/mobile-app/lib/repos/auth_aware_http_client.dart)
Before calling `_inner.send(...)`, call `ConnectivityService.isOnline()`. If offline, throw `OfflineException` (a new simple exception class in `connectivity_service.dart`).

#### [MODIFY] Cubit catch-blocks (login, dashboard, profile, bookings, etc.)
Add an `on OfflineException` branch that emits a dedicated `ConnectivityError` status variant. The existing `FormzStatus` is kept unchanged; a new `apiConnectivityError` enum value is added to the shared state or handled via a side channel.

> [!NOTE]
> Only the two most-used Cubits ([LoginCubit](file:///c:/Code/mitabl/mobile-app/lib/pages/login/cubit/login_cubit.dart#16-81), `DashboardCookCubit`) will be updated as part of this phase as a pattern; the rest follow identically and are listed as follow-ups.

#### [MODIFY] [app.dart](file:///c:/Code/mitabl/mobile-app/lib/app.dart)
Add a global `ConnectivityBanner` in the `builder` of `MaterialApp` that listens to `ConnectivityService.stream` and slides in an `OfflineErrorWidget` at the top when offline — so no per-page changes are needed.

---

### Phase 2 — Biometric Authentication

`flutter_secure_storage` is already used in [UserRepository](file:///c:/Code/mitabl/mobile-app/lib/repos/user_repository.dart#12-296). The missing layer is a biometric unlock screen shown on app resume.

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add `local_auth: ^2.3.0`.

#### [NEW] `lib/helper/biometric_service.dart`
Wraps `LocalAuthentication`. Exposes `isAvailable()`, `authenticate()`, and preference helpers (read/write via `FlutterSecureStorage`). No global state; pure service class.

#### [NEW] `lib/pages/common/biometric_lock_page.dart`
Full-screen widget shown on cold start or resume when biometric is enabled. Shows fingerprint/FaceID icon, triggers `BiometricService.authenticate()`, and on success pops itself. On failure shows a fallback "Use passcode" option that bypasses biometric for that session.

#### [MODIFY] [app.dart](file:///c:/Code/mitabl/mobile-app/lib/app.dart)
Add `WidgetsBindingObserver` to [_AppViewState](file:///c:/Code/mitabl/mobile-app/lib/app.dart#99-200). In `didChangeAppLifecycleState`, when resuming from `paused → resumed`, push `BiometricLockPage` if biometric is enabled. This is the **only** place this logic lives.

#### [MODIFY] Settings pages (`SettingsCookPage`, `ProfileFoodiePage`)
Add a `ListTile` toggle for biometric enable/disable. Calls `BiometricService.setEnabled(bool)`.

---

### Phase 3 — App Update Check

A light version gate on the splash screen.

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add `package_info_plus: ^8.0.0`.

#### [NEW] `lib/helper/update_check_service.dart`
- Reads current build version via `PackageInfo.fromPlatform()`.
- Calls `GET /app/version` (backend endpoint — see note below).
- Returns an `UpdateResult` (none / optional / required) with store URLs.

> [!IMPORTANT]
> **Backend TODO:** Add `GET /app/version` returning `{"minimum": "1.0.0", "latest": "1.2.0", "ios_url": "...", "android_url": "..."}`. This is a one-line config addition — not blocking for Phase 3 mock testing.

#### [NEW] `lib/pages/common/update_gate_widget.dart`
Non-dismissible dialog for `required` updates; dismissible banner for `optional`. Contains a "Update Now" button that calls `url_launcher` to open the store (package already in [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)).

#### [MODIFY] [splash.dart](file:///c:/Code/mitabl/mobile-app/lib/splash.dart)
After `GlobalConfiguration` loads, call `UpdateCheckService.check()`. If `required`, show `UpdateGateWidget`. Otherwise continue to auth check.

---

### Phase 4 — Push Notifications

> [!WARNING]
> This phase requires **manual steps** outside of code: adding Firebase config files. Implementation below marks those explicitly.

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add `firebase_core: ^3.6.0`, `firebase_messaging: ^15.1.3`, `flutter_local_notifications: ^18.0.0`.

#### Manual steps (not automated)
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Run `flutterfire configure` once per environment

#### [MODIFY] [main.dart](file:///c:/Code/mitabl/mobile-app/lib/main.dart)
Call `Firebase.initializeApp()` and register a `FirebaseMessaging.onBackgroundMessage` top-level handler.

#### [NEW] `lib/helper/notification_service.dart`
- Requests permission with `FirebaseMessaging.instance.requestPermission()`.
- On first login, posts FCM token via the **existing** `UserRepository.updateNotificationPreference()` call (already wired to the correct endpoint).
- Sets up `onMessage` handler: delegates to `flutter_local_notifications` for foreground toasts.
- Sets up `onMessageOpenedApp` handler: parses `data.type` (e.g., `booking_confirmed`, `new_order`) and routes to the correct named route via `navigatorKey`.

#### [MODIFY] [app.dart](file:///c:/Code/mitabl/mobile-app/lib/app.dart)
In `_AppViewState.initState`, call `NotificationService.init(navigatorKey)`.

---

### Phase 5 — Deep Linking

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add `app_links: ^6.3.2`.

#### [NEW] `lib/helper/deep_link_service.dart`
- Subscribes to `AppLinks().uriLinkStream`.
- Parses paths and maps them to named routes + `RouteArguments`.
- Exposes a single [init(NavigatorState navigator)](file:///c:/Code/mitabl/mobile-app/lib/app.dart#103-109) method.

Supported initial route map:
| URI path | Named route |
|---|---|
| `/cook/{id}` | `/CookProfile` |
| `/booking/{id}` | `/Bookings` |
| `/order/{id}` | `/OrderDetails` |

#### [MODIFY] Android `AndroidManifest.xml` and iOS `Info.plist`
Add intent filters / URL scheme for `mitabl://` and HTTPS universal links. *(These are config-only changes, no logic.)*

#### [MODIFY] [app.dart](file:///c:/Code/mitabl/mobile-app/lib/app.dart)
In `_AppViewState.initState`, call `DeepLinkService.init(_navigator!)`.

---

### Phase 6 — Accessibility

No new packages needed. Changes are purely additive wrappers.

#### [NEW] `lib/helper/semantic_button.dart`
A `Semantics`-wrapped `GestureDetector`/`IconButton` helper so call sites are one-liners.

#### [MODIFY] All interactive widgets across `pages/` and `pages_cook/`
- Wrap tap targets in `Semantics(label: '...', button: true, child: ...)`.
- Add `semanticLabel` to all [Image](file:///c:/Code/mitabl/mobile-app/lib/repos/user_repository.dart#202-214), `SvgPicture`, and `CachedNetworkImage` usages.
- Add `Semantics(header: true)` to page title `Text` widgets.
- Wrap `StarRating` widget with a `Semantics(value: '$rating out of 5')`.
- Check all containers for fixed heights that clip under large text scale; replace with `constraints: BoxConstraints(minHeight: ...)` where needed.

---

### Phase 7 — Tests

#### [MODIFY] [pubspec.yaml](file:///c:/Code/mitabl/mobile-app/pubspec.yaml)
Add to dev_dependencies: `bloc_test: ^9.1.7`, `mocktail: ^1.0.4`.

#### [NEW] `test/helper/connectivity_service_test.dart`
Unit test for `ConnectivityService.isOnline()` using a mock `Connectivity`.

#### [NEW] `test/helper/biometric_service_test.dart`
Unit test for `BiometricService` with a mocked `LocalAuthentication`.

#### [NEW] `test/helper/update_check_service_test.dart`
Unit test for the version comparison logic using a `MockClient`.

#### [NEW] `test/pages/login/login_cubit_test.dart`
Uses `bloc_test` to test: success, API failure, and offline (`OfflineException`) transitions.

#### [NEW] `test/pages/common/offline_error_widget_test.dart`
Widget test: renders correctly, retry callback fires on tap.

#### [NEW] `test/pages/common/update_gate_widget_test.dart`
Widget test: required update blocks dismissal; optional update shows banner.

#### [NEW] `integration_test/app_test.dart`
Smoke integration test: app launches, lands on Splash, navigates to Landing page.

---

## Verification Plan

### Automated Tests

All unit and widget tests can be run from `c:\Code\mitabl\mobile-app\` with:

```bash
# Unit + widget tests
flutter test

# Integration tests (requires a connected device or emulator)
flutter test integration_test/app_test.dart
```

Existing passing tests live in `test/repos/` and must remain green after each phase.

### Manual Verification

| Feature | Verification Steps |
|---|---|
| **Offline banner** | On a physical device, disable Wi-Fi + cellular → open app → observe inline banner with Retry button. Re-enable network → tap Retry → data loads. |
| **Biometrics** | Enable biometric in Settings → background the app for 30 s → bring it to foreground → verify FaceID/fingerprint prompt appears. |
| **Update gate** | Temporarily set `minimum_version` above current build version in backend → cold-launch app → verify non-dismissible dialog appears. |
| **Push notifications** | Use Firebase Console → Send test message to the device FCM token → verify in-app toast appears; tap notification from tray → verify correct screen opens. |
| **Deep links** | Run `adb shell am start -a android.intent.action.VIEW -d "mitabl://cook/123"` → verify CookProfile opens. |
| **Accessibility** | Enable TalkBack (Android) or VoiceOver (iOS) → navigate login screen → verify all buttons announce meaningful labels. |
