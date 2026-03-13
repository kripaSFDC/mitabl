import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/helper/connectivity_service.dart';

/// Light unit tests for ConnectivityService helpers.
/// The singleton stream and isOnline() method depend on platform plugins —
/// full integration tests are in the integration_test suite.
void main() {
  group('OfflineException', () {
    test('implements Exception', () {
      const e = OfflineException();
      expect(e, isA<Exception>());
    });

    test('has meaningful toString', () {
      expect(const OfflineException().toString(), contains('OfflineException'));
    });

    test('two instances are equal in type', () {
      const a = OfflineException();
      const b = OfflineException();
      expect(a.runtimeType, b.runtimeType);
    });
  });
}
