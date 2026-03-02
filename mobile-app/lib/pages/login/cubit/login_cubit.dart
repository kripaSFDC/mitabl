import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/model/password.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:http/http.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/helper.dart';
import '../../../model/email.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
      {required AuthenticationRepository authenticationRepository,
      required UserRepository userRepository})
      : assert(authenticationRepository != null),
        _authenticationRepository = authenticationRepository,
        userRepository = userRepository,
        super(const LoginState()) {}

  final AuthenticationRepository _authenticationRepository;
  final UserRepository userRepository;

  void showPassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void onEmailChanged({String? value}) {
    emit(state.copyWith(
        email: Email.dirty(value.toString()),
        status:
            Formz.validate([Email.dirty(value.toString()), state.password])));
  }

  void onPasswordChanged({String? value}) {
    emit(state.copyWith(
        password: Password.dirty(value.toString()),
        status:
            Formz.validate([Password.dirty(value.toString()), state.email])));
  }

  void doLogin() async {
    try {
      emit(state.copyWith(apiStatus: FormzStatus.submissionInProgress));
      var map = Map<String, dynamic>();
      map['email'] = state.email.value;
      map['password'] = state.password.value;
      // map['device_key'] = state.deviceToken;

      Response response = await _authenticationRepository.logIn(data: map);

      if (response.statusCode == 200) {
        await userRepository.setCurrentUser(response.body);

        emit(state.copyWith(
            apiStatus: FormzStatus.submissionSuccess,
            serverMessage: 'Login Successfully...'));

        _authenticationRepository.controller
            .add(AuthenticationStatus.authenticated);
      } else {
        final payload = jsonDecode(response.body);
        String message = 'Request failed. Please try again.';
        if (payload is Map<String, dynamic>) {
          message = (payload['isError'] ?? payload['message'] ?? message)
              .toString();
        }
        emit(state.copyWith(
            apiStatus: FormzStatus.submissionFailure,
            serverMessage: message));
        emit(state.copyWith(
            apiStatus: FormzStatus.pure, serverMessage: message));
      }
    } catch (e) {
      AppLogger.error('Login failed', e);
      emit(state.copyWith(
          apiStatus: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...'));
    }
  }
}
