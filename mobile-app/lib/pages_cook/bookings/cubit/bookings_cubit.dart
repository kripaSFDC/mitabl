import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';

import '../../../repos/authentication_repository.dart';

part 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit(this.bookingRepository) : super(const BookingsState());

  final BookingRepository? bookingRepository;

  Future<void> updateOrderWorkflowStatus({
    required dynamic orderId,
    required String status,
    String? cancelComment,
  }) async {
    try {
      emit(state.copyWith(
          orderCompleteCancelStatus: FormzStatus.submissionInProgress));

      final map = <String, dynamic>{
        'order_id': orderId.toString(),
        'status': status,
      };
      if ((cancelComment ?? '').trim().isNotEmpty) {
        map['cancel_comment'] = cancelComment!.trim();
      }

      final response = await bookingRepository!.updateOrderStatus(data: map);
      if (response.statusCode == 200) {
        navigatorKey.currentState!.pop();
        emit(state.copyWith(
            orderCompleteCancelStatus: FormzStatus.submissionSuccess));
        getUpcomingBookings();
      } else {
        emit(state.copyWith(
            orderCompleteCancelStatus: FormzStatus.submissionFailure));
      }
    } on Exception {
      emit(state.copyWith(
          orderCompleteCancelStatus: FormzStatus.submissionFailure));
    }
  }

  onOrderCompleteDecline({bool? isCompleted, dynamic orderId}) async {
    return updateOrderWorkflowStatus(
      orderId: orderId,
      status: isCompleted! ? '1' : '4',
      cancelComment: isCompleted ? null : 'Cancelled by miCook',
    );
  }

  getBookings() async {
    try {
      emit(state.copyWith(bookingStatus: FormzStatus.submissionInProgress));
      var response = await bookingRepository!.getBookings(
          limit: 20,
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
    } on Exception {
      emit(state.copyWith(bookingStatus: FormzStatus.submissionFailure));
    }
  }

  getUpcomingBookings() async {
    try {
      emit(state.copyWith(
          upcomingBookingStatus: FormzStatus.submissionInProgress));
      var response = await bookingRepository!.getBookings(
        limit: 20,
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
    } on Exception {
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

  @override
  Future<void> close() {
    bookingRepository?.dispose();
    return super.close();
  }
}
