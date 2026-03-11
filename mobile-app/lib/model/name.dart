import 'package:mitabl_user/helper/formz_compat.dart';

enum NameValidationError{empty}

class Name extends FormzInput<String ,NameValidationError>{
  const Name.dirty([super.value='']) : super.dirty();
  const Name.pure():super.pure('');

  @override
  NameValidationError? validator(String value) {
    return value.isNotEmpty == true
        ? null : NameValidationError.empty;
  }

}