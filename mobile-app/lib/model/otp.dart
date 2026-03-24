import 'package:mitabl_user/helper/formz_compat.dart';

enum OTPValidationError{empty}

class OTP extends FormzInput<String ,OTPValidationError>{
  const OTP.dirty([super.value='']) : super.dirty();
  const OTP.pure():super.pure('');

  @override
  OTPValidationError? validator(String value) {
    return value.isNotEmpty == true && value.length >= 4
        ? null : OTPValidationError.empty;
  }

}