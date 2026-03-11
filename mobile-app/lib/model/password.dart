import 'package:mitabl_user/helper/formz_compat.dart';

enum PasswordValidationError { empty }

class Password extends FormzInput<String?, PasswordValidationError> {
  const Password.pure() : super.pure('');

  const Password.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String? value) {
    return value?.isNotEmpty == true && value!.length >= 6
        ? null
        : PasswordValidationError.empty;
  }
}
