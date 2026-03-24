# mitabl Mobile App — Development Guide

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** mobile-app

---

## Prerequisites

- Flutter SDK >=3.5.0
- Dart SDK >=3.5.0
- Android Studio or Xcode
- For Android: Java 17, Android SDK
- For iOS: macOS with Xcode, CocoaPods

---

## Local Setup

```bash
cd mobile-app
flutter pub get
flutter run
```

### Configuration

API endpoints are configured in `assets/cfg/configuration.json`:
```json
{
  "base_url": "https://mitabl.com/",
  "api_base_url": "https://mitabl.com/api/",
  "image_base_url": "https://mitabl.com/"
}
```

For local development, update to point to your local backend:
```json
{
  "base_url": "http://10.0.2.2:8000/",
  "api_base_url": "http://10.0.2.2:8000/api/",
  "image_base_url": "http://10.0.2.2:8000/"
}
```

---

## Running Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/pages/login/login_cubit_test.dart

# Run integration tests (requires emulator/device)
flutter test integration_test/app_test.dart

# Run with coverage
flutter test --coverage
```

### Test Structure
- `test/` — 14 unit/widget test files
- `test/repos/` — Repository tests (HTTP mocking)
- `test/pages/` — Cubit and widget tests
- `test/helper/` — Helper utility tests
- `integration_test/` — Full app smoke test

---

## Build Commands

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release

# iOS build
flutter build ios --release
```

### Android Signing

Release builds use keystore configured in `android/key.properties`. See `docs/APK_BUILDER.md` for details.

---

## Project Structure

```
lib/
├── main.dart              # Entry point (Firebase, config, providers)
├── app.dart               # App widget tree, theme, global providers
├── route_generator.dart   # Named route definitions
├── splash.dart            # Splash screen
├── auth_bloc/             # Authentication BLoC (global)
├── helper/                # Utilities (API contract, config, constants, logger)
├── model/                 # Data models/DTOs
├── repos/                 # Repository layer (API communication)
├── pages/                 # Foodie-facing features
└── pages_cook/            # Cook-facing features
```

### Feature Structure Pattern
```
feature/
├── cubit/
│   ├── feature_cubit.dart   # Business logic
│   └── feature_state.dart   # Immutable state
└── view/
    └── feature_page.dart    # UI widget
```

---

## Code Conventions

- **State Management:** Cubit pattern (not full BLoC events) for all features
- **State Classes:** Extend Equatable, use copyWith, track status via FormzStatus
- **Repositories:** Handle HTTP calls, return parsed models
- **Models:** fromJson/toJson with safe type coercion (_asInt, _asDouble)
- **Navigation:** Named routes via global navigatorKey
- **Error Handling:** Cubits catch → emit failure state with serverMessage → UI shows toast
- **Naming:** Dart conventions (lowerCamelCase variables, PascalCase classes)
