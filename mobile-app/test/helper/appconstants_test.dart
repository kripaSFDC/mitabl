import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/helper/appconstants.dart';

void main() {
  group('AppConstants.isCookRole', () {
    test('returns true for cook role aliases', () {
      expect(AppConstants.isCookRole('Restaurant'), isTrue);
      expect(AppConstants.isCookRole('cook'), isTrue);
      expect(AppConstants.isCookRole('miCook'), isTrue);
      expect(AppConstants.isCookRole('mikitchn'), isTrue);
      expect(AppConstants.isCookRole(' KITCHEN '), isTrue);
      expect(AppConstants.isCookRole('vendor'), isTrue);
    });

    test('returns false for non-cook values', () {
      expect(AppConstants.isCookRole('foodie'), isFalse);
      expect(AppConstants.isCookRole('customer'), isFalse);
      expect(AppConstants.isCookRole(''), isFalse);
      expect(AppConstants.isCookRole(null), isFalse);
    });
  });
}
