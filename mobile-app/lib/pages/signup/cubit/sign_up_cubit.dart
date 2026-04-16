import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/confirmpassword.dart';
import 'package:mitabl_user/model/email.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/password.dart';
import 'package:mitabl_user/model/international_phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/helper.dart';
import '../../../model/signup_response.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this.authenticationRepository) : super(const SignUpState());

  final AuthenticationRepository? authenticationRepository;

  onSignUp() async {
    try {
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['first_name'] = state.nameFirst!.value;
      map['last_name'] = state.nameLast!.value;
      map['email'] = state.email!.value;
      map['password'] = state.confirmPassword.value['password'];
      map['password_confirmation'] =
          state.confirmPassword.value['confirmPassword'];
      map['role_id'] = state.selectedRole;
      map['phone'] = state.phone.value;
      map['address'] = state.address!.value;

      var response = await authenticationRepository!.signUp(data: map);
      if (response.statusCode == 200) {
        SignUpResponse signUpResponse = SignUpResponse.fromJson(
          jsonDecode(response.body),
        );

        emit(state.copyWith(statusApi: FormzStatus.submissionSuccess));

        navigatorKey.currentState!.popAndPushNamed(
          '/OTPPage',
          arguments: RouteArguments(
            id: signUpResponse.data!.id.toString(),
            role: state.selectedRole,
          ),
        );
      } else {
        String message = ApiErrorParser.parseMessage(response.body);
        String phoneError = '';
        if (response.statusCode == 422) {
          final lc = message.toLowerCase();
          if (lc.contains('phone')) {
            phoneError = message;
          }
        }
        emit(
          state.copyWith(
            statusApi: FormzStatus.submissionFailure,
            serverMessage: message,
            phoneServerError: phoneError,
          ),
        );
        emit(
          state.copyWith(
            statusApi: FormzStatus.pure,
            serverMessage: message,
            phoneServerError: phoneError,
          ),
        );
      }
    } on Exception {
      emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  onFirstNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        nameFirst: name,
        status: Formz.validate([
          name,
          state.phone,
          state.email!,
          state.nameLast!,
          state.password,
          state.confirmPassword,
          state.address!,
        ]),
      ),
    );
  }

  onRoleChanged({int? role}) {
    emit(state.copyWith(selectedRole: role));
  }

  onLastNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        nameLast: name,
        status: Formz.validate([
          name,
          state.phone,
          state.email!,
          state.nameFirst!,
          state.password,
          state.confirmPassword,
          state.address!,
        ]),
      ),
    );
  }

  onEmailChanged({String? value}) {
    var email = Email.dirty(value!);
    emit(
      state.copyWith(
        email: email,
        status: Formz.validate([
          state.nameFirst!,
          state.phone,
          email,
          state.nameLast!,
          state.password,
          state.confirmPassword,
          state.address!,
        ]),
      ),
    );
  }

  onPhoneChanged({String? value}) {
    var phone = InternationalPhone.dirty(value!);
    emit(
      state.copyWith(
        phone: phone,
        phoneServerError: '',
        status: Formz.validate([
          state.nameFirst!,
          phone,
          state.email!,
          state.nameLast!,
          state.password,
          state.confirmPassword,
          state.address!,
        ]),
      ),
    );
  }

  void onCountryCodeChanged({
    required String value,
    required String localNumber,
  }) {
    final normalizedCountryCode = value.trim().isEmpty ? '+61' : value.trim();
    emit(state.copyWith(countryCode: normalizedCountryCode));
    onPhoneChanged(
      value: InternationalPhone.compose(
        countryCode: normalizedCountryCode,
        number: localNumber,
      ),
    );
  }

  onAddressChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        address: name,
        status: Formz.validate([
          name,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!,
          state.password,
          state.confirmPassword,
        ]),
      ),
    );
  }

  onPasswordChanged({String? value}) {
    var name = Password.dirty(value!);
    emit(
      state.copyWith(
        password: name,
        status: Formz.validate([
          name,
          state.confirmPassword,
          state.address!,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!,
        ]),
      ),
    );
  }

  onConfirmPasswordChanged(String? confirmPasswordValue) {
    Map<String, String> map = {};
    map['password'] = state.password.value!;
    map['confirmPassword'] = confirmPasswordValue ?? '';

    final confirmPassword = ConfirmPassword.dirty(map);
    emit(
      state.copyWith(
        status: Formz.validate([
          confirmPassword,
          state.password,
          state.address!,
          state.nameFirst!,
          state.phone,
          state.email!,
          state.nameLast!,
        ]),
        confirmPassword: confirmPassword,
      ),
    );
  }

  void showPassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void showConfirmPassword() {
    emit(state.copyWith(showConfirmPassword: !state.showConfirmPassword));
  }
}
