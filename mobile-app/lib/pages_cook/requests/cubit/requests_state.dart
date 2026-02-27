part of 'requests_cubit.dart';

class RequestsState extends Equatable {
  const RequestsState(
      {this.page = 0,
      this.requestBookingModel,
      this.requestBookingStatus = FormzStatus.pure});

  final FormzStatus? requestBookingStatus;
  final Booking? requestBookingModel;
  final int? page;

  RequestsState copyWith(
      {int? page,
      FormzStatus? requestBookingStatus,
      Booking? requestBookingModel}) {
    return RequestsState(
        page: page ?? this.page,
        requestBookingModel: requestBookingModel ?? this.requestBookingModel,
        requestBookingStatus:
            requestBookingStatus ?? this.requestBookingStatus);
  }

  @override
  List<Object?> get props => [requestBookingStatus, requestBookingModel, page];
}
