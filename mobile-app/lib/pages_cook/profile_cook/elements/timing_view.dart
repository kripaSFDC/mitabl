import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';

class TimingViewDialog extends StatelessWidget {
  TimingViewDialog({super.key});

  final DateTime nowDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCookCubit, ProfileCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(config.AppConfig(context).appWidth(5)))),
          child: Container(
            height: config.AppConfig(context).appHeight(70),
            width: config.AppConfig(context).appWidth(90),
            padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(2),
                right: config.AppConfig(context).appWidth(2)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: config.AppConfig(context).appHeight(8),
                ),
                Text(
                  'mikitchn Timing',
                  style: GoogleFonts.gothicA1(
                      fontSize: config.AppConfig(context).appWidth(6),
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Day',
                        style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColor,
                            fontSize: config.AppConfig(context).appWidth(4),
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 1,
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
                    SizedBox(
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
                                  child: Row(
                                    children: [
                                      Text(
                                        state.daysTiming[index].day.toString(),
                                        style: TextStyle(
                                          fontSize: config
                                              .AppConfig(context)
                                              .appWidth(4),
                                        ),
                                      ),
                                      Switch(
                                        value: state.daysTiming[index].isOn!,
                                        onChanged: (val) {},
                                      ),
                                    ],
                                  ),
                                ),
                                // Spacer(),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(2),
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
                                          onTap: () {},
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                left: config.AppConfig(context)
                                                    .appWidth(3),
                                                right: config.AppConfig(context)
                                                    .appWidth(3),
                                                top: config.AppConfig(context)
                                                    .appWidth(1),
                                                bottom:
                                                    config.AppConfig(context)
                                                        .appWidth(1)),
                                            decoration: BoxDecoration(
                                                color: const Color(0xffF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Text(
                                              ' ${state.daysTiming[index].timing!.startTime!} ',
                                              // '9:00',
                                              style: GoogleFonts.gothicA1(
                                                  color: Theme.of(context)
                                                      .primaryColorDark,
                                                  fontSize:
                                                      config.AppConfig(context)
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
                                            fontSize: config.AppConfig(context)
                                                .appWidth(4)),
                                      ),
                                      SizedBox(
                                        width: config.AppConfig(context)
                                            .appWidth(1),
                                      ),
                                      InkWell(
                                          onTap: () {},
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                left: config.AppConfig(context)
                                                    .appWidth(3),
                                                right: config.AppConfig(context)
                                                    .appWidth(3),
                                                top: config.AppConfig(context)
                                                    .appWidth(1),
                                                bottom:
                                                    config.AppConfig(context)
                                                        .appWidth(1)),
                                            decoration: BoxDecoration(
                                                color: const Color(0xffF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Text(
                                              ' ${state.daysTiming[index].timing!.endTime!} ',
                                              style: GoogleFonts.gothicA1(
                                                  color: Theme.of(context)
                                                      .primaryColorDark,
                                                  fontSize:
                                                      config.AppConfig(context)
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


                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
