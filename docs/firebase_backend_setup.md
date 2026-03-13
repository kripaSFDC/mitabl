# Firebase & Backend Setup Guide

This guide covers the two remaining manual steps needed to complete push notifications and the version-gate endpoint.

---

## Part 1 - Firebase Push Notifications

### What was already done in code

| File                                                                                                           | Change                                                                    |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [android/build.gradle](file:///c:/Code/mitabl/mobile-app/android/build.gradle)                                 | Google Services classpath added                                           |
| [android/app/build.gradle](file:///c:/Code/mitabl/mobile-app/android/app/build.gradle)                         | `com.google.gms.google-services` plugin applied                           |
| [lib/firebase_options.dart](file:///c:/Code/mitabl/mobile-app/lib/firebase_options.dart)                       | Placeholder created (will be replaced by flutterfire)                     |
| [lib/main.dart](file:///c:/Code/mitabl/mobile-app/lib/main.dart)                                               | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` |
| [lib/helper/notification_service.dart](file:///c:/Code/mitabl/mobile-app/lib/helper/notification_service.dart) | Full FCM handling wired to `AppView.initState`                            |

### Step 1 - Create a Firebase project (if you don't have one)

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `mitabl` → Continue
3. Disable Google Analytics if not needed → **Create project**

### Step 2 - Add the Android app to Firebase

1. In the Firebase Console, click the **Android icon** (Add app)
2. Fill in:
   - **Android package name**: `com.mitabl.user.mitabl_user`  ← already in your [build.gradle](file:///c:/Code/mitabl/mobile-app/android/build.gradle)
   - **App nickname**: Mitabl Android
   - SHA-1: leave blank for now (add later for Google Sign-In if needed)
3. Click **Register app**
4. Click **Download `google-services.json`**
5. Place the file at:
   
   ```
   c:\Code\mitabl\mobile-app\android\app\google-services.json
   ```
6. Click **Next → Next → Continue to console** (the Gradle steps are already done)

### Step 3 - Add the iOS app to Firebase

1. Click the **iOS icon** (Add app)
2. Fill in:
   - **iOS bundle ID**: check your Xcode project → Runner target → General → Bundle Identifier  
     (typically `com.mitabl.user.mitabl-user` or similar)
   - **App nickname**: Mitabl iOS
3. Click **Register app**
4. Click **Download `GoogleService-Info.plist`**
5. **Open Xcode** (not just the file manager):
   - Open `c:\Code\mitabl\mobile-app\ios\Runner.xcworkspace`
   - Right-click the **Runner** folder in the left panel → **Add Files to "Runner"**
   - Select `GoogleService-Info.plist` → make sure **"Copy items if needed"** is checked → **Add**
6. Click **Next → Next → Continue to console**

### Step 4 - Install the FlutterFire CLI and configure

Run these commands from your terminal (PowerShell or any shell):

```powershell
# 1. Activate the CLI (once per machine)
dart pub global activate flutterfire_cli

# 2. Log in to Firebase
firebase login

# 3. From the mobile-app folder, run configuration
cd c:\Code\mitabl\mobile-app
flutterfire configure --project=<your-firebase-project-id>
```

**What `flutterfire configure` does:**

- Downloads and places `google-services.json` → `android/app/`
- Downloads and places `GoogleService-Info.plist` → `ios/Runner/`
- **Overwrites** the placeholder `lib/firebase_options.dart` with the real one

> After this, `lib/firebase_options.dart` will contain real API keys and `DefaultFirebaseOptions.currentPlatform` will work.

### Step 5 - iOS APNs key (required for push to work on iOS)

1. Go to [Apple Developer](https://developer.apple.com) → **Certificates, IDs & Profiles** → **Keys**
2. Click **+** → name it `Mitabl FCM Key` → check **Apple Push Notifications service (APNs)** → Continue → Register
3. Download the `.p8` key file (only downloadable once!)
4. Back in Firebase Console: **Project settings** → **Cloud Messaging** → **Apple app configuration**
5. Upload the `.p8` file, enter your **Key ID** and **Team ID** (both visible in Apple Developer portal)

### Step 6 - Enable Cloud Messaging API

In Firebase Console:  
**Project settings → Cloud Messaging** → Ensure **Firebase Cloud Messaging API (V1)** is **Enabled**.

### Step 7 - Test it

```powershell
# Run the app on a real device (emulators don't receive push on iOS)
cd c:\Code\mitabl\mobile-app
flutter run
```

In Firebase Console → **Messaging** → **Send your first message** → select your app → Send to **Device token** (printed in the Flutter debug console by `NotificationService.getToken()`).

---

## Part 2 - Backend `/app/version` Endpoint

### What was already done in code

| File                                                | Change                                                                                   |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `app/Http/Controllers/Api/AppVersionController.php` | **NEW** controller reading from env                                                      |
| `routes/api.php`                                    | `GET /app/version` route added (no auth, throttle 60/min)                                |
| `config/app.php`                                    | `version_minimum`, `version_latest`, `version_ios_url`, `version_android_url` keys added |
| `.env.example`                                      | `APP_VERSION_*` vars documented                                                          |

### Step 1 - Add the env vars to your `.env` (and production config)

```ini
APP_VERSION_MINIMUM=1.0.0
APP_VERSION_LATEST=1.0.0
APP_VERSION_IOS_URL=https://apps.apple.com/app/mitabl/id<YOUR_APP_STORE_ID>
APP_VERSION_ANDROID_URL=https://play.google.com/store/apps/details?id=com.mitabl.user.mitabl_user
```

### Step 2 - Test the endpoint locally

```bash
curl http://localhost:8080/api/app/version
```

Expected response:

```json
{
  "minimum": "1.0.0",
  "latest": "1.0.0",
  "ios_url": "https://apps.apple.com/...",
  "android_url": "https://play.google.com/..."
}
```

### Step 3 - How to force an upgrade

When you release a breaking API version (e.g., `2.0.0`):

```ini
# In production .env - no redeploy needed, just restart PHP-FPM or clear config cache
APP_VERSION_MINIMUM=2.0.0
APP_VERSION_LATEST=2.0.0
```

Then run:

```bash
php artisan config:cache
```

All users on `< 2.0.0` will see the **Update Required** dialog and cannot proceed.

### Step 4 - Point the mobile app at the correct base URL

Make sure `api_base_url` in `mobile-app/assets/configuration.json` points to your live backend:

```json
{
  "api_base_url": "https://api.yourdomain.com/api/"
}
```

The `UpdateCheckService` uses `ApiContract.uri('app/version')` which resolves to `{api_base_url}app/version`.

---

## Where to find your Store IDs

| Platform                 | Where to find                                              |
| ------------------------ | ---------------------------------------------------------- |
| **iOS App Store ID**     | App Store Connect → My Apps → App Information → Apple ID   |
| **Android package name** | Already `com.mitabl.user.mitabl_user` from `build.gradle`  |
| **Firebase project ID**  | Firebase Console → Project settings → General → Project ID |
