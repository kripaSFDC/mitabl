import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/model/timing_model.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/helper.dart';
import '../../../model/name.dart';
import '../../../repos/authentication_repository.dart';

part 'edit_kitchen_profile_state.dart';

class EditKitchenProfileCubit extends Cubit<EditKitchenProfileState> {
  EditKitchenProfileCubit({this.routeArguments, this.userRepository})
    : super(const EditKitchenProfileState()) {
    setUpTimingModel();
    loadDineInSlots();
  }

  onOpenTimingDialog() {
    List<Days> daysList = [];
    if (state.daysTimingOriginal!.isNotEmpty) {
      daysList.addAll(state.daysTimingOriginal!);
    }
    emit(state.copyWith(daysTiming: daysList));
  }

  onApplyDays({List<Days>? daysTiming}) {
    navigatorKey.currentState!.pop();
    emit(state.copyWith(daysTimingOriginal: state.daysTiming));
  }

  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
  }

  setUpTimingModel() {
    var valueDays = (jsonDecode(routeArguments!.kitchen!.timings!));
    TimingModel timingModel = TimingModel.fromJson(valueDays);

    // List<String>? value =
    //     (jsonDecode(routeArguments!.kitchen!.images!) as List<dynamic>)
    //         .cast<String>()
    //         .toList();

    emit(
      state.copyWith(
        daysTimingOriginal: timingModel.days,
        daysTiming: timingModel.days,
        pathFiles: routeArguments!.kitchen!.images,
        dineIn: routeArguments!.kitchen!.dineIn == 1 ? true : false,
        takeAway: routeArguments!.kitchen!.takeAway == 1 ? true : false,
        abn: routeArguments!.kitchen!.abn ?? '',
        certificateNo: routeArguments!.kitchen!.certificateNo ?? '',
        dineInSlots: routeArguments!.kitchen!.dineInSlots ?? const [],
      ),
    );
  }

  onDineInChange({bool? value}) {
    emit(state.copyWith(dineIn: value));
  }

  onTakeAwayChange({bool? value}) {
    emit(state.copyWith(takeAway: value));
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
  UserRepository? userRepository;

  onNewImageAdded({String? path}) {
    ImagesCook addImage = ImagesCook(path: path);
    List<ImagesCook> allPaths = [];
    if (state.pathFiles.isNotEmpty) {
      allPaths.addAll(state.pathFiles);
      allPaths.add(addImage);
    } else {
      allPaths.add(addImage);
    }

    emit(state.copyWith(pathFiles: allPaths));
  }

  onDeleteImage({String? path, ImagesCook? imagesCook}) async {
    if (imagesCook!.id == null) {
      List<ImagesCook> allPaths = [];
      if (state.pathFiles.isNotEmpty) {
        allPaths.addAll(state.pathFiles);
        allPaths.removeWhere(
          (element) => element.path.toString() == path.toString(),
        );
      } else {
        allPaths.removeWhere(
          (element) => element.path.toString() == path.toString(),
        );
      }

      emit(state.copyWith(pathFiles: allPaths));
    } else {
      var response = await userRepository!.deleteImage(
        id: imagesCook.id.toString(),
        type: 'mikitchns',
      );
      if (response.statusCode == 200) {
        List<ImagesCook> allPaths = [];
        if (state.pathFiles.isNotEmpty) {
          allPaths.addAll(state.pathFiles);
          allPaths.removeWhere(
            (element) => element.path.toString() == path.toString(),
          );
        } else {
          allPaths.removeWhere(
            (element) => element.path.toString() == path.toString(),
          );
        }

        emit(state.copyWith(pathFiles: allPaths));
      }
    }
  }

  onKitchenEditUpload() async {
    try {
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['name'] = state.nameKitchn!.value;
      map['address'] = state.address!.value;
      map['no_of_seats'] = state.noOfSeats.value;
      map['phone'] = state.phone.value;
      map['abn'] = state.abn.trim();
      map['certificate_no'] = state.certificateNo.trim();
      // map['user_id'] = routeArguments!.data!.user!.id;
      map['timings'] = jsonEncode(TimingModel(days: state.daysTimingOriginal));
      map['dine_in'] = state.dineIn == true ? 1 : 0;
      map['take_away'] = state.takeAway == true ? 1 : 0;
      map['description'] = state.bio!.value;
      if (state.dineIn == true) {
        map['dine_in_slots'] = jsonEncode(
          state.dineInSlots
              .map((slot) => slot.toJson())
              .toList(growable: false),
        );
      }

      var paths = state.pathFiles
          .where((element) => element.id == null)
          .toList();
      List<String> localPaths = [];
      for (var element in paths) {
        localPaths.add(element.path!);
      }
      var response = await userRepository!.vendorKitchenEditUpload(
        data: map,
        filePaths: localPaths,
      );
      if (response.statusCode == 200) {
        jsonDecode(response.body);

        emit(state.copyWith(statusApi: FormzStatus.submissionSuccess));
        Helper.showToast('Success');
        navigatorKey.currentState!.pop(true);
        // navigatorKey.currentState!.pushNamedAndRemoveUntil(
        //   '/DashboardCook',
        //       (route) => false,
        // );
      } else {
        Helper.showToast(jsonDecode(response.body)['isError']);
        emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      }
    } on Exception {
      emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  onKitchnNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        nameKitchn: name,
        status: Formz.validate([
          name,
          state.bio!,
          state.phone,
          state.noOfSeats,
          state.address!,
        ]),
      ),
    );
  }

  onBioChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        bio: name,
        status: Formz.validate([
          name,
          state.nameKitchn!,
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
          state.bio!,
          state.nameKitchn!,
          state.phone,
          state.noOfSeats,
        ]),
      ),
    );
  }

  onPhoneChanged({String? value}) {
    var phone = Phone.dirty(value!);
    emit(
      state.copyWith(
        phone: phone,
        status: Formz.validate([
          state.nameKitchn!,
          state.bio!,
          state.noOfSeats,
          phone,
          state.address!,
        ]),
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
          state.bio!,
          state.phone,
          seat,
          state.address!,
        ]),
      ),
    );
  }

  onAbnChanged({String? value}) {
    emit(state.copyWith(abn: value ?? ''));
  }

  onCertificateNoChanged({String? value}) {
    emit(state.copyWith(certificateNo: value ?? ''));
  }

  Future<void> loadDineInSlots() async {
    final repo = userRepository;
    if (repo == null) {
      return;
    }

    try {
      emit(state.copyWith(dineInSlotsStatus: FormzStatus.submissionInProgress));
      final response = await repo.fetchMyDineInSlots();
      if (response.statusCode != 200) {
        emit(state.copyWith(dineInSlotsStatus: FormzStatus.submissionFailure));
        return;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) {
        emit(state.copyWith(dineInSlotsStatus: FormzStatus.submissionFailure));
        return;
      }

      final slots = data
          .whereType<Map>()
          .map(
            (slot) =>
                DineInSlotTemplate.fromJson(Map<String, dynamic>.from(slot)),
          )
          .toList(growable: false);

      emit(
        state.copyWith(
          dineInSlots: slots,
          dineInSlotsStatus: FormzStatus.submissionSuccess,
        ),
      );
    } catch (_) {
      emit(state.copyWith(dineInSlotsStatus: FormzStatus.submissionFailure));
    }
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
