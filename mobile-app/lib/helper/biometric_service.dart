import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mitabl_user/helper/app_logger.dart';

/// Service that wraps [LocalAuthentication] and manages the biometric
/// enabled preference in [FlutterSecureStorage].
///
/// All public methods are safe to call even when biometrics are not available
/// on the device — they will return `false` gracefully.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'biometric_enabled';

  final _auth = LocalAuthentication();

  /// Returns `true` if the device supports biometric authentication and has
  /// at least one enrolled biometric.
  Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      AppLogger.warn('BiometricService.isAvailable error: $e');
      return false;
    }
  }

  /// Returns `true` if the user has opted in to biometric unlock.
  Future<bool> isEnabled() async {
    final value = await _storage.read(key: _enabledKey);
    return value == 'true';
  }

  /// Persists the user's biometric preference.
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: enabled.toString());
  }

  /// Prompts the user and returns `true` on success.
  ///
  /// [reason] is the string shown on the system prompt.
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return true; // Fail open if not available.

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN as fallback
          stickyAuth: true,
        ),
      );
    } catch (e) {
      AppLogger.error('BiometricService.authenticate error', e);
      return false;
    }
  }
}
