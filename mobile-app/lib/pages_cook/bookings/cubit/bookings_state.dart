part of 'bookings_cubit.dart';

class BookingsState extends Equatable {
  const BookingsState(
      {this.bookingModel,
      this.upcomingBookingModel,
      this.totalCount,
      this.page = 0,
      this.sortby = '',
      this.status = '',
      this.bookingStatus = FormzStatus.pure,
      this.orderCompleteCancelStatus = FormzStatus.pure,
      this.upcomingBookingStatus = FormzStatus.pure});

  final FormzStatus? bookingStatus;
  final FormzStatus? upcomingBookingStatus;
  final Booking? bookingModel;
  final Booking? upcomingBookingModel;

  final int? totalCount;
  final String? sortby;
  final String? status;
  final int? page;

  final FormzStatus? orderCompleteCancelStatus;

  BookingsState copyWith(
      {int? totalCount,
      FormzStatus? orderCompleteCancelStatus,
      int? page,
      String? sortby,
      String? status,
      FormzStatus? bookingStatus,
      Booking? bookingModel,
      FormzStatus? upcomingBookingStatus,
      Booking? upcomingBookingModel}) {
    return BookingsState(
        orderCompleteCancelStatus:
            orderCompleteCancelStatus ?? this.orderCompleteCancelStatus,
        totalCount: totalCount ?? this.totalCount,
        page: page ?? this.page,
        sortby: sortby ?? this.sortby,
        status: status ?? this.status,
        upcomingBookingStatus:
            upcomingBookingStatus ?? this.upcomingBookingStatus,
        upcomingBookingModel: upcomingBookingModel ?? this.upcomingBookingModel,
        bookingModel: bookingModel ?? this.bookingModel,
        bookingStatus: bookingStatus ?? this.bookingStatus);
  }

  @override
  List<Object?> get props => [
        orderCompleteCancelStatus,
        page,
        totalCount,
        sortby,
        status,
        upcomingBookingStatus,
        upcomingBookingModel,
        bookingStatus,
        bookingModel
      ];
}
