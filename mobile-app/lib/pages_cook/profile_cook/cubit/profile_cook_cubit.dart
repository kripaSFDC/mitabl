import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/email.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/model/timing_model.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import '../../../model/kitchen_profile.dart';
import '../../../model/name.dart';

part 'profile_cook_state.dart';

class ProfileCookCubit extends Cubit<ProfileCookState> {
  ProfileCookCubit({this.userRepository}) : super(const ProfileCookState());

  final UserRepository? userRepository;

  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
  }

  onTabChanged({int? index}) {
    emit(state.copyWith(tabIndex: index));
  }

  getCookProfile() async {
    try {
      var response = await userRepository!.getCookProfile();
      if (response.statusCode != 200) {
        Helper.showToast('Unable to load profile data.');
        return;
      }

      GetCookProfileModel cookProfile = GetCookProfileModel.fromJson(
        jsonDecode(response.body),
      );

      await userRepository!.syncAvailableRolesFromProfile(cookProfile.data);

      final timingsJson = cookProfile.data?.kitchen?.timings;
      Map<String, dynamic> valueDays = <String, dynamic>{'days': []};
      if (timingsJson != null && timingsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(timingsJson);
          if (decoded is Map<String, dynamic>) {
            valueDays = decoded;
          }
        } catch (_) {}
      }
      TimingModel timingModel = TimingModel.fromJson(valueDays);

      final firstName = Name.dirty(cookProfile.data?.firstName ?? '');
      final lastName = Name.dirty(cookProfile.data?.lastName ?? '');
      final description = Name.dirty(cookProfile.data?.description ?? '');
      final phone = Phone.dirty(cookProfile.data?.phone?.toString() ?? '');
      final email = Email.dirty(cookProfile.data?.email?.toString() ?? '');

      emit(
        state.copyWith(
          daysTiming: timingModel.days ?? const [],
          daysTimingOriginal: timingModel.days ?? const [],
          firstName: firstName,
          lastName: lastName,
          description: description,
          phoneNo: phone,
          email: email,
          status: Formz.validate([
            firstName,
            lastName,
            description,
            phone,
            email,
          ]),
          cookProfile: cookProfile,
          pathFiles: cookProfile.data?.kitchen?.images ?? const [],
        ),
      );
    } catch (_) {
      Helper.showToast('Unable to load profile data.');
    }
  }

  onFirstNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        firstName: name,
        status: Formz.validate([
          name,
          state.phoneNo!,
          state.email!,
          state.lastName!,
          state.description!,
        ]),
      ),
    );
  }

  onLastNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        lastName: name,
        status: Formz.validate([
          name,
          state.phoneNo!,
          state.email!,
          state.firstName!,
          state.description!,
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
          state.firstName!,
          state.phoneNo!,
          email,
          state.lastName!,
          state.description!,
        ]),
      ),
    );
  }

  onPhoneChanged({String? value}) {
    var phone = Phone.dirty(value!);
    emit(
      state.copyWith(
        phoneNo: phone,
        status: Formz.validate([
          state.firstName!,
          phone,
          state.email!,
          state.lastName!,
          state.description!,
        ]),
      ),
    );
  }

  onDescriptionChanged({String? value}) {
    var description = Name.dirty(value!);
    emit(
      state.copyWith(
        description: description,
        status: Formz.validate([
          state.firstName!,
          description,
          state.email!,
          state.lastName!,
          state.phoneNo!,
        ]),
      ),
    );
  }

  onAvatarImageSelect({String? path}) {
    emit(state.copyWith(avatarPath: path));
  }

  void resetSubmissionStatus() {
    emit(state.copyWith(statusUpload: FormzStatus.pure));
  }

  updateCookProfile() async {
    try {
      emit(state.copyWith(statusUpload: FormzStatus.submissionInProgress));
      Map<String, String> map = {};
      map['first_name'] = state.firstName!.value;
      map['last_name'] = state.lastName!.value;
      map['email'] = state.email!.value;
      map['phone'] = state.phoneNo!.value;
      map['description'] = state.description!.value;

      var response = await userRepository!.updateCookProfile(
        data: map,
        filePath: state.avatarPath ?? '',
      );

      if (response.statusCode == 200) {
        getCookProfile();
        emit(
          state.copyWith(
            avatarPath: '',
            statusUpload: FormzStatus.submissionSuccess,
          ),
        );
        Helper.showToast('Profile updated successfully.');
      } else {
        getCookProfile();
        emit(
          state.copyWith(
            avatarPath: '',
            statusUpload: FormzStatus.submissionFailure,
          ),
        );
      }
    } on Exception {
      getCookProfile();
      emit(
        state.copyWith(
          avatarPath: '',
          statusUpload: FormzStatus.submissionFailure,
        ),
      );
    }
  }
}
