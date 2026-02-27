import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:formz/formz.dart';
import '../../../helper/common_progress.dart';
import '../../../helper/route_arguement.dart';

class OrderDetailsBookings extends StatelessWidget {
  OrderDetailsBookings({Key? key, this.routeArguments}) : super(key: key);

  RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => OrderDetailsBookings(
              routeArguments: routeArguments,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Order Details',
          isFilter: false,
        ),
        body: BlocConsumer<BookingsCubit, BookingsState>(
          listener: (context, state) {
            if (state.orderCompleteCancelStatus!.isSubmissionSuccess) {
              context.read<DashboardCookCubit>().getDashBoardData();
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: config.AppConfig(context).appWidth(4)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: config.AppConfig(context).appHeight(3),
                        ),
                        Container(
                          alignment: Alignment.topCenter,
                          height: config.AppConfig(context).appHeight(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Center(
                                    child: Container(
                                      height: config.AppConfig(context)
                                          .appHeight(11),
                                      width: config.AppConfig(context)
                                          .appHeight(11),
                                      decoration: BoxDecoration(
                                        color: config.AppColors()
                                            .textFieldBackgroundColor(1),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '${GlobalConfiguration().getValue<String>('image_base_url')}${routeArguments!.bookings!.customer!.avatar!}',
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          height: config.AppConfig(context)
                                              .appWidth(25),
                                          width: config.AppConfig(context)
                                              .appWidth(25),
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100)),
                                        ),
                                        errorWidget: (context, data, e) {
                                          return Container(
                                            height: config.AppConfig(context)
                                                .appHeight(15),
                                            width: config.AppConfig(context)
                                                .appHeight(15),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .backgroundColor,
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        },
                                        placeholder: (context, s) => Container(
                                          height: config.AppConfig(context)
                                              .appHeight(15),
                                          width: config.AppConfig(context)
                                              .appHeight(15),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .backgroundColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        config.AppConfig(context).appWidth(2),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              navigatorKey.currentState!
                                                  .pushNamed('/UserDetails',
                                                      arguments: RouteArguments(
                                                          customer:
                                                              routeArguments!
                                                                  .bookings!
                                                                  .customer!));
                                            },
                                            child: Text(
                                              routeArguments!
                                                  .bookings!.customer!.name
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize:
                                                    config.AppConfig(context)
                                                        .appWidth(4),
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontFamily: config.FontFamily()
                                                    .itcAvantGardeGothicStdFontFamily,
                                                fontWeight:
                                                    config.FontFamily().medium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: config.AppConfig(context)
                                            .appHeight(1),
                                      ),
                                      RatingBar.builder(
                                        ignoreGestures: true,
                                        initialRating: routeArguments!
                                            .bookings!.customer!.rating!,
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: config.AppConfig(context)
                                            .appWidth(3.5),
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: Color(0xffFFA200),
                                          size: config.AppConfig(context)
                                              .appWidth(2),
                                        ),
                                        onRatingUpdate: (rating) {
                                          print(rating);
                                        },
                                      ),
                                      SizedBox(
                                        height: config.AppConfig(context)
                                            .appHeight(1),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: config.AppConfig(context)
                                                .appHeight(0.2),
                                            horizontal:
                                                config.AppConfig(context)
                                                    .appWidth(2.5)),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                  config.AppConfig(context)
                                                      .appWidth(2.5))),
                                          border: Border.all(
                                              color: Color(0xff707070)),
                                        ),
                                        child: Text(
                                          routeArguments!.bookings!.dineIn == 1
                                              ? 'Dine-in'
                                              : 'Take-away',
                                          style: TextStyle(
                                            fontSize: config.AppConfig(context)
                                                .appWidth(3),
                                            color: config.AppColors()
                                                .colorPrimaryDark(1),
                                            fontFamily: config.FontFamily()
                                                .itcAvantGardeGothicStdFontFamily,
                                            fontWeight:
                                                config.FontFamily().book,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  !routeArguments!.isUpcoming!
                                      ? Expanded(flex: 1, child: SizedBox())
                                      : SizedBox(),
                                  !routeArguments!.isUpcoming!
                                      ? Container(
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
                                              color: routeArguments!
                                                          .bookings!.status ==
                                                      0
                                                  ? Colors.red
                                                  : routeArguments!.bookings!
                                                              .status ==
                                                          1
                                                      ? Color(0xff3DAE06)
                                                      : routeArguments!
                                                                  .bookings!
                                                                  .status ==
                                                              2
                                                          ? Colors.yellow
                                                          : Colors.blue),
                                          child: Text(
                                            routeArguments!.bookings!.status ==
                                                    0
                                                ? 'Canceled'
                                                : routeArguments!
                                                            .bookings!.status ==
                                                        1
                                                    ? 'Completed'
                                                    : routeArguments!.bookings!
                                                                .status ==
                                                            2
                                                        ? 'Pending'
                                                        : 'Accepted',
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        )
                                      : SizedBox(),
                                  Expanded(flex: 2, child: SizedBox()),
                                  Text(
                                    'ID: ${routeArguments!.bookings!.order_type_id.toString()}',
                                    style: TextStyle(
                                      fontSize: config.AppConfig(context)
                                          .appWidth(3.5),
                                      color: Theme.of(context).primaryColorDark,
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().medium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(flex: 1, child: SizedBox()),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(3),
                        ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(1 ),
                        ),
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date:',
                                          style: TextStyle(
                                            fontSize: config.AppConfig(context)
                                                .appWidth(3.8),
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontFamily: config.FontFamily()
                                                .itcAvantGardeGothicStdFontFamily,
                                            fontWeight:
                                                config.FontFamily().demi,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          height: config.AppConfig(context)
                                              .appHeight(0.5),
                                        ),
                                        Text(
                                          routeArguments!.bookings!.date
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: config.AppConfig(context)
                                                .appWidth(3.5),
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontFamily: config.FontFamily()
                                                .itcAvantGardeGothicStdFontFamily,
                                            fontWeight:
                                                config.FontFamily().book,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                flex: 1,
                                child: VerticalDivider(
                                  color: Color(0xffE9E9E9),
                                  thickness: 2,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time:',
                                      style: TextStyle(
                                        fontSize: config.AppConfig(context)
                                            .appWidth(3.8),
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontFamily: config.FontFamily()
                                            .itcAvantGardeGothicStdFontFamily,
                                        fontWeight: config.FontFamily().demi,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      height: config.AppConfig(context)
                                          .appHeight(0.5),
                                    ),
                                    Text(
                                      '${routeArguments!.bookings!.timeFrom} to ${routeArguments!.bookings!.timeTo}',
                                      style: TextStyle(
                                        fontSize: config.AppConfig(context)
                                            .appWidth(3.5),
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontFamily: config.FontFamily()
                                            .itcAvantGardeGothicStdFontFamily,
                                        fontWeight: config.FontFamily().book,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 2,
                                    )
                                  ],
                                ),
                              ),
                              routeArguments!.bookings!.dineIn == 1
                                  ? const Expanded(
                                      flex: 1,
                                      child: VerticalDivider(
                                        color: Color(0xffE9E9E9),
                                        thickness: 2,
                                      ),
                                    )
                                  : SizedBox(),
                              routeArguments!.bookings!.dineIn == 1
                                  ? Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Persons:',
                                            style: TextStyle(
                                              fontSize:
                                                  config.AppConfig(context)
                                                      .appWidth(3.8),
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontFamily: config.FontFamily()
                                                  .itcAvantGardeGothicStdFontFamily,
                                              fontWeight:
                                                  config.FontFamily().demi,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(
                                            height: config.AppConfig(context)
                                                .appHeight(0.5),
                                          ),
                                          Text(
                                            '${routeArguments!.bookings!.persons}',
                                            style: TextStyle(
                                              fontSize:
                                                  config.AppConfig(context)
                                                      .appWidth(3.5),
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontFamily: config.FontFamily()
                                                  .itcAvantGardeGothicStdFontFamily,
                                              fontWeight:
                                                  config.FontFamily().book,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            maxLines: 2,
                                          )
                                        ],
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ),
                        routeArguments!.isUpcoming!
                            ? Column(
                                children: [
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(3),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Contact ${routeArguments!.bookings!.customer!.name}',
                                        style: TextStyle(
                                          fontSize: config.AppConfig(context)
                                              .appWidth(3.8),
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontFamily: config.FontFamily()
                                              .itcAvantGardeGothicStdFontFamily,
                                          fontWeight: config.FontFamily().demi,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        'assets/img/contact_w.svg',
                                        height: config.AppConfig(context)
                                            .appHeight(6),
                                        width: config.AppConfig(context)
                                            .appHeight(6),
                                        // color: Colors.white,
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(3),
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        routeArguments!.bookings!.dineIn != 1 &&
                                routeArguments!.bookings!.items!.length > 0
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(3),
                                  ),
                                  Text(
                                    'Food Ordered',
                                    style: TextStyle(
                                      fontSize:
                                          config.AppConfig(context).appWidth(4),
                                      color: Theme.of(context).primaryColorDark,
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().demi,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(3),
                                  ),
                                  ListView.separated(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${routeArguments!.bookings!.items![index].quantity} x ${routeArguments!.bookings!.items![index].food}',
                                              style: TextStyle(
                                                fontSize:
                                                    config.AppConfig(context)
                                                        .appWidth(4),
                                                color: Theme.of(context)
                                                    .primaryColorDark,
                                                fontFamily: config.FontFamily()
                                                    .itcAvantGardeGothicStdFontFamily,
                                                fontWeight:
                                                    config.FontFamily().book,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              'AUD ${routeArguments!.bookings!.items![index].price}',
                                              style: TextStyle(
                                                fontSize:
                                                    config.AppConfig(context)
                                                        .appWidth(4),
                                                color: Theme.of(context)
                                                    .primaryColorDark,
                                                fontFamily: config.FontFamily()
                                                    .itcAvantGardeGothicStdFontFamily,
                                                fontWeight:
                                                    config.FontFamily().book,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          ],
                                        );
                                      },
                                      separatorBuilder: (context, index) {
                                        return SizedBox(
                                          height: config.AppConfig(context)
                                              .appHeight(1),
                                        );
                                      },
                                      itemCount: routeArguments!
                                          .bookings!.items!.length),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(1),
                                  ),
                                  Divider(
                                    height: config.AppConfig(context)
                                        .appHeight(1.2),
                                    color: Color(0xffE9E9E9),
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(1),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Bill',
                                        style: TextStyle(
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4),
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontFamily: config.FontFamily()
                                              .itcAvantGardeGothicStdFontFamily,
                                          fontWeight:
                                              config.FontFamily().medium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "AUD ${routeArguments!.bookings!.itemTotalPrice.toString()}",
                                        style: TextStyle(
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4),
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontFamily: config.FontFamily()
                                              .itcAvantGardeGothicStdFontFamily,
                                          fontWeight: config.FontFamily().demi,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(
                              routeArguments!.bookings!.dineIn == 1 ? 20 : 10),
                        ),
                        routeArguments!.isUpcoming!
                            ? Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: config.AppConfig(context)
                                          .appHeight(6),
                                      width: config.AppConfig(context)
                                          .appWidth(80),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(26.0),
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              colors: [
                                                Theme.of(context).primaryColor,
                                                Theme.of(context).primaryColor,
                                              ])),
                                      child: MaterialButton(
                                          child: Text(
                                            'ORDER COMPLETED',
                                            style: TextStyle(
                                                fontSize:
                                                    config.AppConfig(context)
                                                        .appWidth(3.5),
                                                fontFamily: config.FontFamily()
                                                    .itcAvantGardeGothicStdFontFamily,
                                                fontWeight:
                                                    config.FontFamily().book,
                                                color: Colors.white),
                                          ),
                                          height: config.AppConfig(context)
                                              .appHeight(6),
                                          minWidth: config.AppConfig(context)
                                              .appWidth(100),
                                          onPressed: () {
                                            context
                                                .read<BookingsCubit>()
                                                .onOrderCompleteDecline(
                                                    orderId: routeArguments!
                                                        .bookings!.orderId!,
                                                    isCompleted: true);
                                          }),
                                    ),
                                    SizedBox(
                                      height: config.AppConfig(context)
                                          .appHeight(2),
                                    ),
                                    Container(
                                      height: config.AppConfig(context)
                                          .appHeight(6),
                                      width: config.AppConfig(context)
                                          .appWidth(80),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(26.0),
                                          color: const Color(0xffE9E9E9)),
                                      child: MaterialButton(
                                          child: Text(
                                            'CANCEL ORDER',
                                            style: TextStyle(
                                              fontSize:
                                                  config.AppConfig(context)
                                                      .appWidth(3.5),
                                              color: config.AppColors()
                                                  .colorPrimaryDark(1),
                                              fontFamily: config.FontFamily()
                                                  .itcAvantGardeGothicStdFontFamily,
                                              fontWeight:
                                                  config.FontFamily().book,
                                            ),
                                          ),
                                          height: config.AppConfig(context)
                                              .appHeight(6),
                                          minWidth: config.AppConfig(context)
                                              .appWidth(100),
                                          onPressed: () {
                                            context
                                                .read<BookingsCubit>()
                                                .onOrderCompleteDecline(
                                                    orderId: routeArguments!
                                                        .bookings!.orderId!,
                                                    isCompleted: false);
                                          }),
                                    ),
                                    SizedBox(
                                      height: config.AppConfig(context)
                                          .appHeight(2),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox()
                      ],
                    ),
                  ),
                ),
                state.orderCompleteCancelStatus!.isSubmissionInProgress
                    ? CommonProgressWidget()
                    : SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }
}
