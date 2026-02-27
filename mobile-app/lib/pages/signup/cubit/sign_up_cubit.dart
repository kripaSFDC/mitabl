import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/confirmpassword.dart';
import 'package:mitabl_user/model/email.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/password.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/helper.dart';
import '../../../model/signup_response.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this.authenticationRepository) : super(SignUpState());

  final AuthenticationRepository? authenticationRepository;

  onSignUp() async {
    try {
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['first_name'] = state.nameFirst!.value;
      map['last_name'] = state.nameLast!.value;
      map['email'] = state.email!.value;
      map['password'] = state.confirmPassword.value['password'];
      map['role_id'] = state.selectedRole;
      map['phone'] = state.phone.value;
      map['address'] = state.address!.value;

      print('mapppss ${map.toString()}');

      var response = await authenticationRepository!.signUp(data: map);
      if (response.statusCode == 200) {
        SignUpResponse signUpResponse =
            SignUpResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(statusApi: FormzStatus.submissionSuccess));

        navigatorKey.currentState!.popAndPushNamed('/OTPPage',
            arguments: RouteArguments(
                id: signUpResponse.data!.id.toString(),
                role: state.selectedRole));
      } else {
        String message = jsonDecode(response.body)['isError'];
        emit(state.copyWith(
            statusApi: FormzStatus.submissionFailure, serverMessage: message));
        emit(state.copyWith(
            statusApi: FormzStatus.pure, serverMessage: '${message}'));
      }
    } on Exception catch (e) {
      emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  onFirstNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        nameFirst: name,
        status: Formz.validate([
          name,
          state.phone,
          state.email!,
          state.nameLast!,
          state.password,
          state.confirmPassword,
          state.address!
        ])));
  }

  onRoleChanged({int? role}) {
    emit(state.copyWith(selectedRole: role));
  }

  onLastNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        nameLast: name,
        status: Formz.validate([
          name,
          state.phone,
          state.email!,
          state.nameFirst!,
          state.password,
          state.confirmPassword,
          state.address!
        ])));
  }

  onEmailChanged({String? value}) {
    var email = Email.dirty(value!);
    emit(state.copyWith(
        email: email,
        status: Formz.validate([
          state.nameFirst!,
          state.phone,
          email,
          state.nameFirst!,
          state.password,
          state.confirmPassword,
          state.address!
        ])));
  }

  onPhoneChanged({String? value}) {
    var phone = Phone.dirty(value!);
    emit(state.copyWith(
        phone: phone,
        status: Formz.validate([
          state.nameFirst!,
          phone,
          state.email!,
          state.nameFirst!,
          state.password,
          state.confirmPassword,
          state.address!
        ])));
  }

  onAddressChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        address: name,
        status: Formz.validate([
          name,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!,
          state.password,
          state.confirmPassword
        ])));
  }

  onPasswordChanged({String? value}) {
    var name = Password.dirty(value!);
    emit(state.copyWith(
        password: name,
        status: Formz.validate([
          name,
          state.confirmPassword,
          state.address!,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!
        ])));
  }

  onConfirmPasswordChanged(String? confirmPasswordValue) {
    Map<String, String> map = Map();
    map['password'] = state.password.value!;
    map['confirmPassword'] = confirmPasswordValue ?? '';

    final confirmPassword = ConfirmPassword.dirty(map);
    emit(state.copyWith(
        status: Formz.validate([
          confirmPassword,
          state.password,
          state.address!,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!
        ]),
        confirmPassword: confirmPassword));
  }

  void showPassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void showConfirmPassword() {
    emit(state.copyWith(showConfirmPassword: !state.showConfirmPassword));
  }
}
