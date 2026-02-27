import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';

import '../../../repos/authentication_repository.dart';

part 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit(this.bookingRepository) : super(BookingsState());

  final BookingRepository? bookingRepository;

  onOrderCompleteDecline({bool? isCompleted, dynamic? orderId}) async {
    emit(state.copyWith(
        orderCompleteCancelStatus: FormzStatus.submissionInProgress));
    Map<String, dynamic>? map = {};

    map['order_id'] = orderId.toString();
    map['status'] = isCompleted! ? '1' : '0';

    var response = await bookingRepository!.updateOrderStatus(data: map);
    if (response.statusCode == 200) {
      navigatorKey.currentState!.pop();
      emit(state.copyWith(
          orderCompleteCancelStatus: FormzStatus.submissionSuccess));

      /* if (isCompleted) {
        navigatorKey.currentState!.popAndPushNamed('/UpcomingBookings');
      } else {
        navigatorKey.currentState!.popAndPushNamed('/UpcomingBookings');
      }*/
      getUpcomingBookings();
    }
  }

  getBookings() async {
    try {
      emit(state.copyWith(bookingStatus: FormzStatus.submissionInProgress));
      var response = await bookingRepository!.getBookings(
          limit: 100,
          page: state.page! + 1,
          isUpcoming: false,
          sortBy: state.sortby,
          status: state.status);
      if (response.statusCode == 200) {
        Booking booking = Booking.fromJson(jsonDecode(response.body));
        emit(state.copyWith(
            bookingModel: booking,
            bookingStatus: FormzStatus.submissionSuccess,
            totalCount: booking.data!.totalCount));
      } else {
        emit(state.copyWith(bookingStatus: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(state.copyWith(bookingStatus: FormzStatus.submissionFailure));
    }
  }

  getUpcomingBookings() async {
    try {
      emit(state.copyWith(
          upcomingBookingStatus: FormzStatus.submissionInProgress));
      var response = await bookingRepository!.getBookings(
        limit: 100,
        page: state.page! + 1,
        isUpcoming: true,
        sortBy: state.sortby,
      );
      if (response.statusCode == 200) {
        Booking booking = Booking.fromJson(jsonDecode(response.body));
        emit(state.copyWith(
            upcomingBookingModel: booking,
            upcomingBookingStatus: FormzStatus.submissionSuccess,
            totalCount: booking.data!.totalCount));
      } else {
        emit(state.copyWith(
            upcomingBookingStatus: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(
          state.copyWith(upcomingBookingStatus: FormzStatus.submissionFailure));
    }
  }

  onSortByChanged({String? data}) {
    emit(state.copyWith(sortby: data));
  }

  onStatusChanged({String? data}) {
    emit(state.copyWith(status: data));
  }
}
