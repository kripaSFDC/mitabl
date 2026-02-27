import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/route_arguement.dart';
import '../cubit/requests_cubit.dart';
import 'accept_reject_dialog.dart';

class OrderDetails extends StatelessWidget {
  OrderDetails({Key? key, this.routeArguments}) : super(key: key);

  RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => OrderDetails(
              routeArguments: routeArguments,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Padding(
            padding:
                EdgeInsets.only(top: config.AppConfig(context).appHeight(3)),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    navigatorKey.currentState!.pop();
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).primaryColorDark,
                    size: config.AppConfig(context).appWidth(5),
                  ),
                ),
                SizedBox(
                  width: config.AppConfig(context).appWidth(2),
                ),
                Flexible(
                  child: Text(
                    'Order Details',
                    style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                        fontSize: config.AppConfig(context).appWidth(5),
                        fontFamily: config.FontFamily()
                            .itcAvantGardeGothicStdFontFamily,
                        fontWeight: config.FontFamily().medium),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<RequestsCubit, RequestsState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: config.AppConfig(context).appHeight(3),
                  ),
                  Container(
                    // alignment: Alignment.topCenter,
                    height: config.AppConfig(context).appHeight(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Center(
                              child: Container(
                                height: config.AppConfig(context).appHeight(11),
                                width: config.AppConfig(context).appHeight(11),
                                decoration: BoxDecoration(
                                  color: config.AppColors()
                                      .textFieldBackgroundColor(1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      '${GlobalConfiguration().getValue<String>('image_base_url')}${routeArguments!.bookings!.customer!.avatar!}',
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    height:
                                        config.AppConfig(context).appWidth(25),
                                    width:
                                        config.AppConfig(context).appWidth(25),
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
                                        color:
                                            Theme.of(context).backgroundColor,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                  placeholder: (context, s) => Container(
                                    height:
                                        config.AppConfig(context).appHeight(15),
                                    width:
                                        config.AppConfig(context).appHeight(15),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).backgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: config.AppConfig(context).appWidth(2),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => {
                                    navigatorKey.currentState!.pushNamed(
                                        '/UserDetails',
                                        arguments: RouteArguments(
                                            customer: routeArguments!
                                                .bookings!.customer))
                                  },
                                  child: Text(
                                    routeArguments!.bookings!.customer!.name
                                        .toString(),
                                    style: TextStyle(
                                      fontSize:
                                          config.AppConfig(context).appWidth(4),
                                      color: Theme.of(context).primaryColor,
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().medium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      config.AppConfig(context).appHeight(1),
                                ),
                                RatingBar.builder(
                                  ignoreGestures: true,
                                  initialRating: routeArguments!
                                      .bookings!.customer!.rating!,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize:
                                      config.AppConfig(context).appWidth(3.5),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Color(0xffFFA200),
                                    size: config.AppConfig(context).appWidth(2),
                                  ),
                                  onRatingUpdate: (rating) {
                                    print(rating);
                                  },
                                ),
                                SizedBox(
                                  height:
                                      config.AppConfig(context).appHeight(1),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: config.AppConfig(context)
                                          .appHeight(0.2),
                                      horizontal: config.AppConfig(context)
                                          .appWidth(2.5)),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            config.AppConfig(context)
                                                .appWidth(2.5))),
                                    border:
                                        Border.all(color: Color(0xff707070)),
                                  ),
                                  child: Text(
                                    routeArguments!.bookings!.dineIn == 1
                                        ? 'Dine-in'
                                        : 'Take-away',
                                    style: TextStyle(
                                      fontSize:
                                          config.AppConfig(context).appWidth(3),
                                      color: config.AppColors()
                                          .colorPrimaryDark(1),
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().book,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          // mainAxisSize: MainAxisSize.min,
                          children: [
                            // Spacer(),
                            Expanded(flex: 5, child: SizedBox()),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ID: ${routeArguments!.bookings!.order_type_id.toString()}',
                                style: TextStyle(
                                  fontSize:
                                      config.AppConfig(context).appWidth(3.5),
                                  color: Theme.of(context).primaryColorDark,
                                  fontFamily: config.FontFamily()
                                      .itcAvantGardeGothicStdFontFamily,
                                  fontWeight: config.FontFamily().medium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(3),
                  ),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(1),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date:',
                                    style: TextStyle(
                                      fontSize: config.AppConfig(context)
                                          .appWidth(3.8),
                                      color: Theme.of(context).primaryColorDark,
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
                                    routeArguments!.bookings!.date.toString(),
                                    style: TextStyle(
                                      fontSize: config.AppConfig(context)
                                          .appWidth(3.5),
                                      color: Theme.of(context).primaryColorDark,
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().book,
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
                                  fontSize:
                                      config.AppConfig(context).appWidth(3.8),
                                  color: Theme.of(context).primaryColorDark,
                                  fontFamily: config.FontFamily()
                                      .itcAvantGardeGothicStdFontFamily,
                                  fontWeight: config.FontFamily().demi,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                height:
                                    config.AppConfig(context).appHeight(0.5),
                              ),
                              Text(
                                '${routeArguments!.bookings!.timeFrom} to ${routeArguments!.bookings!.timeTo}',
                                style: TextStyle(
                                  fontSize:
                                      config.AppConfig(context).appWidth(3.5),
                                  color: Theme.of(context).primaryColorDark,
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Persons:',
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
                                      '${routeArguments!.bookings!.persons}',
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
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
                  routeArguments!.bookings!.dineIn != 1 &&
                          routeArguments!.bookings!.items!.length > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            Text(
                              'Food Ordered',
                              style: TextStyle(
                                fontSize: config.AppConfig(context).appWidth(4),
                                color: Theme.of(context).primaryColorDark,
                                fontFamily: config.FontFamily()
                                    .itcAvantGardeGothicStdFontFamily,
                                fontWeight: config.FontFamily().demi,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            ListView.separated(
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
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4),
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontFamily: config.FontFamily()
                                              .itcAvantGardeGothicStdFontFamily,
                                          fontWeight: config.FontFamily().book,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'AUD ${routeArguments!.bookings!.items![index].price}',
                                        style: TextStyle(
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4),
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontFamily: config.FontFamily()
                                              .itcAvantGardeGothicStdFontFamily,
                                          fontWeight: config.FontFamily().book,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(1),
                                  );
                                },
                                itemCount:
                                    routeArguments!.bookings!.items!.length),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(1),
                            ),
                            Divider(
                              height: config.AppConfig(context).appHeight(1.2),
                              color: Color(0xffE9E9E9),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Bill',
                                  style: TextStyle(
                                    fontSize:
                                        config.AppConfig(context).appWidth(4),
                                    color: Theme.of(context).primaryColorDark,
                                    fontFamily: config.FontFamily()
                                        .itcAvantGardeGothicStdFontFamily,
                                    fontWeight: config.FontFamily().medium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "AUD ${routeArguments!.bookings!.itemTotalPrice.toString()}",
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
                              ],
                            ),
                          ],
                        )
                      : SizedBox(),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(10),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: config.AppConfig(context).appWidth(4),
                        vertical: config.AppConfig(context).appHeight(1.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: config.AppConfig(context).appHeight(5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor,
                                    ])),
                            child: MaterialButton(
                                child: Text(
                                  'Accept',
                                  style: TextStyle(
                                      fontSize: config.AppConfig(context)
                                          .appWidth(3.5),
                                      fontFamily: config.FontFamily()
                                          .itcAvantGardeGothicStdFontFamily,
                                      fontWeight: config.FontFamily().book,
                                      color: Colors.white),
                                ),
                                height: config.AppConfig(context).appHeight(6),
                                minWidth:
                                    config.AppConfig(context).appWidth(100),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (c) {
                                        return BlocProvider.value(
                                          value: context.read<RequestsCubit>(),
                                          child: AcceptRejectDialog(
                                              isAccept: true,
                                              isFromOrderView: true,
                                              id: routeArguments!
                                                  .bookings!.orderId),
                                        );
                                      });
                                }),
                          ),
                        ),
                        SizedBox(
                          width: config.AppConfig(context).appWidth(3),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: config.AppConfig(context).appHeight(5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Color(0xffE9E9E9)),
                            child: MaterialButton(
                                child: Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize:
                                        config.AppConfig(context).appWidth(3.5),
                                    color:
                                        config.AppColors().colorPrimaryDark(1),
                                    fontFamily: config.FontFamily()
                                        .itcAvantGardeGothicStdFontFamily,
                                    fontWeight: config.FontFamily().book,
                                  ),
                                ),
                                height: config.AppConfig(context).appHeight(6),
                                minWidth:
                                    config.AppConfig(context).appWidth(100),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (c) {
                                        return BlocProvider.value(
                                          value: context.read<RequestsCubit>(),
                                          child: AcceptRejectDialog(
                                              isAccept: false,
                                              isFromOrderView: true,
                                              id: routeArguments!
                                                  .bookings!.orderId),
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
            );
          },
        ),
      ),
    );
  }
}
