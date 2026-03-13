# Firebase Setup For Mitabl (Mobile + Backend)

This document is a complete, click-by-click guide for enabling Firebase Cloud Messaging end to end.

It includes:
1. Firebase Console setup
2. Mobile app setup (Flutter Android + iOS)
3. Backend setup (Laravel FCM delivery path)
4. Verification and production checklist

---

## 0) Exact app identifiers from this project

Use these exact values when registering Firebase apps:

1. Android package name:
   com.mitabl.user.mitabl_user

2. iOS bundle identifier:
   com.mitabl.user.mitablUser

Where they come from:
1. mobile-app/android/app/build.gradle
2. mobile-app/ios/Runner.xcodeproj/project.pbxproj

---

## 1) Firebase Console setup (click-by-click)

### 1.1 Create Firebase project

1. Open https://console.firebase.google.com
2. Click Add project.
3. Project name: Mitabl Production (or your chosen name).
4. Continue.
5. Google Analytics: enable or disable as your policy requires.
6. Click Create project.

### 1.2 Add Android app in Firebase

1. In Firebase project home, click Android icon.
2. Android package name: com.mitabl.user.mitabl_user
3. App nickname: Mitabl Android
4. Debug signing certificate SHA-1: optional for push, can skip for now.
5. Click Register app.
6. Click Download google-services.json.
7. Save file to:
   mobile-app/android/app/google-services.json
8. Click Next until Continue to console.

### 1.3 Add iOS app in Firebase

1. In Firebase project home, click iOS icon.
2. iOS bundle ID: com.mitabl.user.mitablUser
3. App nickname: Mitabl iOS
4. Click Register app.
5. Click Download GoogleService-Info.plist.
6. Open Xcode workspace:
   mobile-app/ios/Runner.xcworkspace
7. In Xcode left panel, right click Runner folder.
8. Click Add Files to Runner.
9. Select GoogleService-Info.plist.
10. Check Copy items if needed.
11. Ensure Runner target is checked.
12. Click Add.
13. Back in Firebase console click Continue to console.

### 1.4 Configure APNs for iOS push delivery

1. Go to Apple Developer portal.
2. Open Certificates, Identifiers and Profiles.
3. Open Keys section.
4. Click plus button to create new key.
5. Name: Mitabl FCM APNs Key
6. Enable Apple Push Notifications service (APNs).
7. Register and download p8 key file.
8. Copy and store:
   1. Key ID
   2. Team ID
   3. p8 file
9. Back in Firebase console, open Project settings.
10. Open Cloud Messaging tab.
11. Under Apple app configuration, upload p8 file.
12. Enter Key ID and Team ID.
13. Save.

### 1.5 Confirm Cloud Messaging APIs

1. Firebase console > Project settings > Cloud Messaging.
2. Confirm Firebase Cloud Messaging API (v1) is enabled.

Important for this backend:
1. Current backend code sends via legacy endpoint https://fcm.googleapis.com/fcm/send.
2. It expects a server key string.
3. In Firebase Cloud Messaging tab, obtain the legacy server key if your project still exposes it.
4. If legacy key is not available, backend must be migrated to HTTP v1 service-account flow before production push can work.

---

## 2) Mobile app setup (Flutter side)

### 2.1 Install Firebase CLI tools (one-time per machine)

Run in terminal:

1. dart pub global activate flutterfire_cli
2. npm install -g firebase-tools
3. firebase login

### 2.2 Generate firebase_options.dart

From mobile-app folder:

1. cd c:/Code/mitabl/mobile-app
2. flutterfire configure --project YOUR_FIREBASE_PROJECT_ID

Result:
1. lib/firebase_options.dart is generated with real options.
2. Android and iOS Firebase app references are wired.

### 2.3 Ensure Android Google Services plugin is active

Open mobile-app/android/app/build.gradle and verify plugin line is active.

