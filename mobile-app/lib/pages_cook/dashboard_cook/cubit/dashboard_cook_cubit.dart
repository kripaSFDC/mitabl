import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/connectivity_service.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/model/dashboard_data.dart' as dd;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../model/user_model.dart';

part 'dashboard_cook_state.dart';

class DashboardCookCubit extends Cubit<DashboardCookState> {
  DashboardCookCubit(
      {this.userRepository, required this.authenticationRepository})
      : super(DashboardCookState(
            dashboardData: dd.DashboardData(
                data: dd.Data(
                    nBookings: 0, nUpcomingBookings: 0, totalEarning: 0))));

  final AuthenticationRepository? authenticationRepository;
  final UserRepository? userRepository;

  onTabChange({int? index}) {
    emit(state.copyWith(selectedIndex: index));
  }

  getDashBoardData() async {
    try {
      final response = await userRepository!.getDashboardData();
      if (response.statusCode == 200) {
        dd.DashboardData dashboardData =
            dd.DashboardData.fromJson(jsonDecode(response.body));
        emit(state.copyWith(dashboardData: dashboardData));
      } else {
        AppLogger.warn(
          'Dashboard request failed with status ${response.statusCode}',
        );
        Helper.showToast('Unable to load dashboard data.');
      }
    } on OfflineException {
      Helper.showToast('No internet connection. Please try again.');
    } catch (e) {
      AppLogger.error('Dashboard request failed', e);
      Helper.showToast('Unable to load dashboard data.');
    }
  }

  void doLogout() async {
    try {
      // emit(state.copyWith(status: FormzStatus.submissionInProgress));
      UserModel? userModel = await userRepository!.getUser();
      var response =
          await authenticationRepository!.logOutApi(userModel: userModel);

      if (response.statusCode == 200) {
        // emit(state.copyWith(
        //     status: FormzStatus.submissionSuccess,
        //     serverMessage: jsonDecode(response.body)['message']));
        await authenticationRepository!.logOut();
        emit(state.copyWith(selectedIndex: 0));
      } else {
        await authenticationRepository!.logOut();
        emit(state.copyWith(
            // status: FormzStatus.pure,
            selectedIndex: 0));
      }
    } catch (e) {
      AppLogger.error('Cook logout failed', e);
      // emit(state.copyWith(
      //     status: FormzStatus.submissionFailure,
      //     serverMessage: 'Something went wrong...'));
    }
  }
}
