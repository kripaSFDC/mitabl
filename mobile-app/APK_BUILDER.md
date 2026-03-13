# APK Builder Guide

This guide provides step-by-step instructions for building and distributing Android APK files for the Mitabl mobile application.

## Prerequisites

- **Flutter SDK**: Ensure Flutter is installed and in your system PATH
- **Android SDK**: Must be installed with proper environment variables configured
- **Java Development Kit (JDK)**: Required for Android compilation
- **Adequate Disk Space**: At least 2GB free space for build artifacts

## Quick Start

### 1. Navigate to the Mobile App Directory

```powershell
cd c:\Code\mitabl\mobile-app
```

### 2. Clean Previous Build Artifacts

```powershell
flutter clean
```

**What it does:**
- Removes the `build/` directory containing all compiled files
- Deletes `.dart_tool/` directory
- Clears cache files
- Ensures a fresh, clean build environment

### 3. Get Dependencies

```powershell
flutter pub get
```

**What it does:**
- Downloads and installs all packages listed in `pubspec.yaml`
- Resolves dependency versions
- Prepares the project for compilation

### 4. Build the Release APK

```powershell
flutter build apk --release
```

**What it does:**
- Compiles the Dart code to native Android code
- Optimizes assets and resources
- Generates an optimized, production-ready APK
- Removes debug symbols and unused code
- **Estimated time**: 3-5 minutes depending on system performance

### 5. Verify the Build

Once the build completes successfully, verify the APK file was created:

```powershell
Get-Item "build\app\outputs\flutter-apk\app-release.apk" | Select-Object FullName, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}
```

## Output Location

The generated APK file will be available at:

```
c:\Code\mitabl\mobile-app\build\app\outputs\flutter-apk\app-release.apk
```

**File Size**: Typically 50-70 MB (optimized for distribution)

## Build Variants

### Release APK (Recommended for Distribution)

```powershell
flutter build apk --release
```

**Characteristics:**
- Optimized for performance and size
- No debug symbols
- Production-ready
- Smaller file size
- Slower build process

### Debug APK (Faster Build for Testing)

```powershell
flutter build apk
```

**Characteristics:**
- Includes debug symbols
- Faster compilation
- Larger file size
- Suitable for development and testing

### App Bundle (For Google Play Store)

```powershell
flutter build appbundle --release
```

**Characteristics:**
- Optimized format for Google Play Store
- Smaller downloads for end users
- Required for Play Store submission
- Generated at: `build\app\outputs\bundle\release\app-release.aab`

## Installation Methods

### Method 1: Direct APK Transfer

1. Connect your Android device via USB
2. Copy the APK to your device
3. Open a file manager on the device
4. Navigate to the APK file
5. Tap to install
6. Allow installation from unknown sources if prompted

### Method 2: Using ADB (Android Debug Bridge)

**Prerequisites:**
- Android SDK Platform Tools installed
- Device connected via USB
- USB debugging enabled on device

```powershell
adb install c:\Code\mitabl\mobile-app\build\app\outputs\flutter-apk\app-release.apk
```

**Verify installation:**

```powershell
adb shell pm list packages | findstr "com.yourcompany.mitabl"
```

### Method 3: Multiple Devices

Install on all connected devices:

```powershell
adb devices
adb install -r c:\Code\mitabl\mobile-app\build\app\outputs\flutter-apk\app-release.apk
```

The `-r` flag allows reinstallation over existing version.

## Troubleshooting

### Build Failures

**"Android SDK not found"**
- Ensure Android SDK is installed
- Check `ANDROID_SDK_ROOT` environment variable is set
- Verify path: `echo $env:ANDROID_SDK_ROOT`

**"Gradle build failed"**
```powershell
flutter clean
flutter pub get
flutter build apk --release
```

**"Java not found"**
- Install Java Development Kit (JDK) 11 or higher
- Verify: `java -version`

### Installation Issues

**"Installation failed: INSTALL_FAILED_USER_RESTRICTED"**
- Issue: App is already installed
- Solution: Uninstall first with `adb uninstall com.yourcompany.mitabl`

**"Installation failed: INSTALL_FAILED_INSUFFICIENT_STORAGE"**
- Issue: Device storage is full
- Solution: Free up space on the device

**"Unknown error: 'adb' is not recognized"**
- Issue: ADB is not in PATH
- Solution: Add Android SDK platform-tools to PATH or use full path to adb

## Automated Build Script

Create a batch file `build-apk.bat` for one-command builds:

```batch
@echo off
cd /d c:\Code\mitabl\mobile-app
echo Cleaning build...
call flutter clean
echo Getting dependencies...
call flutter pub get
echo Building APK...
call flutter build apk --release
echo.
echo Build complete! APK location:
echo c:\Code\mitabl\mobile-app\build\app\outputs\flutter-apk\app-release.apk
pause
```

Run with:
```powershell
.\build-apk.bat
```

## Performance Tips

1. **Increase Gradle Heap Size**: Edit `android/gradle.properties`:
   ```
   org.gradle.jvmargs=-Xmx4096m
   ```

2. **Use Ahead-of-Time Compilation**: Already enabled in release builds

3. **Split APK by Architecture** (reduces size):
   ```powershell
   flutter build apk --release --split-per-abi
   ```
   Creates separate APKs for arm64 and armeabi-v7a architectures

4. **Cache Dependencies**: Keep `.gradle` cache between builds

## Continuous Integration

### GitHub Actions Example

```yaml
- name: Build APK
  run: |
    cd mobile-app
    flutter clean
    flutter pub get
    flutter build apk --release
    
- name: Upload APK
  uses: actions/upload-artifact@v3
  with:
    name: app-release
    path: mobile-app/build/app/outputs/flutter-apk/app-release.apk
```

## Distribution Checklist

- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] All tests passing
- [ ] Release APK built successfully
- [ ] APK tested on multiple device types
- [ ] App signing certificate in place (for Play Store)
- [ ] Release notes prepared
- [ ] Privacy policy updated (if needed)

## Environment Variables

**Recommended `.env` file for development:**

```
ANDROID_SDK_ROOT=C:\Android\sdk
JAVA_HOME=C:\Program Files\Java\jdk-11
FLUTTER_ROOT=C:\flutter
PATH=%FLUTTER_ROOT%\bin;%ANDROID_SDK_ROOT%\platform-tools;%PATH%
```

## Additional Resources

- [Flutter Official Build Guide](https://flutter.dev/docs/deployment/android)
- [Google Play Store Submission](https://play.google.com/apps/publish/)
- [Android Development Docs](https://developer.android.com/)

---

**Last Updated**: March 14, 2026
**Maintained by**: Mitabl Development Team
