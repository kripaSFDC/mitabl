import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/email.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart';

part 'profile_foodie_state.dart';

class ProfileFoodieCubit extends Cubit<ProfileFoodieState> {
  ProfileFoodieCubit({this.userRepository, this.authenticationRepository})
      : super(ProfileFoodieState());

  final UserRepository? userRepository;
  final AuthenticationRepository? authenticationRepository;

  getFoodieProfile() async {
    var response = await userRepository!.getFoodieProfile();
    if (response.statusCode == 200) {
      GetCookProfileModel foodieProfile =
          GetCookProfileModel.fromJson(jsonDecode(response.body));
      print('SunnyProfileRes ${foodieProfile.message}');

      emit(state.copyWith(
        firstName: Name.dirty(foodieProfile.data!.firstName!),
        lastName: Name.dirty(foodieProfile.data!.lastName!),
        description: Name.dirty(foodieProfile.data!.description ?? ''),
        phoneNo: Phone.dirty(foodieProfile.data!.phone!.toString()),
        email: Email.dirty(foodieProfile.data!.email!.toString()),
        foodieProfile: foodieProfile,
      ));
    }
  }

  onFirstNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        firstName: name,
        status: Formz.validate([
          name,
          state.phoneNo!,
          state.email!,
          state.lastName!,
          state.description!
        ])));
  }

  onLastNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        lastName: name,
        status: Formz.validate([
          name,
          state.phoneNo!,
          state.email!,
          state.firstName!,
          state.description!,
        ])));
  }

  onEmailChanged({String? value}) {
    var email = Email.dirty(value!);
    emit(state.copyWith(
        email: email,
        status: Formz.validate([
          state.firstName!,
          state.phoneNo!,
          email,
          state.lastName!,
          state.description!,
        ])));
  }

  onPhoneChanged({String? value}) {
    var phone = Phone.dirty(value!);
    emit(state.copyWith(
        phoneNo: phone,
        status: Formz.validate([
          state.firstName!,
          phone,
          state.email!,
          state.lastName!,
          state.description!,
        ])));
  }

  onDescriptionChanged({String? value}) {
    var description = Name.dirty(value!);
    emit(state.copyWith(
        description: description,
        status: Formz.validate([
          state.firstName!,
          description,
          state.email!,
          state.lastName!,
          state.phoneNo!,
        ])));
  }

  onAvatarImageSelect({String? path}) {
    emit(state.copyWith(avatarPath: path));
  }

  updateFoodieProfile() async {
    try {
      emit(state.copyWith(statusUpload: FormzStatus.submissionInProgress));
      Map<String, String> map = {};
      map['first_name'] = state.firstName!.value;
      map['last_name'] = state.lastName!.value;
      map['email'] = state.email!.value;
      map['phone'] = state.phoneNo!.value;
      map['description'] = state.description!.value;

      var response = await userRepository!
          .updateCookProfile(data: map, filePath: state.avatarPath ?? '');

      if (response.statusCode == 200) {
        getFoodieProfile();
        emit(state.copyWith(
            avatarPath: '', statusUpload: FormzStatus.submissionSuccess));
        Helper.showToast('User Profile Updated');
      } else {
        getFoodieProfile();
        emit(state.copyWith(
            avatarPath: '', statusUpload: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      getFoodieProfile();
      emit(state.copyWith(
          avatarPath: '', statusUpload: FormzStatus.submissionFailure));
    }
  }

  void doLogout() async {
    try {
      Response response = await authenticationRepository!
          .logOutApi(userModel: userRepository!.user);

      print('Respomse ${jsonDecode(response.body)}');

      if (response.statusCode == 200) {
        authenticationRepository!.logOut();
      } else {
        emit(state.copyWith(
          status: FormzStatus.pure,
        ));
        authenticationRepository!.logOut();
      }
    } catch (e) {
      print('exceptionLogin $e');
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
      ));
    }
  }
}
