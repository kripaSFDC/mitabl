import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages_cook/requests/cubit/requests_cubit.dart';
import 'package:formz/formz.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/no_data_widget.dart';
import '../../../repos/authentication_repository.dart';
import '../elements/accept_reject_dialog.dart';
import '../elements/order_details_view.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({Key? key}) : super(key: key);

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {

  @override
  void initState() {
    context.read<RequestsCubit>().getRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: config.AppConfig(context).appWidth(32),
        leading: Padding(
          padding: EdgeInsets.only(
              left: config.AppConfig(context).appWidth(5.2),
              top: config.AppConfig(context).appHeight(2)),
          child: Center(
            child: Text(
              'Requests',
              style: Theme.of(context).textTheme.headline5?.copyWith(
                fontSize: config.AppConfig(context).appWidth(5.0),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,

      ),
      body: BlocConsumer<RequestsCubit, RequestsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Stack(
            children: [
              state.requestBookingStatus!.isSubmissionInProgress
                  ? const Center()
                  : state.requestBookingModel == null ||
                          state.requestBookingModel!.data!.bookings!.isEmpty
                      ? const NoDataWidget()
                      : ListView.separated(
                          // shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.all(
                                  config.AppConfig(context).appWidth(4)),
                              child: Container(
                                height:
                                    config.AppConfig(context).appHeight(22),
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
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                            config.AppConfig(context)
                                                .appWidth(3)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    navigatorKey.currentState!.pushNamed(
                                                        '/UserDetails',
                                                        arguments: RouteArguments(
                                                            customer: state
                                                                .requestBookingModel!
                                                                .data!
                                                                .bookings![
                                                                    index]
                                                                .customer!));
                                                  },
                                                  child: Text(
                                                    state
                                                        .requestBookingModel!
                                                        .data!
                                                        .bookings![index]
                                                        .customer!
                                                        .name
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        ?.copyWith(
                                                            fontSize: 16),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(0.5),
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                      text: 'Date: ',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle2
                                                          ?.copyWith(
                                                              fontWeight: config
                                                                      .FontFamily()
                                                                  .demi),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                            text: state
                                                                .requestBookingModel!
                                                                .data!
                                                                .bookings![
                                                                    index]
                                                                .date,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2)
                                                      ]),
                                                ),
                                                SizedBox(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(0.5),
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                      text: 'Time: ',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle2
                                                          ?.copyWith(
                                                              fontWeight: config
                                                                      .FontFamily()
                                                                  .demi),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                            text:
                                                                '${state.requestBookingModel!.data!.bookings![index].timeFrom} to ${state.requestBookingModel!.data!.bookings![index].timeTo}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2)
                                                      ]),
                                                ),
                                                SizedBox(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(0.5),
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                      text: 'Persons: ',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle2
                                                          ?.copyWith(
                                                              fontWeight: config
                                                                      .FontFamily()
                                                                  .demi),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                            text: state
                                                                .requestBookingModel!
                                                                .data!
                                                                .bookings![
                                                                    index]
                                                                .persons
                                                                .toString(),
                                                            style: Theme.of(
                                                                    context)
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                          vertical:
                                                              config.AppConfig(
                                                                      context)
                                                                  .appHeight(
                                                                      0.2),
                                                          horizontal:
                                                              config.AppConfig(
                                                                      context)
                                                                  .appWidth(
                                                                      2.5)),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius
                                                            .all(Radius.circular(
                                                                config.AppConfig(
                                                                        context)
                                                                    .appWidth(
                                                                        2.5))),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xff707070)),
                                                      ),
                                                      child: Text(
                                                        state
                                                                    .requestBookingModel!
                                                                    .data!
                                                                    .bookings![
                                                                        index]
                                                                    .dineIn ==
                                                                1
                                                            ? 'Dine-in'
                                                            : 'Take-away',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle2,
                                                      ),
                                                    ),
                                                    // SizedBox(
                                                    //   width: config.AppConfig(context)
                                                    //       .appWidth(2.5),
                                                    // ),
                                                    // Container(
                                                    //   margin: EdgeInsets.zero,
                                                    //   padding: EdgeInsets.symmetric(
                                                    //       vertical:
                                                    //       config.AppConfig(context)
                                                    //           .appHeight(0.3),
                                                    //       horizontal:
                                                    //       config.AppConfig(context)
                                                    //           .appWidth(2.5)),
                                                    //   decoration: BoxDecoration(
                                                    //       borderRadius: BorderRadius.all(
                                                    //           Radius.circular(
                                                    //               config.AppConfig(
                                                    //                   context)
                                                    //                   .appWidth(2.5))),
                                                    //       color: state
                                                    //           .upcomingBookingModel!
                                                    //           .data![index]
                                                    //           .status ==
                                                    //           0
                                                    //           ? Colors.red
                                                    //           : state
                                                    //           .upcomingBookingModel!
                                                    //           .data![index]
                                                    //           .status ==
                                                    //           1
                                                    //           ? Color(0xff3DAE06)
                                                    //           : state
                                                    //           .upcomingBookingModel!
                                                    //           .data![
                                                    //       index]
                                                    //           .status ==
                                                    //           2
                                                    //           ? Colors.yellow
                                                    //           : Colors.blue),
                                                    //   child: Text(
                                                    //     state.upcomingBookingModel!.data![index]
                                                    //         .status ==
                                                    //         0
                                                    //         ? 'Canceled'
                                                    //         : state
                                                    //         .upcomingBookingModel!
                                                    //         .data![index]
                                                    //         .status ==
                                                    //         1
                                                    //         ? 'Completed'
                                                    //         : state
                                                    //         .upcomingBookingModel!
                                                    //         .data![index]
                                                    //         .status ==
                                                    //         2
                                                    //         ? 'Pending'
                                                    //         : 'Acceptted',
                                                    //     style: GoogleFonts.gothicA1(
                                                    //         color: Colors.white,
                                                    //         fontSize:
                                                    //         config.AppConfig(context)
                                                    //             .appWidth(3.5),
                                                    //         fontWeight: FontWeight.w500),
                                                    //   ),
                                                    // )
                                                  ],
                                                ),
                                                Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    print('opendetail pagae');
                                                    navigatorKey.currentState!
                                                        .push(MaterialPageRoute<
                                                                void>(
                                                            builder:
                                                                (_) =>
                                                                    BlocProvider
                                                                        .value(
                                                                      value: context
                                                                          .read<
                                                                              RequestsCubit>(),
                                                                      child:
                                                                          OrderDetails(
                                                                        routeArguments:
                                                                            RouteArguments(bookings: state.requestBookingModel!.data!.bookings![index]),
                                                                      ),
                                                                    )));
                                                    // navigatorKey.currentState!.pushNamed(
                                                    //     '/OrderDetails',
                                                    //     arguments: RouteArguments(
                                                    //         bookings: state
                                                    //             .requestBookingModel!
                                                    //             .data!
                                                    //             .bookings![index]));
                                                  },
                                                  child: Text(
                                                    'View Details',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle2
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      color: const Color(0xffEEEEEE),
                                      height: config.AppConfig(context)
                                          .appHeight(0.5),
                                      thickness: config.AppConfig(context)
                                          .appHeight(0.25),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: config.AppConfig(context)
                                              .appWidth(4),
                                          vertical: config.AppConfig(context)
                                              .appHeight(1.5)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              height: config.AppConfig(context)
                                                  .appHeight(4.5),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.topRight,
                                                      colors: [
                                                        Theme.of(context)
                                                            .primaryColor,
                                                        Theme.of(context)
                                                            .primaryColor,
                                                      ])),
                                              child: MaterialButton(
                                                  child: Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: config
                                                                .FontFamily()
                                                            .itcAvantGardeGothicStdFontFamily,
                                                        fontWeight:
                                                            config.FontFamily()
                                                                .book,
                                                        color: Colors.white),
                                                  ),
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(6),
                                                  minWidth:
                                                      config.AppConfig(context)
                                                          .appWidth(100),
                                                  onPressed: () {
                                                    showDialog(
                                                        context: context,
                                                        builder: (c) {
                                                          return BlocProvider
                                                                  .value(
                                                            value: context.read<
                                                                RequestsCubit>(),
                                                            child: AcceptRejectDialog(
                                                                isAccept: true,
                                                                id: state
                                                                    .requestBookingModel!
                                                                    .data!
                                                                    .bookings![
                                                                        index]
                                                                    .orderId),
                                                          )

                                                              /*showAcceptDeclineDialog(
                                                              isAccept: true,
                                                              id: state
                                                                  .requestBookingModel!
                                                                  .data!
                                                                  .bookings![
                                                                      index]
                                                                  .orderId)*/
                                                              ;
                                                        });
                                                  }),
                                            ),
                                          ),
                                          SizedBox(
                                            width: config.AppConfig(context)
                                                .appWidth(3),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              height: config.AppConfig(context)
                                                  .appHeight(4.5),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  color: Color(0xffE9E9E9)),
                                              child: MaterialButton(
                                                  child: Text(
                                                    'Decline',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: config.AppColors()
                                                          .colorPrimaryDark(1),
                                                      fontFamily: config
                                                              .FontFamily()
                                                          .itcAvantGardeGothicStdFontFamily,
                                                      fontWeight:
                                                          config.FontFamily()
                                                              .book,
                                                    ),
                                                  ),
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(6),
                                                  minWidth:
                                                      config.AppConfig(context)
                                                          .appWidth(100),
                                                  onPressed: () {
                                                    showDialog(
                                                        context: context,
                                                        builder: (c) {
                                                          return BlocProvider
                                                              .value(
                                                            value: context.read<
                                                                RequestsCubit>(),
                                                            child: AcceptRejectDialog(
                                                                isAccept: false,
                                                                id: state
                                                                    .requestBookingModel!
                                                                    .data!
                                                                    .bookings![
                                                                        index]
                                                                    .orderId),
                                                          );
                                                        });
                                                  }),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(
                              height: config.AppConfig(context).appHeight(1),
                            );
                          },
                          itemCount: state
                              .requestBookingModel!.data!.bookings!.length),
              state.requestBookingStatus!.isSubmissionInProgress
                  ? CommonProgressWidget()
                  : SizedBox(),
            ],
          );
        },
      ),
    );
  }

  showAcceptDeclineDialog({bool? isAccept, String? id}) {
    return SizedBox(
      height: config.AppConfig(context).appHeight(30),
      width: config.AppConfig(context).appWidth(50),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: config.AppConfig(context).appHeight(1),
                      right: config.AppConfig(context).appWidth(2)),
                  child: InkWell(
                    onTap: () {
                      navigatorKey.currentState!.pop();
                    },
                    child: Container(
                      height: config.AppConfig(context).appHeight(2.5),
                      width: config.AppConfig(context).appHeight(2.5),
                      padding:
                          EdgeInsets.all(config.AppConfig(context).appWidth(0)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(
                              config.AppConfig(context).appWidth(10))),
                          border: Border.all(
                              color: Theme.of(context).primaryColorDark)),
                      child: Icon(
                        Icons.clear,
                        color: Theme.of(context).primaryColorDark,
                        size: config.AppConfig(context).appWidth(4.0),
                      ),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(4),
            ),
            Text(
              'Order Request',
              style: TextStyle(
                fontFamily:
                    config.FontFamily().itcAvantGardeGothicStdFontFamily,
                fontWeight: config.FontFamily().demi,
                color: Theme.of(context).primaryColorDark,
                fontSize: config.AppConfig(context).appWidth(5.5),
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(10)),
              child: Text(
                'Are you sure you want to ${isAccept! ? 'accept' : 'decline'} the order?',
                style: TextStyle(
                  fontFamily:
                      config.FontFamily().itcAvantGardeGothicStdFontFamily,
                  fontWeight: config.FontFamily().book,
                  color: Theme.of(context).primaryColorDark,
                  fontSize: config.AppConfig(context).appWidth(4.0),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(3),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(5)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Theme.of(context).primaryColor),
                      child: MaterialButton(
                          child: Text(
                            'YES',
                            style: TextStyle(
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: Colors.white,
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              fontWeight: config.FontFamily().book,
                            ),
                          ),
                          height: config.AppConfig(context).appHeight(6),
                          minWidth: config.AppConfig(context).appWidth(100),
                          onPressed: () {
                            context.read<RequestsCubit>().onOrderAcceptDecline(
                                isAccept: isAccept, orderId: id);
                          }),
                    ),
                  ),
                  SizedBox(
                    width: config.AppConfig(context).appWidth(3),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Color(0xffE9E9E9)),
                      child: MaterialButton(
                          child: Text(
                            'NO',
                            style: TextStyle(
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: config.AppColors().colorPrimaryDark(1),
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              fontWeight: config.FontFamily().book,
                            ),
                          ),
                          height: config.AppConfig(context).appHeight(6),
                          minWidth: config.AppConfig(context).appWidth(100),
                          onPressed: () {
                            navigatorKey.currentState!.pop();
                          }),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(4),
            ),
          ],
        ),
      ),
    );
  }
}
