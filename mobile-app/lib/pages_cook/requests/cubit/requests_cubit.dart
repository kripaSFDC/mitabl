import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/model/requests.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';

import '../../../model/bookings.dart';
import '../../../repos/authentication_repository.dart';

part 'requests_state.dart';

class RequestsCubit extends Cubit<RequestsState> {
  RequestsCubit(this.bookingRepository) : super(RequestsState()) {
    // getRequests();
  }

  final BookingRepository? bookingRepository;

  getRequests() async {
    try {
      emit(state.copyWith(
          requestBookingStatus: FormzStatus.submissionInProgress));
      var response = await bookingRepository!
          .getRequests(page: state.page! + 1, limit: 100);
      if (response.statusCode == 200) {
        Booking booking = Booking.fromJson(jsonDecode(response.body));
        emit(state.copyWith(
            requestBookingModel: booking,
            requestBookingStatus: FormzStatus.submissionSuccess));
      } else {
        emit(state.copyWith(
            requestBookingStatus: FormzStatus.submissionSuccess));
      }
    } on Exception catch (e) {
      emit(state.copyWith(requestBookingStatus: FormzStatus.submissionFailure));
    }
  }

  onOrderAcceptDecline({
    bool? isAccept,
    dynamic? orderId,
    bool? isFromOrderView,
  }) async {
    Map<String, dynamic>? map = {};

    map['order_id'] = orderId.toString();
    map['status'] = isAccept! ? '3' : '0';

    var response = await bookingRepository!.updateOrderStatus(data: map);
    if (response.statusCode == 200) {
      navigatorKey.currentState!.pop();
      // if (isAccept) {
      //   navigatorKey.currentState!.pushNamed('/UpcomingBookings');
      // } else {
      //   navigatorKey.currentState!.pushNamed('/Bookings');
      // }

      if (isFromOrderView!) {
        navigatorKey.currentState!.pop();
      }
      getRequests();
    }
  }
}
