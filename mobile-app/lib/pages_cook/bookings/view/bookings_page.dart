import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/booking_filter_dialog.dart';
import 'package:mitabl_user/pages_cook/bookings/elements/order_details_booking.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';

class Bookings extends StatefulWidget {
  const Bookings({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) => BookingsCubit(
                  BookingRepository(context.read<UserRepository>())),
              child: const Bookings(),
            ));
  }

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Bookings',
          onFilterSelected: () {
            showDialog(
                context: context,
                builder: (c) {
                  return BlocProvider.value(
                    value: context.read<BookingsCubit>(),
                    child: const BookingFilterDialog(isUpComing: false),
                  );
                });
          },
        ),
        body: BlocConsumer<BookingsCubit, BookingsState>(
          listener: (context, state) {},
          builder: (context, state) {
            return state.bookingStatus!.isSubmissionInProgress
                ? const Center(child: CommonProgressWidget())
                : state.bookingModel == null ||
                        state.bookingModel!.data!.bookings!.isEmpty
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
                                          state.bookingModel!.data!
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
                                                        .bookingModel!
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
                                                        '${state.bookingModel!.data!.bookings![index].timeFrom} t0 ${state.bookingModel!.data!.bookings![index].timeTo}',
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
                                                        .bookingModel!
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
                                                            .bookingModel!
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
                                            SizedBox(
                                              width: config.AppConfig(context)
                                                  .appWidth(2.5),
                                            ),
                                            Container(
                                              margin: EdgeInsets.zero,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      config.AppConfig(context)
                                                          .appHeight(0.3),
                                                  horizontal:
                                                      config.AppConfig(context)
                                                          .appWidth(2.5)),
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(
                                                          config.AppConfig(context)
                                                              .appWidth(2.5))),
                                                  color: state
                                                              .bookingModel!
                                                              .data!
                                                              .bookings![index]
                                                              .status ==
                                                          0
                                                      ? Colors.red
                                                      : state
                                                                  .bookingModel!
                                                                  .data!
                                                                  .bookings![
                                                                      index]
                                                                  .status ==
                                                              1
                                                          ? const Color(
                                                              0xff3DAE06)
                                                          : state
                                                                      .bookingModel!
                                                                      .data!
                                                                      .bookings![index]
                                                                      .status ==
                                                                  2
                                                              ? Colors.yellow
                                                              : Colors.blue),
                                              child: Text(
                                                state
                                                            .bookingModel!
                                                            .data!
                                                            .bookings![index]
                                                            .status ==
                                                        0
                                                    ? 'Canceled'
                                                    : state
                                                                .bookingModel!
                                                                .data!
                                                                .bookings![
                                                                    index]
                                                                .status ==
                                                            1
                                                        ? 'Completed'
                                                        : state
                                                                    .bookingModel!
                                                                    .data!
                                                                    .bookings![
                                                                        index]
                                                                    .status ==
                                                                2
                                                            ? 'Pending'
                                                            : 'Accepted',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: Colors.white),
                                              ),
                                            )
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
                                                                        .bookingModel!
                                                                        .data!
                                                                        .bookings![
                                                                    index],
                                                                isUpcoming:
                                                                    false),
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
                        itemCount: state.bookingModel!.data!.bookings!.length);
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
    context.read<BookingsCubit>().getBookings();
  }
}
