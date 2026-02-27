import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/otp_response.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/helper.dart';
import '../../../model/otp.dart';

part 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit(
      this.authenticationRepository, this.userRepository, this.routeArguments)
      : super(OtpState());

  final AuthenticationRepository? authenticationRepository;
  final UserRepository? userRepository;
  final RouteArguments? routeArguments;

  onOtpChanged({String? value}) {
    var values = OTP.dirty(value!);
    emit(state.copyWith(otp: values, status: Formz.validate([values])));
  }

  onSubmitted() async {
    try {
      emit(state.copyWith(statusAPI: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['id'] = routeArguments!.id;
      map['otp'] = state.otp!.value.toString();

      var response = await authenticationRepository!.otpVerify(data: map);
      if (response.statusCode == 200) {
        OTPResponse otpResponse =
            OTPResponse.fromJson(jsonDecode(response.body));
        UserModel userModel = UserModel.fromJson(jsonDecode(response.body));
        await userRepository!.setCurrentUser(response.body).then((value) async {
          emit(state.copyWith(statusAPI: FormzStatus.submissionSuccess));
          if (routeArguments!.role == AppConstants.FOODI) {
            authenticationRepository!.controller
                .add(AuthenticationStatus.authenticated);
          } else {
            navigatorKey.currentState!.popAndPushNamed('/CookProfile',
                arguments: RouteArguments(data: otpResponse.data));
          }
        });
      } else {
        String message = jsonDecode(response.body)['isError'];
        emit(state.copyWith(
            statusAPI: FormzStatus.submissionFailure, serverMessage: message));
        emit(state.copyWith(statusAPI: FormzStatus.pure, serverMessage: ''));
      }
    } on Exception catch (e) {
      emit(state.copyWith(
          statusAPI: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...'));
      emit(state.copyWith(
        statusAPI: FormzStatus.pure,
      ));
    }
  }
}
