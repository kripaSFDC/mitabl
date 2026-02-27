part of 'otp_cubit.dart';

class OtpState extends Equatable {
  const OtpState({
    this.otp,
    this.status = FormzStatus.pure,
    this.statusAPI = FormzStatus.pure,
    this.serverMessage = '',
  });

  final OTP? otp;
  final FormzStatus? status;
  final FormzStatus? statusAPI;
  final String? serverMessage;

  OtpState copyWith(
      {OTP? otp,
      FormzStatus? status,
      FormzStatus? statusAPI,
      String? serverMessage}) {
    return OtpState(
      otp: otp ?? this.otp,
      status: status ?? this.status,
      serverMessage: serverMessage ?? this.serverMessage,
      statusAPI: statusAPI ?? this.statusAPI,
    );
  }

  @override
  List<Object?> get props => [otp, statusAPI, status, serverMessage];
}
