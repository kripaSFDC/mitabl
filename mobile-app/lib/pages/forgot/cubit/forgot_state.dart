part of 'forgot_cubit.dart';

class ForgotState extends Equatable {
  const ForgotState(
      {this.email = const Email.pure(),
      this.status = FormzStatus.pure,
      this.serverMessage = ''});

  final Email? email;
  final FormzStatus? status;
  final String? serverMessage;

  ForgotState copyWith(
      {FormzStatus? status, Email? email, String? serverMessage}) {
    return ForgotState(
        status: status ?? this.status,
        email: email ?? this.email,
        serverMessage: serverMessage ?? this.serverMessage);
  }

  @override
  List<Object?> get props => [status, email, serverMessage];
}
