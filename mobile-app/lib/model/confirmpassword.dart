import 'package:formz/formz.dart';

enum PasswordValidationError { empty,addPasswordFirst_,passwordNotMatched }

class ConfirmPassword extends FormzInput<Map<String,String> ,
    PasswordValidationError> {
  static const Map<String,String>  list={};

  // ignore: sort_constructors_first
  const ConfirmPassword.pure() : super.pure(list);
  // ignore: sort_constructors_first
  const ConfirmPassword.dirty(Map<String, String> confirmPassword)
      : super.dirty(confirmPassword);

  @override
  PasswordValidationError? validator(Map<String, String> value) {

    if(value.isEmpty){

      return PasswordValidationError.addPasswordFirst_;

    }
    else if(value.containsKey('password')&&
        !value.containsKey('confirmPassword')){
      return PasswordValidationError.passwordNotMatched;

    }
    else if(value.containsKey('password')&&
        value.containsKey('confirmPassword') &&
        value['password']!=value['confirmPassword']){
      return PasswordValidationError.passwordNotMatched;

    }
    else{
      return null;
    }

  }






// @override
// PasswordValidationError validator(String value) {
//   return value?.isNotEmpty == true && value.length>=6?
//   null : PasswordValidationError.empty;
// }



}
