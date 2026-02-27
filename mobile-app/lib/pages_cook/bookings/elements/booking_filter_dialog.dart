import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages_cook/bookings/cubit/bookings_cubit.dart';

import '../../../repos/authentication_repository.dart';

class BookingFilterDialog extends StatelessWidget {
  const BookingFilterDialog({Key? key, this.isUpComing, this.id})
      : super(key: key);

  final bool? isUpComing;
  final dynamic? id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            height: !isUpComing!
                ? config.AppConfig(context).appHeight(42)
                : config.AppConfig(context).appHeight(32),
            width: config.AppConfig(context).appWidth(90),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => navigatorKey.currentState!.pop(),
                      icon: SvgPicture.asset(
                        'assets/img/filter_cross.svg',
                        height: config.AppConfig(context).appHeight(2.0),
                      ),
                    )
                  ],
                ),
                Text(
                  'Filter',
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
                      horizontal: config.AppConfig(context).appWidth(5)),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text('Sort by:',
                        style: Theme.of(context).textTheme.bodyText1),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: RadioListTile<String>(
                        title: Text(
                          "Take-away",
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2
                              ?.copyWith(fontSize: 16),
                        ),
                        value: 'take_away',
                        groupValue: state.sortby,
                        onChanged: (String? value) {
                          context
                              .read<BookingsCubit>()
                              .onSortByChanged(data: value.toString());
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: RadioListTile<String>(
                        title: Text(
                          "Dine-in",
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2
                              ?.copyWith(fontSize: 16),
                        ),
                        value: "dine-in",
                        groupValue: state.sortby,
                        onChanged: (String? value) {
                          context
                              .read<BookingsCubit>()
                              .onSortByChanged(data: value.toString());
                        },
                      ),
                    ),

                    // Expanded(
                    //   flex: 1,
                    //   child: Row(
                    //     children: [
                    //       Radio(
                    //           value: "dine-in",
                    //           groupValue: state.sortby,
                    //           onChanged: (value) {
                    //             context
                    //                 .read<BookingsCubit>()
                    //                 .onSortByChanged(data: value.toString());
                    //           }),
                    //       Text("Dine-in")
                    //     ],
                    //   ),
                    // )
                  ],
                ),
                !isUpComing!
                    ? SizedBox(
                        height: config.AppConfig(context).appHeight(1),
                      )
                    : Container(),
                !isUpComing!
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: config.AppConfig(context).appWidth(5)),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text('Status:',
                              style: Theme.of(context).textTheme.bodyText1),
                        ),
                      )
                    : Container(),
                !isUpComing!
                    ? Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: RadioListTile<String>(
                              title: Text(
                                'Completed',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    ?.copyWith(fontSize: 16),
                              ),
                              value: '1',
                              groupValue: state.status,
                              onChanged: (String? value) {
                                context
                                    .read<BookingsCubit>()
                                    .onStatusChanged(data: value.toString());
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: RadioListTile<String>(
                              title: Text(
                                'Declined',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    ?.copyWith(fontSize: 16),
                              ),
                              value: '0',
                              groupValue: state.status,
                              onChanged: (String? value) {
                                context
                                    .read<BookingsCubit>()
                                    .onStatusChanged(data: value.toString());
                              },
                            ),
                          )
                        ],
                      )
                    : Container(),
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
                              color: Color(0xffE9E9E9)),
                          child: MaterialButton(
                              child: Text(
                                'CLEAR',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    ?.copyWith(fontSize: 13),
                              ),
                              height: config.AppConfig(context).appHeight(6),
                              minWidth: config.AppConfig(context).appWidth(100),
                              onPressed: () {
                                context
                                    .read<BookingsCubit>()
                                    .onStatusChanged(data: '');
                                context
                                    .read<BookingsCubit>()
                                    .onSortByChanged(data: '');

                                if (isUpComing!) {
                                  context
                                      .read<BookingsCubit>()
                                      .getUpcomingBookings();
                                } else {
                                  context.read<BookingsCubit>().getBookings();
                                }

                                navigatorKey.currentState!.pop();
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
                              color: Theme.of(context).primaryColor),
                          child: MaterialButton(
                              child: Text(
                                'APPLY',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    ?.copyWith(
                                        fontSize: 13, color: Colors.white),
                              ),
                              height: config.AppConfig(context).appHeight(6),
                              minWidth: config.AppConfig(context).appWidth(100),
                              onPressed: () {
                                if (isUpComing!) {
                                  context
                                      .read<BookingsCubit>()
                                      .getUpcomingBookings();
                                } else {
                                  context.read<BookingsCubit>().getBookings();
                                }
                                navigatorKey.currentState!.pop();
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(4),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
