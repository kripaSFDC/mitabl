import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/model/email.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import 'package:http/http.dart';

part 'forgot_state.dart';

class ForgotCubit extends Cubit<ForgotState> {
  ForgotCubit(this.authenticationRepository) : super(ForgotState());

  final AuthenticationRepository? authenticationRepository;

  onEmailChanged({String? value}) {
    var email = Email.dirty(value!);
    emit(state.copyWith(email: email, status: Formz.validate([email])));
  }

  void forgot() async {
    try {
      emit(state.copyWith(status: FormzStatus.submissionInProgress));
      var map = Map<String, dynamic>();
      map['email'] = state.email!.value;

      Response response = await authenticationRepository!.forgot(data: map);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print(res);
        if (res['isSuccess']) {
          emit(state.copyWith(
              status: FormzStatus.submissionSuccess,
              serverMessage: '${res['message']}'));
        } else {
          emit(state.copyWith(
              status: FormzStatus.submissionFailure,
              serverMessage: '${res['isError']}'));
        }
      } else {
        String message = jsonDecode(response.body)['message'];

        emit(state.copyWith(
            status: FormzStatus.submissionFailure,
            serverMessage: '${message}'));

        emit(state.copyWith(
            status: FormzStatus.pure, serverMessage: '${message}'));
      }
    } catch (e) {
      print('exceptionLogin $e');
      emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...'));
    }
  }
}
