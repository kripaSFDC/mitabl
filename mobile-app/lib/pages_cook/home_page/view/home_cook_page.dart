import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/home_page/element/home_cook_header.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/shape_custom.dart';

class HomePageCook extends StatefulWidget {
  const HomePageCook({Key? key}) : super(key: key);

  @override
  State<HomePageCook> createState() => _HomePageCookState();
}

class _HomePageCookState extends State<HomePageCook> {



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: SingleChildScrollView(
            child: BlocBuilder<DashboardCookCubit, DashboardCookState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: config.AppConfig(context).appHeight(3),
                    ),
                    HomeCookHeaderWidget(),
                    SizedBox(
                      height: config.AppConfig(context).appHeight(4),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.all(config.AppConfig(context).appWidth(6)),
                      width: config.AppConfig(context).appWidth(100),
                      height: config.AppConfig(context).appHeight(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Earnings',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: config.FontFamily().medium),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height:
                                      config.AppConfig(context).appHeight(1)),
                              Text(
                                'AUD ${state.dashboardData!.data!.totalEarning.toString()}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        config.AppConfig(context).appWidth(7),
                                    fontWeight: config.FontFamily().demi),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Spacer(),
                          SvgPicture.asset(
                            'assets/img/dollar.svg',
                            height: config.AppConfig(context).appHeight(10),
                            width: config.AppConfig(context).appHeight(10),
                            color: Colors.white,
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: config.AppConfig(context).appHeight(2),
                    ),
                    GestureDetector(
                      onTap: () {
                        navigatorKey.currentState!.pushNamed('/Bookings');
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(
                                  config.AppConfig(context).appWidth(6)),
                              width: config.AppConfig(context).appWidth(100),
                              height: config.AppConfig(context).appHeight(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Number Of Bookings',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1,
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(
                                          height: config.AppConfig(context)
                                              .appHeight(1)),
                                      Text(
                                        '${state.dashboardData!.data!.nBookings.toString()}',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontSize: config.AppConfig(context)
                                                .appWidth(7),
                                            fontWeight:
                                                config.FontFamily().demi),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  // Spacer(),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16)),
                                child: CustomPaint(
                                  painter: CustomShapeCook(),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        config.AppConfig(context).appWidth(6)),
                                    width:
                                        config.AppConfig(context).appWidth(30),
                                    height:
                                        config.AppConfig(context).appHeight(15),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )),
                                    child: SvgPicture.asset(
                                      'assets/img/booking.svg',
                                      height: config.AppConfig(context)
                                          .appHeight(10),
                                      width: config.AppConfig(context)
                                          .appHeight(10),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: config.AppConfig(context).appHeight(2),
                    ),
                    InkWell(
                      onTap: () {
                        navigatorKey.currentState!
                            .pushNamed('/UpcomingBookings');
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(
                                  config.AppConfig(context).appWidth(6)),
                              width: config.AppConfig(context).appWidth(100),
                              height: config.AppConfig(context).appHeight(15),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upcoming Bookings',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1!.copyWith(
                                          fontSize: config.AppConfig(context).appWidth(4.5)
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(
                                          height: config.AppConfig(context)
                                              .appHeight(1)),
                                      Text(
                                        '${state.dashboardData!.data!.nUpcomingBookings.toString()}',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontSize: config.AppConfig(context)
                                                .appWidth(7),
                                            fontWeight:
                                                config.FontFamily().demi),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  // Spacer(),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16)),
                                child: CustomPaint(
                                  painter: CustomShapeCook(),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        config.AppConfig(context).appWidth(6)),
                                    width:
                                        config.AppConfig(context).appWidth(30),
                                    height:
                                        config.AppConfig(context).appHeight(15),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )),
                                    child: SvgPicture.asset(
                                      'assets/img/plate.svg',
                                      height: config.AppConfig(context)
                                          .appHeight(10),
                                      width: config.AppConfig(context)
                                          .appHeight(10),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    context.read<DashboardCookCubit>().getDashBoardData();
  }
}
