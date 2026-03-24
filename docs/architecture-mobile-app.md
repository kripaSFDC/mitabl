# mitabl Mobile App — Architecture Document

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** mobile-app | **Type:** Flutter Mobile App (Foodie + Cook)

---

## Executive Summary

The mitabl mobile app is a Flutter application serving as a single binary for both **Foodie** (customer) and **Cook** (restaurant operator) experiences. It uses the BLoC/Cubit pattern for state management, communicates with the Laravel backend via REST/JSON with JWT authentication, and supports offline detection, biometric auth, push notifications, deep linking, and app update gating.

---

## Technology Stack

| Category | Technology | Version | Justification |
|----------|-----------|---------|---------------|
| Framework | Flutter | SDK >=3.5.0 | Cross-platform iOS/Android from single codebase |
| Language | Dart | >=3.5.0 | Type-safe, AOT-compiled for mobile performance |
| State Management | flutter_bloc / Cubit | 9.0.0 | Predictable state management with separation of concerns |
| HTTP Client | http | 1.2.2 | Lightweight HTTP with custom AuthAwareHttpClient wrapper |
| Auth Storage | flutter_secure_storage | 10.0.0 | Encrypted token storage (Keychain/Keystore) |
| Config | global_configuration | 2.0.0 | JSON-based endpoint configuration from assets |
| Form Validation | formz | 0.7.0 | Type-safe form input validation |
| Push Notifications | firebase_messaging + flutter_local_notifications | 15.1.3 / 18.0.0 | FCM push + local notification display |
| Biometrics | local_auth | 2.3.0 | Fingerprint/Face ID authentication |
| Deep Linking | app_links | 6.3.2 | Universal links and custom scheme handling |
| Geolocation | geolocator + geocoding | 14.0.2 / 4.0.0 | GPS positioning + reverse geocoding |
| Offline Detection | connectivity_plus | 6.0.3 | Network status monitoring |
| App Updates | package_info_plus | 8.0.0 | Semver version checking against backend |
| Image Caching | cached_network_image | 3.4.1 | Network image caching with placeholders |
| Carousel | carousel_slider | 5.1.2 | Home page content carousels |
| Testing | flutter_test + bloc_test + mocktail | - | Widget, BLoC, and mock-based testing |

---

## Architecture Pattern

**BLoC/Cubit with Repository Pattern:**

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                        │
│   (Pages / Widgets — BlocBuilder, BlocListener)  │
├─────────────────────────────────────────────────┤
│               State Management                    │
│   (Cubits emit States via copyWith pattern)      │
│   AuthenticationBloc (global), Feature Cubits     │
├─────────────────────────────────────────────────┤
│               Repository Layer                    │
│   (AuthRepo, UserRepo, HomeRepo, BookingRepo,    │
│    CookRepo, SessionRepo, SupportTicketRepo)     │
├─────────────────────────────────────────────────┤
│             AuthAwareHttpClient                   │
│   (Automatic 401 retry, token refresh,           │
│    offline detection, multipart replay)          │
├─────────────────────────────────────────────────┤
│           Backend REST API (JWT)                  │
└─────────────────────────────────────────────────┘
```

---

## App Initialization Sequence

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load configuration from `assets/cfg/configuration.json`
3. Enable Google Fonts runtime fetching
4. Set `AppBlocObserver` as global BLoC observer
5. Initialize Firebase (gracefully skipped if not configured)
6. Register background push notification handler
7. Create core dependencies: `SessionRepository`, `AuthAwareHttpClient`, `UserRepository`
8. Wire `UserRepository` to `SessionRepository` for token refresh callbacks
9. Launch `App` widget with `MultiRepositoryProvider` + `MultiBlocProvider`

---

## Widget Tree

```
App (StatelessWidget)
  └── MultiRepositoryProvider
        ├── AuthenticationRepository
        ├── UserRepository
        ├── SessionRepository (with dispose)
        └── SupportTicketRepository (with dispose)
      └── MultiBlocProvider
            ├── AuthenticationBloc (global)
            ├── DashboardCookCubit (global)
            ├── ProfileCookCubit (global)
            ├── ProfileFoodieCubit (global)
            └── AddMenuCubit (global)
          └── AppView (StatefulWidget + WidgetsBindingObserver)
                ├── BlocListener<AuthenticationBloc> (auth-based navigation)
                ├── ConnectivityBanner (offline indicator)
                ├── BiometricLockPage (on app resume)
                └── MaterialApp with named routes
