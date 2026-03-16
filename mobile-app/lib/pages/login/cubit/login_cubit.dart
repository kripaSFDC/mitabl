import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/connectivity_service.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/model/password.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:http/http.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../model/email.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required AuthenticationRepository authRepository,
    required UserRepository repo,
  }) : _authenticationRepository = authRepository,
       userRepository = repo,
       super(const LoginState());

  final AuthenticationRepository _authenticationRepository;
  final UserRepository userRepository;

  void showPassword() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  void onEmailChanged({String? value}) {
    emit(
      state.copyWith(
        email: Email.dirty(value.toString()),
        status: Formz.validate([Email.dirty(value.toString()), state.password]),
      ),
    );
  }

  void onPasswordChanged({String? value}) {
    emit(
      state.copyWith(
        password: Password.dirty(value.toString()),
        status: Formz.validate([Password.dirty(value.toString()), state.email]),
      ),
    );
  }

  void doLogin() async {
    try {
      emit(state.copyWith(apiStatus: FormzStatus.submissionInProgress));

      final payload = _buildLoginPayload();
      if (payload == null) {
        emit(
          state.copyWith(
            apiStatus: FormzStatus.submissionFailure,
            serverMessage: 'Please enter a valid email and password.',
          ),
        );
        emit(state.copyWith(apiStatus: FormzStatus.pure));
        return;
      }

      Response response = await _authenticationRepository.logIn(data: payload);

      if (response.statusCode == 200) {
        await userRepository.setCurrentUser(response.body);

        emit(
          state.copyWith(
            apiStatus: FormzStatus.submissionSuccess,
            serverMessage: 'Login Successfully...',
          ),
        );

        _authenticationRepository.notifyAuthenticated();
      } else {
        final message = ApiErrorParser.parseMessage(
          response.body,
          fallbackMessage: 'Request failed. Please try again.',
        );
        emit(
          state.copyWith(
            apiStatus: FormzStatus.submissionFailure,
            serverMessage: message,
          ),
        );
        emit(
          state.copyWith(apiStatus: FormzStatus.pure, serverMessage: message),
        );
      }
    } on OfflineException {
      emit(
        state.copyWith(
          apiStatus: FormzStatus.submissionFailure,
          serverMessage: 'No internet connection. Please try again.',
        ),
      );
    } catch (e) {
      AppLogger.error('Login failed', e);
      emit(
        state.copyWith(
          apiStatus: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...',
        ),
      );
    }
  }

  Map<String, dynamic>? _buildLoginPayload() {
    final normalizedEmail = state.email.value.trim().toLowerCase();
    final normalizedPassword = (state.password.value ?? '').trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'username': normalizedEmail,
      'password': normalizedPassword,
    };

    final normalizedDeviceToken = state.deviceToken.trim();
    if (normalizedDeviceToken.isNotEmpty) {
      payload['device_token'] = normalizedDeviceToken;
      // Backward-compatible alias for older backend handlers.
      payload['device_key'] = normalizedDeviceToken;
    }

    return payload;
  }

}
