import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitabl_user/model/password.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:http/http.dart';
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
        print(response.body);
        UserModel userModel = UserModel.fromJson(jsonDecode(response.body));
        userRepository.setCurrentUser(response.body).then((value) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // if (state.rememberMe) {
          //   print('remberMe_LOGIN ${state.rememberMe}');
          //   prefs.setBool(AppConstants.USER_REMEMBER_ME, true);
          //   await prefs.setString(AppConstants.USER_EMAIL, state.email.value);
          //   await prefs.setString(
          //       AppConstants.USER_PASSWORD, state.password.value);
          // } else {
          //   prefs.setBool(AppConstants.USER_REMEMBER_ME, false);
          // }

          emit(state.copyWith(
              apiStatus: FormzStatus.submissionSuccess,
              serverMessage: 'Login Successfully...'));

          _authenticationRepository.controller
              .add(AuthenticationStatus.authenticated);
        });
      } else {
        String message = jsonDecode(response.body)['isError'];
        // if (response.statusCode == 404) {
        //   message = 'Please check your email and password';
        // }
        emit(state.copyWith(
            apiStatus: FormzStatus.submissionFailure,
            serverMessage: '${message}'));
        emit(state.copyWith(
            apiStatus: FormzStatus.pure, serverMessage: '${message}'));
      }
    } catch (e) {
      print('exceptionLogin $e');
      emit(state.copyWith(
          apiStatus: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...'));
    }
  }
}
