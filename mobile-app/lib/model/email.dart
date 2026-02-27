import 'package:formz/formz.dart';

enum EmailValidationError{empty}

class Email extends FormzInput<String ,EmailValidationError>{
  const Email.dirty([String value='']) : super.dirty(value);
  const Email.pure():super.pure('');

  @override
  EmailValidationError? validator(String value) {
    return value.isNotEmpty == true&&
        RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)
        ? null : EmailValidationError.empty;
  }

}