Current file uses:
1. id 'com.google.gms.google-services' apply false

For Firebase processing in app module, this must be active in the app module build:
1. id 'com.google.gms.google-services'

If left as apply false, google-services.json may not be processed correctly.

### 2.4 Confirm iOS capabilities in Xcode

In Runner target:

1. Signing and Capabilities > add Push Notifications capability.
2. Signing and Capabilities > add Background Modes capability.
3. In Background Modes, enable Remote notifications.

### 2.5 Build and validate mobile initialization

From mobile-app folder:

1. flutter clean
2. flutter pub get
3. flutter run

Success criteria:
1. No startup warning about firebase_options.dart not generated.
2. No warning saying Firebase initialization skipped.

---

## 3) Backend setup (Laravel side)

This project currently delivers push notifications through:
1. app/Listeners/LogNotification.php
2. app/Http/Controllers/Api/FcmController.php
3. config key services.fcm.server_key

### 3.1 Set the FCM key in Platform Admin

Preferred method in this codebase:
1. Login to platform admin.
2. Open Platform Settings page.
3. Find key integrations.fcm.server_key.
4. Paste Firebase FCM server key value.
5. Save settings.

Why this is required:
1. Runtime mapping in app/Services/PlatformRuntimeConfigService.php maps integrations.fcm.server_key to services.fcm.server_key.
2. FcmController reads config services.fcm.server_key when sending.

### 3.2 Verify backend health status for FCM

1. Call GET /api/health/ready
2. Check checks list contains key fcm.
3. Expect message FCM server key is configured.

If it still says not configured:
1. Confirm Platform Settings value saved.
2. Restart backend containers or clear Laravel caches.

### 3.3 Ensure queue workers are running

Push sending is triggered from notification listener that implements ShouldQueue.

Check queue worker service is healthy in production stack.

For local container setups, ensure queue worker process is running before testing push.

### 3.4 Ensure device token is reaching backend

User device token is saved in users.device_token.

Current backend routes expose:
1. POST /api/v2/account/device-token
2. POST /api/v2/account/notifications/toggle

Current mobile repository call uses:
1. POST /api/v2/account/notification-preferences

Action required:
1. Keep backend and mobile endpoint naming aligned.
2. If backend does not expose notification-preferences, either:
   1. update mobile to use existing backend routes, or
   2. add compatibility endpoint in backend.

Without this alignment, push may initialize in app but device token may not persist server-side.

### 3.5 Backend smoke test

After user logs in on device:

1. Confirm users.device_token is non-empty for that user.
2. Trigger a known notification event from app flow (for example order status change).
3. Check backend logs for notification listener execution.
4. Confirm device receives push.

---

## 4) End-to-end test procedure

1. Start backend API and queue worker.
2. Run mobile app on physical Android device.
3. Login with test user.
4. Confirm device token saved in backend.
5. Send test message from Firebase Console Messaging to the device token.
6. Verify message appears when app is:
   1. foreground
   2. background
   3. terminated
7. Repeat on iOS physical device after APNs setup.

---

## 5) Production readiness checklist

1. Firebase Android app registered with exact package id.
2. Firebase iOS app registered with exact bundle id.
3. google-services.json present in android/app.
4. GoogleService-Info.plist added to Runner target in Xcode.
5. APNs key uploaded in Firebase.
6. flutterfire configure completed successfully.
7. mobile-app/lib/firebase_options.dart generated from Firebase.
8. Android google-services plugin active in app build.gradle.
9. Backend integrations.fcm.server_key set in Platform Settings.
10. /api/health/ready reports FCM configured.
11. Queue worker running in production.
12. Device token persistence verified in users table.
13. Push delivery verified on Android and iOS physical devices.

---

## 6) Known current behavior if Firebase is not configured

The app is intentionally resilient:
1. App still works for login and core features.
2. NotificationService initialization is skipped safely.
3. Push notifications do not work until setup above is complete.
