import 'package:mitabl_user/helper/formz_compat.dart';

enum PhoneValidationError{empty}

class Phone extends FormzInput<String ,PhoneValidationError>{
  const Phone.dirty([super.value='']) : super.dirty();
  const Phone.pure():super.pure('');

  @override
  PhoneValidationError? validator(String value) {
    return value.isNotEmpty == true
        ? null : PhoneValidationError.empty;
  }

}