```

---

## Authentication Flow

1. User enters email/password on LoginPage
2. `LoginCubit.doLogin()` → `AuthenticationRepository.logIn()` → `POST /api/login`
3. JWT token returned, stored via `UserRepository.setCurrentUser()` in `FlutterSecureStorage`
4. `AuthenticationRepository` emits `authenticated` status
5. `AuthenticationBloc` processes status, emits `AuthenticationState.authenticated(user)`
6. `AppView` listener navigates to `/HomePage` (foodie) or `/DashboardCook` (cook)

### Token Refresh
- `AuthAwareHttpClient` intercepts 401 responses
- Calls `SessionRepository.refreshAccessToken()` → `POST /api/token/refresh`
- On success: updates stored user, retries original request (including multipart)
- On failure: emits `SessionEvent.unauthorized` → clears session → navigates to landing

### Biometric Lock
- Opt-in via settings (stored in secure storage)
- `BiometricLockPage` shown on `AppLifecycleState.resumed` events
- Uses `local_auth` for fingerprint/Face ID
- Fails open when biometrics unavailable on device

---

## Routing (25 Named Routes)

| Route | Page | Auth Required | Persona |
|-------|------|--------------|---------|
| `/Splash` | SplashPage | No | Both |
| `/LandingPage` | LandingPage | No | Both |
| `/LoginPage` | LoginPage | No | Both |
| `/SignUpPage` | SignupPage | No | Both |
| `/ForgotPage` | ForgotPage | No | Both |
| `/OTPPage` | OTPPage | No | Both |
| `/HomePage` | HomePage | Yes | Foodie |
| `/ProfileFoodie` | ProfileFoodiePage | Yes | Foodie |
| `/EditProfileFoodie` | EditProfileFoodiePage | Yes | Foodie |
| `/CookProfile` | CookProfilePage | Yes | Cook |
| `/DashboardCook` | DashBoardCookPage | Yes | Cook |
| `/ProfileCook` | EditProfileCookPage | Yes | Cook |
| `/EditKitchenProfile` | EditKitchenProfilePage | Yes | Cook |
| `/MenuDetails` | MenuDetails | Yes | Cook |
| `/AddMenuPage` | AddMenuPage | Yes | Cook |
| `/Bookings` | Bookings | Yes | Cook |
| `/UpcomingBookings` | UpcomingBookings | Yes | Cook |
| `/CustomerReviewPage` | CustomerReviewPage | Yes | Cook |
| `/SettingsCook` | SettingsCookPage | Yes | Cook |
| `/UserDetails` | UserDetails | Yes | Cook |
| `/OrderDetails` | OrderDetails | Yes | Cook |

---

## Repository Layer

| Repository | Endpoints Called | Purpose |
|-----------|----------------|---------|
| AuthenticationRepository | login, register, verifyOtp, password/reset, v2/logout, v2/mikitchn/store | Auth lifecycle + cook onboarding |
| UserRepository | v2/account/profile, v2/editprofile, v2/account/switch-role, v2/account/delete, v2/deleteimage, v2/mikitchn/editkitchen, v2/account/notification-preferences, v2/account/dashboard | Profile management + dashboard |
| SessionRepository | token/refresh | JWT token refresh with deduplication |
| HomeRepository | v2/discovery/recommended, v2/discovery/top-rated, v2/discovery/nearest | Restaurant discovery feeds |
| CookRepository | v2/mymenu, v2/getspecialdiets, v2/getcookingstyles, v2/food/add, v2/food/editfood, v2/food/status/{id} | Menu management |
| BookingRepository | v2/allorders, v2/kitchenupcomingorders, v2/kitchenorderrequest, v2/updateorderstatus | Order/booking management |
| SupportTicketRepository | /support/ticket (create, show, reply) | Support ticket operations |
| MobileContactRepository | v2/mob-contact | Contact info |

---

## State Management Patterns

### Cubit Pattern (used for all features)
```dart
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit({required this.repository}) : super(const FeatureState());

  Future<void> loadData() async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      final data = await repository.fetchData();
      emit(state.copyWith(status: FormzStatus.submissionSuccess, data: data));
    } catch (e) {
      emit(state.copyWith(status: FormzStatus.submissionFailure, serverMessage: e.toString()));
    }
  }
}
```

### State Pattern
```dart
class FeatureState extends Equatable {
  final FormzStatus status;
  final String serverMessage;
  // ... feature-specific fields

