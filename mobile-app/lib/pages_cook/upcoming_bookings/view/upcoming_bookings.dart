import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/booking_filter_dialog.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';
import '../../bookings/elements/order_details_booking.dart';

class UpcomingBookings extends StatefulWidget {
  const UpcomingBookings({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) => BookingsCubit(
                  BookingRepository(context.read<UserRepository>())),
              child: const UpcomingBookings(),
            ));
  }

  @override
  State<UpcomingBookings> createState() => _UpcomingBookingsState();
}

class _UpcomingBookingsState extends State<UpcomingBookings> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Upcoming Bookings',
          onFilterSelected: () {
            showDialog(
                context: context,
                builder: (c) {
                  return BlocProvider.value(
                    value: context.read<BookingsCubit>(),
                    child: const BookingFilterDialog(isUpComing: true),
                  );
                });
          },
        ),
        body: BlocConsumer<BookingsCubit, BookingsState>(
          listener: (context, state) {},
          builder: (context, state) {
            return state.upcomingBookingStatus!.isSubmissionInProgress
                ? const Center(child: CommonProgressWidget())
                : state.upcomingBookingModel == null ||
                        state.upcomingBookingModel!.data!.bookings!.isEmpty
                    ? const NoDataWidget()
                    : ListView.separated(
                        // shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.all(
                                config.AppConfig(context).appWidth(2)),
                            child: Container(
                              height: config.AppConfig(context).appHeight(13),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(config.AppConfig(context)
                                        .appWidth(1.6)),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0x1C000000)
                                            .withValues(alpha: 0.11),
                                        blurRadius: 1.3,
                                        offset: const Offset(-0.01, -0.01)),
                                    BoxShadow(
                                        color: const Color(0x1C000000)
                                            .withValues(alpha: 0.11),
                                        blurRadius: 0.5,
                                        offset: const Offset(0, 0.0)),
                                  ]),
                              child: Padding(
                                padding: EdgeInsets.all(
                                    config.AppConfig(context).appWidth(3)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          state.upcomingBookingModel!.data!
                                              .bookings![index].customer!.name
                                              .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(fontSize: 16),
                                        ),
                                        const Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Date: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          config.FontFamily()
                                                              .demi),
                                              children: <TextSpan>[
                                                TextSpan(
                                                    text: state
                                                        .upcomingBookingModel!
                                                        .data!
                                                        .bookings![index]
                                                        .date,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall)
                                              ]),
                                        ),
                                        const Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Time: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          config.FontFamily()
                                                              .demi),
                                              children: <TextSpan>[
                                                TextSpan(
                                                    text:
                                                        '${state.upcomingBookingModel!.data!.bookings![index].timeFrom} t0 ${state.upcomingBookingModel!.data!.bookings![index].timeTo}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall)
                                              ]),
                                        ),
                                        const Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Persons: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          config.FontFamily()
                                                              .demi),
                                              children: <TextSpan>[
                                                TextSpan(
                                                    text: state
                                                        .upcomingBookingModel!
                                                        .data!
                                                        .bookings![index]
                                                        .persons
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall)
                                              ]),
                                        )
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      config.AppConfig(context)
                                                          .appHeight(0.2),
                                                  horizontal:
                                                      config.AppConfig(context)
                                                          .appWidth(2.5)),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(
                                                        config.AppConfig(
                                                                context)
                                                            .appWidth(2.5))),
                                                border: Border.all(
                                                    color: const Color(
                                                        0xff707070)),
                                              ),
                                              child: Text(
                                                state
                                                            .upcomingBookingModel!
                                                            .data!
                                                            .bookings![index]
                                                            .dineIn ==
                                                        1
                                                    ? 'Dine-in'
                                                    : 'Take-away',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            navigatorKey.currentState!.push(
                                                MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        BlocProvider.value(
                                                          value: context.read<
                                                              BookingsCubit>(),
                                                          child:
                                                              OrderDetailsBookings(
                                                            routeArguments: RouteArguments(
                                                                bookings: state
                                                                        .upcomingBookingModel!
                                                                        .data!
                                                                        .bookings![
                                                                    index],
                                                                isUpcoming:
                                                                    true),
                                                          ),
                                                        )));
                                          },
                                          child: Text(
                                            'View Details',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return SizedBox(
                            height: config.AppConfig(context).appHeight(1),
                          );
                        },
                        itemCount:
                            state.upcomingBookingModel!.data!.bookings!.length);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<BookingsCubit>().onStatusChanged(data: '');
    context.read<BookingsCubit>().onSortByChanged(data: '');
    context.read<BookingsCubit>().getUpcomingBookings();
  }
}
