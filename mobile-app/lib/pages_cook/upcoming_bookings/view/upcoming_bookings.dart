import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  const UpcomingBookings({Key? key}) : super(key: key);

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) => BookingsCubit(
                  BookingRepository(context.read<UserRepository>())),
              child: UpcomingBookings(),
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
                    child: BookingFilterDialog(isUpComing: true),
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
                    ? NoDataWidget()
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
                                        color: const Color(0xff0000001C)
                                            .withOpacity(0.11),
                                        blurRadius: 1.3,
                                        offset: const Offset(-0.01, -0.01)),
                                    BoxShadow(
                                        color: const Color(0xff0000001C)
                                            .withOpacity(0.11),
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
                                              .bodyText1
                                              ?.copyWith(fontSize: 16),
                                        ),
                                        Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Date: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2
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
                                                        .subtitle2)
                                              ]),
                                        ),
                                        Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Time: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2
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
                                                        .subtitle2)
                                              ]),
                                        ),
                                        Spacer(),
                                        RichText(
                                          text: TextSpan(
                                              text: 'Persons: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2
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
                                                        .subtitle2)
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
                                                    color: Color(0xff707070)),
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
                                                    .subtitle2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
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
                                                .subtitle2
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
    context.read<BookingsCubit>().onStatusChanged(data: '');
    context.read<BookingsCubit>().onSortByChanged(data: '');
    context.read<BookingsCubit>().getUpcomingBookings();
  }
}

// elements

//Padding(
//             padding: EdgeInsets.all(config.AppConfig(context).appWidth(2)),
//             child: Container(
//               height: config.AppConfig(context).appHeight(15),
//               decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.all(
//                     Radius.circular(config.AppConfig(context).appWidth(1.6)),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                         color: const Color(0xff0000001C).withOpacity(0.11),
//                         blurRadius: 1.3,
//                         offset: const Offset(-0.01, -0.01)),
//                     BoxShadow(
//                         color: const Color(0xff0000001C).withOpacity(0.11),
//                         blurRadius: 0.5,
//                         offset: const Offset(0, 0.0)),
//                   ]),
//               child: Padding(
//                 padding: EdgeInsets.all(config.AppConfig(context).appWidth(2)),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.max,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Feeney Haven',
//                           style: GoogleFonts.gothicA1(
//                               fontSize: config.AppConfig(context).appWidth(4.5),
//                               color: Theme.of(context).primaryColor,
//                               fontWeight: FontWeight.w600),
//                         ),
//                         Spacer(),
//                         RichText(
//                           text: TextSpan(
//                               text: 'Date: ',
//                               style: GoogleFonts.gothicA1(
//                                   color: Color(0xff666666),
//                                   fontWeight: FontWeight.w500,
//                                   fontSize:
//                                       config.AppConfig(context).appWidth(3.5)),
//                               children: <TextSpan>[
//                                 TextSpan(
//                                     text: DateFormat('dd MMM yyyy').format(
//                                       DateTime.now(),
//                                     ),
//                                     style: GoogleFonts.poppins(
//                                         color: Color(0xff666666),
//                                         fontWeight: FontWeight.w400,
//                                         fontSize: config.AppConfig(context)
//                                             .appWidth(3.0)))
//                               ]),
//                         ),
//                         Spacer(),
//                         RichText(
//                           text: TextSpan(
//                               text: 'Time: ',
//                               style: GoogleFonts.gothicA1(
//                                   color: Color(0xff666666),
//                                   fontWeight: FontWeight.w500,
//                                   fontSize:
//                                       config.AppConfig(context).appWidth(3.5)),
//                               children: <TextSpan>[
//                                 TextSpan(
//                                     text: '2:00pm t0 4:00pm',
//                                     style: GoogleFonts.poppins(
//                                         color: Color(0xff666666),
//                                         fontWeight: FontWeight.w400,
//                                         fontSize: config.AppConfig(context)
//                                             .appWidth(3.0)))
//                               ]),
//                         ),
//                         Spacer(),
//                         RichText(
//                           text: TextSpan(
//                               text: 'Persons: ',
//                               style: GoogleFonts.gothicA1(
//                                   color: Color(0xff666666),
//                                   fontWeight: FontWeight.w500,
//                                   fontSize:
//                                       config.AppConfig(context).appWidth(3.5)),
//                               children: <TextSpan>[
//                                 TextSpan(
//                                     text: '2',
//                                     style: GoogleFonts.poppins(
//                                         color: Color(0xff666666),
//                                         fontWeight: FontWeight.w400,
//                                         fontSize: config.AppConfig(context)
//                                             .appWidth(3.0)))
//                               ]),
//                         )
//                       ],
//                     ),
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                   vertical:
//                                       config.AppConfig(context).appHeight(0.2),
//                                   horizontal:
//                                       config.AppConfig(context).appWidth(2.5)),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.all(Radius.circular(
//                                     config.AppConfig(context).appWidth(2.5))),
//                                 border: Border.all(color: Color(0xff707070)),
//                               ),
//                               child: Text(
//                                 'Dine-in',
//                                 style: GoogleFonts.gothicA1(
//                                     color: Color(0xff666666),
//                                     fontSize:
//                                         config.AppConfig(context).appWidth(3.5),
//                                     fontWeight: FontWeight.w500),
//                               ),
//                             ),
//                             SizedBox(
//                               width: config.AppConfig(context).appWidth(2.5),
//                             ),
//                             Container(
//                               margin: EdgeInsets.zero,
//                               padding: EdgeInsets.symmetric(
//                                   vertical:
//                                       config.AppConfig(context).appHeight(0.3),
//                                   horizontal:
//                                       config.AppConfig(context).appWidth(2.5)),
//                               decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.all(
//                                       Radius.circular(config.AppConfig(context)
//                                           .appWidth(2.5))),
//                                   color: Color(0xff3DAE06)),
//                               child: Text(
//                                 'Completed',
//                                 style: GoogleFonts.gothicA1(
//                                     color: Colors.white,
//                                     fontSize:
//                                         config.AppConfig(context).appWidth(3.5),
//                                     fontWeight: FontWeight.w500),
//                               ),
//                             )
//                           ],
//                         ),
//                         Spacer(),
//                         Text(
//                           'View Details',
//                           style: GoogleFonts.gothicA1(
//                               fontSize: config.AppConfig(context).appWidth(3.5),
//                               color: Theme.of(context).primaryColor,
//                               fontWeight: FontWeight.w400),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
