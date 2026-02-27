import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages/profile_signup_cook/cook_profile/cubit/cook_profile_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

class TimingDialog extends StatelessWidget {
  TimingDialog({Key? key}) : super(key: key);

  DateTime? nowDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CookProfileCubit, CookProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(config.AppConfig(context).appWidth(5)))),
          child: Container(
            height: config.AppConfig(context).appHeight(80),
            width: config.AppConfig(context).appWidth(90),
            padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(2),
                right: config.AppConfig(context).appWidth(2)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text('mikitchn Timing',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            fontSize: config.AppConfig(context).appWidth(6),
                          )),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(3),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Day',
                          style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColor,
                              fontSize: config.AppConfig(context).appWidth(4),
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Time',
                          style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColor,
                              fontSize: config.AppConfig(context).appWidth(4),
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.left,
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(2),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: config.AppConfig(context).appHeight(50),
                        child: ListView.separated(
                            separatorBuilder: (context, index) {
                              return SizedBox(
                                height: config.AppConfig(context).appHeight(2),
                              );
                            },
                            itemCount: state.daysTiming.length,
                            itemBuilder: (context, index) {
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: FlutterSwitch(
                                      activeTextFontWeight:
                                          config.FontFamily().medium,
                                      inactiveTextFontWeight:
                                          config.FontFamily().medium,
                                      activeText: state.daysTiming[index].day
                                          .toString(),
                                      inactiveText: state.daysTiming[index].day
                                          .toString(),
                                      value: state.daysTiming[index].isOn!,
                                      valueFontSize:
                                          config.AppConfig(context).appWidth(4),
                                      width: config.AppConfig(context)
                                          .appWidth(20),
                                      borderRadius: 30.0,
                                      showOnOff: true,
                                      onToggle: (val) {
                                        context
                                            .read<CookProfileCubit>()
                                            .onSwitchChanged(
                                                index: index, switchValue: val);
                                      },
                                    ),
                                  ),
                                  // Spacer(),
                                  SizedBox(
                                    width:
                                        config.AppConfig(context).appWidth(2),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: config.AppConfig(context)
                                            .appWidth(10)),
                                    child: Row(
                                      // mainAxisAlignment:
                                      //     MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                            onTap: () {
                                              String date =
                                                  DateFormat('yyyy-MM-dd ')
                                                      .format(nowDate!);
                                              String datePreviousStart = date +
                                                  state.daysTiming[index]
                                                      .timing!.startTime!;
                                              print(
                                                  'startDateTime ${datePreviousStart}');
                                              DateTime startPreviousTime =
                                                  DateTime.parse(
                                                      datePreviousStart);

                                              _showDialog(
                                                  CupertinoDatePicker(
                                                    initialDateTime:
                                                        startPreviousTime /*DateTime(
                                                        nowDate!.year,
                                                        nowDate!.month,
                                                        nowDate!.day,
                                                        0,
                                                        0,
                                                        0)*/
                                                    ,
                                                    mode:
                                                        CupertinoDatePickerMode
                                                            .time,
                                                    use24hFormat: true,
                                                    onDateTimeChanged:
                                                        (DateTime newTime) {
                                                      String date = DateFormat(
                                                              'yyyy-MM-dd ')
                                                          .format(newTime);
                                                      String dateStart = date +
                                                          state
                                                              .daysTiming[index]
                                                              .timing!
                                                              .endTime!;
                                                      print(
                                                          'startDateTime ${dateStart}');
                                                      DateTime startTime =
                                                          DateTime.parse(
                                                              dateStart);

                                                      if (newTime.isBefore(
                                                          startTime)) {
                                                        context
                                                            .read<
                                                                CookProfileCubit>()
                                                            .onSwitchChanged(
                                                                index: index,
                                                                startTime: DateFormat(
                                                                        'HH:mm')
                                                                    .format(
                                                                        newTime));
                                                      }
                                                    },
                                                  ),
                                                  context);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  left:
                                                      config.AppConfig(context)
                                                          .appWidth(3),
                                                  right:
                                                      config.AppConfig(context)
                                                          .appWidth(3),
                                                  top: config.AppConfig(context)
                                                      .appWidth(1),
                                                  bottom:
                                                      config.AppConfig(context)
                                                          .appWidth(1)),
                                              decoration: BoxDecoration(
                                                  color: Color(0xffF5F5F5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text(
                                                ' ${state.daysTiming[index].timing!.startTime!} ',
                                                // '9:00',
                                                style: GoogleFonts.gothicA1(
                                                    color: Theme.of(context)
                                                        .primaryColorDark,
                                                    fontSize: config.AppConfig(
                                                            context)
                                                        .appWidth(4)),
                                              ),
                                            )),
                                        SizedBox(
                                          width: config.AppConfig(context)
                                              .appWidth(1),
                                        ),
                                        Text(
                                          'To',
                                          style: GoogleFonts.gothicA1(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontSize:
                                                  config.AppConfig(context)
                                                      .appWidth(4)),
                                        ),
                                        SizedBox(
                                          width: config.AppConfig(context)
                                              .appWidth(1),
                                        ),
                                        InkWell(
                                            onTap: () {
                                              String date =
                                                  DateFormat('yyyy-MM-dd ')
                                                      .format(nowDate!);
                                              String datePreviousEnd = date +
                                                  state.daysTiming[index]
                                                      .timing!.endTime!;
                                              print(
                                                  'startDateTime ${datePreviousEnd}');
                                              DateTime endPreviousTime =
                                                  DateTime.parse(
                                                      datePreviousEnd);

                                              _showDialog(
                                                  CupertinoDatePicker(
                                                    initialDateTime:
                                                        endPreviousTime /*DateTime(
                                                        nowDate!.year,
                                                        nowDate!.month,
                                                        nowDate!.day,
                                                        0,
                                                        0,
                                                        0)*/
                                                    ,
                                                    mode:
                                                        CupertinoDatePickerMode
                                                            .time,
                                                    use24hFormat: true,
                                                    onDateTimeChanged:
                                                        (DateTime newTime) {
                                                      String date = DateFormat(
                                                              'yyyy-MM-dd ')
                                                          .format(newTime);
                                                      String dateStart = date +
                                                          state
                                                              .daysTiming[index]
                                                              .timing!
                                                              .startTime!;
                                                      print(
                                                          'startDateTime ${dateStart}');
                                                      DateTime startTime =
                                                          DateTime.parse(
                                                              dateStart);
                                                      if (newTime
                                                          .isAfter(startTime)) {
                                                        context
                                                            .read<
                                                                CookProfileCubit>()
                                                            .onSwitchChanged(
                                                                index: index,
                                                                endTime: DateFormat(
                                                                        'HH:mm')
                                                                    .format(
                                                                        newTime));
                                                      }
                                                    },
                                                  ),
                                                  context);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  left:
                                                      config.AppConfig(context)
                                                          .appWidth(3),
                                                  right:
                                                      config.AppConfig(context)
                                                          .appWidth(3),
                                                  top: config.AppConfig(context)
                                                      .appWidth(1),
                                                  bottom:
                                                      config.AppConfig(context)
                                                          .appWidth(1)),
                                              decoration: BoxDecoration(
                                                  color: Color(0xffF5F5F5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text(
                                                ' ${state.daysTiming[index].timing!.endTime!} ',
                                                style: GoogleFonts.gothicA1(
                                                    color: Theme.of(context)
                                                        .primaryColorDark,
                                                    fontSize: config.AppConfig(
                                                            context)
                                                        .appWidth(4)),
                                              ),
                                            )),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }),
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          alignment: Alignment.center,
                          height: config.AppConfig(context).appHeight(6),
                          width: config.AppConfig(context).appWidth(40),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28.0),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor,
                                ],
                              )),
                          child: MaterialButton(
                              child: Text(
                                'Apply',
                                style: GoogleFonts.gothicA1(
                                    fontSize:
                                        config.AppConfig(context).appWidth(3.5),
                                    color: Colors.white),
                              ),
                              height: config.AppConfig(context).appHeight(6),
                              minWidth: config.AppConfig(context).appWidth(100),
                              onPressed: () {
                                context.read<CookProfileCubit>().onApplyDays();
                              }),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDialog(Widget child, BuildContext? context) {
    showCupertinoModalPopup<void>(
        context: context!,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              // The Bottom margin is provided to align the popup above the system navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: CupertinoColors.systemBackground.resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: child,
              ),
            ));
  }
}
