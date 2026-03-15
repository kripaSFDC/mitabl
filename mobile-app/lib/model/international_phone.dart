import 'package:mitabl_user/helper/formz_compat.dart';

enum InternationalPhoneValidationError { empty, invalid }

class InternationalPhone
    extends FormzInput<String, InternationalPhoneValidationError> {
  const InternationalPhone.dirty([super.value = '']) : super.dirty();
  const InternationalPhone.pure() : super.pure('');

  static final RegExp _e164Pattern = RegExp(r'^\+[1-9]\d{6,14}$');

  @override
  InternationalPhoneValidationError? validator(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) {
      return InternationalPhoneValidationError.empty;
    }

    return _e164Pattern.hasMatch(normalized)
        ? null
        : InternationalPhoneValidationError.invalid;
  }

  static String compose({required String countryCode, required String number}) {
    final normalizedCountryCode =
        countryCode.replaceAll(RegExp(r'[^\d+]'), '').trim();
    final normalizedNumber = number.replaceAll(RegExp(r'\D'), '');
    if (normalizedCountryCode.isEmpty || normalizedNumber.isEmpty) {
      return '';
    }

    final prefixedCountryCode = normalizedCountryCode.startsWith('+')
        ? normalizedCountryCode
        : '+$normalizedCountryCode';

    return _normalize('$prefixedCountryCode$normalizedNumber');
  }

  static String _normalize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return '';
    }

    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }

    return '+$digits';
  }
}
