import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/helper.dart';

import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/international_phone.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../../model/timing_model.dart';

part 'cook_profile_state.dart';

class CookProfileCubit extends Cubit<CookProfileState> {
  CookProfileCubit(this.authenticationRepository, this.routeArguments)
    : super(const CookProfileState(days: AppConstants.DAYS)) {
    setUpTimingModel();
  }

  onOpenTimingDialog() {
    emit(state.copyWith(daysTiming: state.daysTimingOriginal));
  }

  onApplyDays({List<Days>? daysTiming}) {
    navigatorKey.currentState!.pop();
    emit(state.copyWith(daysTimingOriginal: state.daysTiming));
  }

  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
  }

  setUpTimingModel() {
    List<Days> daysTiming = [];
    for (var element in AppConstants.DAYS) {
      daysTiming.add(
        Days(
          day: element.toString(),
          isOn: false,
          timing: Timing(endTime: '23:59', startTime: '00:00'),
        ),
      );
    }

    emit(
      state.copyWith(daysTiming: daysTiming, daysTimingOriginal: daysTiming),
    );
  }

  onSwitchChanged({
    int? index,
    bool? switchValue,
    String? startTime,
    String? endTime,
  }) {
    List<Days> daysTiming = [];
    daysTiming.addAll(state.daysTiming);
    Days? days;
    Timing? timing;
    if (switchValue != null) {
      days = daysTiming[index!].copyWith(isOn: switchValue);
      daysTiming.removeAt(index);
      daysTiming.insert(index, days);
      emit(state.copyWith(daysTiming: daysTiming));
    } else if (startTime != null) {
      timing = daysTiming[index!].timing;

      days = daysTiming[index].copyWith(
        timing: timing!.copyWith(startTime: startTime),
      );
      daysTiming.removeAt(index);
      daysTiming.insert(index, days);
      emit(state.copyWith(daysTiming: daysTiming));
    } else if (endTime != null) {
      timing = daysTiming[index!].timing;

      days = daysTiming[index].copyWith(
        timing: timing!.copyWith(endTime: endTime),
      );
      daysTiming.removeAt(index);
      daysTiming.insert(index, days);
      emit(state.copyWith(daysTiming: daysTiming));
    }
  }

  final RouteArguments? routeArguments;
  AuthenticationRepository? authenticationRepository;

  onNewImageAdded({String? path}) {
    List<String> allPaths = [];
    if (state.pathFiles.isNotEmpty) {
      allPaths.addAll(state.pathFiles);
      allPaths.add(path!);
    } else {
      allPaths.add(path!);
    }

    emit(state.copyWith(pathFiles: allPaths));
  }

  onDeleteImage({String? path}) {
    List<String> allPaths = [];
    if (state.pathFiles.isNotEmpty) {
      allPaths.addAll(state.pathFiles);
      allPaths.removeWhere((element) => element.toString() == path.toString());
    } else {
      allPaths.removeWhere((element) => element.toString() == path.toString());
    }

    emit(state.copyWith(pathFiles: allPaths));
  }

  onKitchnUpload() async {
    try {
      if (state.pathFiles.isEmpty) {
        Helper.showToast('Please add at least one kitchen image.');
        emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
        return;
      }

      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['name'] = state.nameKitchn!.value;
      map['address'] = state.address!.value;
      map['no_of_seats'] = state.noOfSeats.value;
      map['phone'] = state.phone.value;
      map['description'] = state.bio.value.trim();
      map['user_id'] = routeArguments!.data!.user!.id;
      map['timings'] = jsonEncode(TimingModel(days: state.daysTiming));
      map['dine_in'] = state.dineIn ? 1 : 0;
      map['take_away'] = state.takeAway ? 1 : 0;
      if (state.dineIn) {
        map['dine_in_slots'] = jsonEncode(
          state.dineInSlots
              .map((slot) => slot.toJson())
              .toList(growable: false),
        );
      }

      var response = await authenticationRepository!.vendorKitchnUpload(
        data: map,
        routeArguments: routeArguments,
        filePaths: state.pathFiles,
      );
      if (response.statusCode == 200) {
        emit(state.copyWith(statusApi: FormzStatus.submissionSuccess));
        authenticationRepository!.notifyAuthenticated();
        // navigatorKey.currentState!.pushNamedAndRemoveUntil(
        //   '/DashboardCook',
        //   (route) => false,
        // );
      } else {
        emit(
          state.copyWith(
            statusApi: FormzStatus.submissionFailure,
            serverMessage: ApiErrorParser.parseMessage(
              response.body,
              statusCode: response.statusCode,
              fallbackMessage:
                  'Unable to save mikitchn right now. Please try again.',
            ),
          ),
        );
      }
    } on Exception {
      emit(
        state.copyWith(
          statusApi: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...',
        ),
      );
    }
  }

  onKitchnNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        nameKitchn: name,
        status: Formz.validate([
          name,
          state.bio,
          state.phone,
          state.noOfSeats,
          state.address!,
        ]),
      ),
    );
  }

  onAddressChanged({String? value}) {
    var address = Name.dirty(value!);
    emit(
      state.copyWith(
        address: address,
        status: Formz.validate([
          address,
          state.bio,
          state.nameKitchn!,
          state.phone,
          state.noOfSeats,
        ]),
      ),
    );
  }

  void onBioChanged({String? value}) {
    final bio = Name.dirty(value ?? '');
    emit(
      state.copyWith(
        bio: bio,
        status: Formz.validate([
          state.nameKitchn!,
          bio,
          state.phone,
          state.noOfSeats,
          state.address!,
        ]),
      ),
    );
  }

  onPhoneChanged({String? value}) {
    var phone = InternationalPhone.dirty(value!);
    emit(
      state.copyWith(
        phone: phone,
        status: Formz.validate([
          state.nameKitchn!,
          state.bio,
          state.noOfSeats,
          phone,
          state.address!,
        ]),
      ),
    );
  }

  void onCountryCodeChanged({
    required String value,
    required String localNumber,
  }) {
    final normalizedCountryCode = value.trim().isEmpty ? '+61' : value.trim();
    emit(state.copyWith(countryCode: normalizedCountryCode));
    onPhoneChanged(
      value: InternationalPhone.compose(
        countryCode: normalizedCountryCode,
        number: localNumber,
      ),
    );
  }

  onSeatChanged({String? value}) {
    var seat = Phone.dirty(value!);
    emit(
      state.copyWith(
        noOfSeats: seat,
        status: Formz.validate([
          state.nameKitchn!,
          state.bio,
          state.phone,
          seat,
          state.address!,
        ]),
      ),
    );
  }

  void onDineInChange({bool? value}) {
    emit(state.copyWith(dineIn: value ?? false));
  }

  void onTakeAwayChange({bool? value}) {
    emit(state.copyWith(takeAway: value ?? false));
  }

  void addOrUpdateDineInSlot(DineInSlotTemplate slot, {int? index}) {
    final next = [...state.dineInSlots];
    if (index != null && index >= 0 && index < next.length) {
      next[index] = slot;
    } else {
      next.add(slot);
    }

    next.sort((left, right) {
      final dayCompare = (left.dayOfWeek ?? 0).compareTo(right.dayOfWeek ?? 0);
      if (dayCompare != 0) {
        return dayCompare;
      }

      return (left.startTime ?? '').compareTo(right.startTime ?? '');
    });

    emit(state.copyWith(dineInSlots: next));
  }

  void deleteDineInSlot(int index) {
    final next = [...state.dineInSlots];
    if (index < 0 || index >= next.length) {
      return;
    }

    next.removeAt(index);
    emit(state.copyWith(dineInSlots: next));
  }
}
