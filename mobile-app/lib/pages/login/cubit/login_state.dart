part of 'login_cubit.dart';

class LoginState extends Equatable {
  const LoginState(
      {this.status = FormzStatus.pure,
      this.rememberMe = false,
      this.email = const Email.pure(),
      this.password = const Password.pure(),
      this.showPassword = true,
      this.isFromSharedPref = false,
      this.serverMessage = '',
      this.apiStatus = FormzStatus.pure,
      this.deviceToken = ''});

  final bool rememberMe;
  final FormzStatus status;
  final Email email;
  final Password password;
  final bool showPassword;
  final bool isFromSharedPref;
  final String serverMessage;
  final FormzStatus apiStatus;
  final String deviceToken;

  LoginState copyWith({
    bool? rememberMe,
    FormzStatus? status,
    Email? email,
    String? deviceToken,
    Password? password,
    bool? isFromSharedPref,
    String? serverMessage,
    FormzStatus? apiStatus,
    bool? showPassword,
  }) {
    return LoginState(
        isFromSharedPref: isFromSharedPref ?? this.isFromSharedPref,
        deviceToken: deviceToken ?? this.deviceToken,
        password: password ?? this.password,
        rememberMe: rememberMe ?? this.rememberMe,
        showPassword: showPassword ?? this.showPassword,
        status: status ?? this.status,
        email: email ?? this.email,
        serverMessage: serverMessage ?? this.serverMessage,
        apiStatus: apiStatus ?? this.apiStatus);
  }

  @override
  List<Object?> get props => [
        deviceToken,
        email,
        password,
        showPassword,
        status,
        isFromSharedPref,
        rememberMe,
        apiStatus,
        serverMessage
      ];
}