  FeatureState copyWith({...}) => FeatureState(status: status ?? this.status, ...);

  @override
  List<Object?> get props => [status, serverMessage, ...];
}
```

### Provider Scoping
- **Global Cubits** (App level): AuthenticationBloc, DashboardCookCubit, ProfileCookCubit, ProfileFoodieCubit, AddMenuCubit
- **Page Cubits** (Route level): LoginCubit, SignUpCubit, OtpCubit, ForgotCubit, HomeCubit, etc.

---

## Offline Handling

1. `ConnectivityService` singleton monitors network state via `connectivity_plus`
2. `AuthAwareHttpClient` checks `isOnline()` before every HTTP request
3. Throws `OfflineException` when offline (caught by cubits for UI feedback)
4. `ConnectivityBanner` overlay slides in/out as network changes
5. `OfflineErrorWidget` provides retry button for feed sections
6. `HomeCubit` caches discovery feeds in `SharedPreferences` (10-min TTL per user)

---

## Push Notifications

1. Firebase initialized at app startup (graceful skip if unconfigured)
2. `NotificationService` singleton manages FCM registration and display
3. Android notification channel: `mitabl_default`
4. Foreground notifications displayed via `flutter_local_notifications`
5. Tap routing: `booking_confirmed`/`booking_cancelled` → `/Bookings`, `new_order` → `/Bookings`, `upcoming_booking` → `/UpcomingBookings`
6. FCM token synced with backend via `UserRepository.updateNotificationPreference()`

---

## Deep Linking

- **Custom scheme:** `mitabl://`
- **Universal links:** `https://mitabl.com`
- **Supported paths:** `/cook/{id}` → CookProfile, `/booking/{id}` → Bookings, `/order/{id}` → Bookings
- **Android:** Intent filters with `autoVerify` in AndroidManifest.xml
- **iOS:** URL scheme in Info.plist

---

## Testing Strategy

| Type | Files | Coverage |
|------|-------|---------|
| Unit Tests (Cubits) | 1 | Login cubit (success, failure, offline) |
| Unit Tests (Repos) | 5 | AuthAwareHttpClient, auth_headers, bookings, support tickets, user switch role |
| Unit Tests (Helpers) | 4 | AppConstants, BiometricService, ConnectivityService, UpdateCheckService |
| Widget Tests | 3 | Route generator, offline widgets, update gate |
| Integration Tests | 1 | Full app smoke test |

---

## Platform Configuration

### Android
- **App ID:** `com.mitabl.user.mitabl_user`
- **Min/Target SDK:** Flutter defaults
- **Permissions:** Internet, Camera (optional), Location (fine + coarse), Notifications
- **Deep links:** `mitabl://` scheme + `https://mitabl.com` universal links
- **Network security:** Cleartext traffic disabled

### iOS
- **Bundle:** `mitabl_user`
- **Display Name:** Mitabl
- **Orientation:** Portrait only
- **Permissions:** Camera, Photo Library, Location (when in use)
- **Background modes:** fetch, remote-notification
- **URL scheme:** `mitabl`
