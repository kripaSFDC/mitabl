import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/helper.dart';

import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../../model/timing_model.dart';

part 'cook_profile_state.dart';

class CookProfileCubit extends Cubit<CookProfileState> {
  CookProfileCubit(this.authenticationRepository, this.routeArguments)
      : super(const CookProfileState(days: AppConstants.DAYS)) {
    setUpTimingModel();
  }

  onOpenTimingDialog(){
    emit(state.copyWith(daysTiming: state.daysTimingOriginal));
  }

  onApplyDays({List<Days>? daysTiming}){
    navigatorKey.currentState!.pop();
    emit(state.copyWith(daysTimingOriginal: state.daysTiming));
  }


  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
  }

  setUpTimingModel() {
    TimingModel? timingModel;
    List<Days> daysTiming = [];
    AppConstants.DAYS.forEach((element) {
      daysTiming.add(Days(
          day: element.toString(),
          isOn: false,
          timing: Timing(endTime: '23:59', startTime: '00:00')));
    });

    emit(state.copyWith(daysTiming: daysTiming,daysTimingOriginal:daysTiming));
  }

  onSwitchChanged(
      {int? index, bool? switchValue, String? startTime, String? endTime}) {
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

      days = daysTiming[index]
          .copyWith(timing: timing!.copyWith(startTime: startTime));
      daysTiming.removeAt(index);
      daysTiming.insert(index, days);
      emit(state.copyWith(daysTiming: daysTiming));
    } else if (endTime != null) {
      timing = daysTiming[index!].timing;

      days = daysTiming[index]
          .copyWith(timing: timing!.copyWith(endTime: endTime));
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
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
      map['name'] = state.nameKitchn!.value;
      map['address'] = state.address!.value;
      map['no_of_seats'] = state.noOfSeats.value;
      map['phone'] = state.phone.value;
      map['user_id'] = routeArguments!.data!.user!.id;
      map['timings'] = jsonEncode(TimingModel(days: state.daysTiming));
      print('mapppss ${map.toString()}');

      var response = await authenticationRepository!.vendorKitchnUpload(
          data: map,
          routeArguments: routeArguments,
          filePaths: state.pathFiles);
      print('response cubit ${response.body}');
      if (response.statusCode == 200) {

        emit(state.copyWith(statusApi: FormzStatus.submissionSuccess));
        authenticationRepository!.controller
            .add(AuthenticationStatus.authenticated);
        // navigatorKey.currentState!.pushNamedAndRemoveUntil(
        //   '/DashboardCook',
        //   (route) => false,
        // );
      } else {
        // Helper.showToast(jsonDecode(response.body)['isError']);
        emit(state.copyWith(
            statusApi: FormzStatus.submissionFailure,
            serverMessage: jsonDecode(response.body)['isError']));
      }
    } on Exception catch (e) {
      emit(state.copyWith(
          statusApi: FormzStatus.submissionFailure,
          serverMessage: 'Something went wrong...'));
    }
  }

  onKitchnNameChanged({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        nameKitchn: name,
        status: Formz.validate(
            [name, state.phone, state.noOfSeats, state.address!])));
  }

  onAddressChanged({String? value}) {
    var address = Name.dirty(value!);
    emit(state.copyWith(
        address: address,
        status: Formz.validate(
            [address, state.nameKitchn!, state.phone, state.noOfSeats])));
  }

  onPhoneChanged({String? value}) {
    var phone = Phone.dirty(value!);
    emit(state.copyWith(
        phone: phone,
        status: Formz.validate(
            [state.nameKitchn!, state.noOfSeats, phone, state.address!])));
  }

  onSeatChanged({String? value}) {
    var seat = Phone.dirty(value!);
    emit(state.copyWith(
        noOfSeats: seat,
        status: Formz.validate(
            [state.nameKitchn!, state.phone, seat, state.address!])));
  }
}
