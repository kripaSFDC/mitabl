import 'package:formz/formz.dart';

enum OTPValidationError{empty}

class OTP extends FormzInput<String ,OTPValidationError>{
  const OTP.dirty([String value='']) : super.dirty(value);
  const OTP.pure():super.pure('');

  @override
  OTPValidationError? validator(String value) {
    return value.isNotEmpty == true && value.length==4
        ? null : OTPValidationError.empty;
  }

}