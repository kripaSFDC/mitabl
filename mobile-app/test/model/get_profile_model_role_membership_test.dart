import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/model/get_profile_model.dart';

void main() {
  group('GetCookProfileModel role membership parsing', () {
    test('parses membership from role_statuses container', () {
      final model = GetCookProfileModel.fromJson({
        'status': 200,
        'isSuccess': true,
        'message': 'ok',
        'data': {
          'id': 1,
          'role_statuses': {
            'micook': {
              'exists': '1',
              'active': '0',
              'onboarding_required': 'true',
              'next_required_step': 'kitchen_profile',
            },
            'mifoodi': {
              'exists': true,
              'active': true,
              'onboarding_required': false,
            },
          },
        },
      });

      final cookMembership = model.data?.cookRoleMembership;
      final foodieMembership = model.data?.foodieRoleMembership;

      expect(cookMembership, isNotNull);
      expect(cookMembership!.exists, isTrue);
      expect(cookMembership.active, isFalse);
      expect(cookMembership.onboardingRequired, isTrue);
      expect(cookMembership.nextRequiredStep, 'kitchen_profile');

      expect(foodieMembership, isNotNull);
      expect(foodieMembership!.exists, isTrue);
      expect(foodieMembership.active, isTrue);
      expect(foodieMembership.onboardingRequired, isFalse);
    });

    test('parses direct *_role_membership payload keys', () {
      final model = GetCookProfileModel.fromJson({
        'status': 200,
        'isSuccess': true,
        'message': 'ok',
        'data': {
          'id': 2,
          'cook_role_membership': {
            'exists': true,
            'active': true,
            'onboarding_required': false,
          },
          'foodie_role_membership': {
            'exists': true,
            'active': false,
            'onboarding_required': true,
            'next_required_step': 'profile',
          },
        },
      });

      expect(model.data?.cookRoleMembership, isNotNull);
      expect(model.data?.cookRoleMembership?.active, isTrue);

      expect(model.data?.foodieRoleMembership, isNotNull);
      expect(model.data?.foodieRoleMembership?.onboardingRequired, isTrue);
      expect(model.data?.foodieRoleMembership?.nextRequiredStep, 'profile');
    });
  });
}
