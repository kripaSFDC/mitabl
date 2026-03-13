import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mitabl_user/helper/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('BiometricService preference persistence', () {
    test('is disabled by default', () async {
      final enabled = await BiometricService.instance.isEnabled();
      expect(enabled, isFalse);
    });

    test('setEnabled(true) persists preference', () async {
      await BiometricService.instance.setEnabled(true);
      final enabled = await BiometricService.instance.isEnabled();
      expect(enabled, isTrue);
    });

    test('setEnabled(false) persists preference', () async {
      await BiometricService.instance.setEnabled(true);
      await BiometricService.instance.setEnabled(false);
      final enabled = await BiometricService.instance.isEnabled();
      expect(enabled, isFalse);
    });
  });
}
