import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/profile_signup_cook/cook_profile/cubit/cook_profile_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../cubit/profile_cook_cubit.dart';
import '../elements/timing_view.dart';

class MikitchnTabView extends StatefulWidget {
  const MikitchnTabView({Key? key}) : super(key: key);

  @override
  State<MikitchnTabView> createState() => _MikitchnTabViewState();
}

class _MikitchnTabViewState extends State<MikitchnTabView> {
  PageController? controller = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCookCubit, ProfileCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProfileCookCubit>().getCookProfile();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                state.pathFiles.isNotEmpty
                    ? Container(
                        height: config.AppConfig(context).appHeight(20),
                        child: PageView.builder(
                          controller: controller,
                          onPageChanged: (page) {
                            context
                                .read<ProfileCookCubit>()
                                .onImageScroll(index: page);
                          },
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      config.AppConfig(context).appWidth(2)),
                              child: Container(
                                height: config.AppConfig(context).appHeight(20),
                                width: config.AppConfig(context).appWidth(85),
                                decoration: BoxDecoration(
                                  color: config.AppColors()
                                      .textFieldBackgroundColor(1),
                                  borderRadius: BorderRadius.circular(
                                      config.AppConfig(context).appWidth(5)),
                                ),
                                alignment: Alignment.center,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                ),
                              ),
                            );
                          },
                          itemCount: state.pathFiles.length,
                        ),
                      )
                    : Container(
                        height: config.AppConfig(context).appHeight(20),
                        decoration: BoxDecoration(
                            color:
                                config.AppColors().textFieldBackgroundColor(1),
                            borderRadius: BorderRadius.circular(
                                config.AppConfig(context).appWidth(5))),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.photo_outlined,
                          size: config.AppConfig(context).appWidth(30),
                          color: Colors.grey,
                        ),
                      ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                state.pathFiles.isNotEmpty
                    ? Container(
                        alignment: Alignment.center,
                        height: config.AppConfig(context).appHeight(5),
                        child: ListView.separated(
                          // controller: controller,
                          separatorBuilder: (context, index) {
                            return SizedBox(
                              width: config.AppConfig(context).appWidth(2),
                            );
                          },
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Container(
                              width: config.AppConfig(context).appWidth(2),
                              decoration: BoxDecoration(
                                  color: state.selectedPage == index
                                      ? Colors.blue
                                      : Colors.grey,
                                  shape: BoxShape.circle),
                            );
                          },
                          itemCount: state.pathFiles.length,
                        ),
                      )
                    : SizedBox(),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.cookProfile!.data!.kitchen!.status == '1'
                          ? 'Your account is activated.'
                          : 'Your account is inactive.',
                      style: GoogleFonts.gothicA1(
                          color: state.cookProfile!.data!.kitchen!.status == '1'
                              ? Colors.lightGreen
                              : Colors.red,
                          fontSize: config.AppConfig(context).appWidth(4)),
                    ),
                    state.cookProfile!.data!.kitchen!.status == '0'
                        ? Container(
                            height: config.AppConfig(context).appHeight(4),
                            width: config.AppConfig(context).appWidth(30),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
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
                                  'Activate',
                                  style: GoogleFonts.gothicA1(
                                      fontSize: config.AppConfig(context)
                                          .appWidth(3.5),
                                      color: Colors.white),
                                ),
                                height: config.AppConfig(context).appHeight(6),
                                minWidth:
                                    config.AppConfig(context).appWidth(100),
                                onPressed: () {}),
                          )
                        : SizedBox()
                  ],
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                Text(
                  state.cookProfile!.data!.kitchen!.name.toString(),
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(
                  color: Theme.of(context).primaryColorDark,
                  height: config.AppConfig(context).appHeight(3),
                  thickness: 0.2,
                ),
                Text(
                  state.cookProfile!.data!.kitchen!.address.toString(),
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(
                  color: Theme.of(context).primaryColorDark,
                  height: config.AppConfig(context).appHeight(3),
                  thickness: 0.2,
                ),
                Text(
                  state.cookProfile!.data!.kitchen!.phone.toString(),
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(
                  color: Theme.of(context).primaryColorDark,
                  height: config.AppConfig(context).appHeight(3),
                  thickness: 0.2,
                ),
                Text(
                  state.cookProfile!.data!.kitchen!.noOfSeats.toString(),
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(
                  color: Theme.of(context).primaryColorDark,
                  height: config.AppConfig(context).appHeight(3),
                  thickness: 0.2,
                ),
                Text(
                  state.cookProfile!.data!.kitchen!.description ?? '-',
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(
                  color: Theme.of(context).primaryColorDark,
                  height: config.AppConfig(context).appHeight(3),
                  thickness: 0.2,
                ),
                Row(
                  children: [
                    Container(
                      width: config.AppConfig(context).appWidth(45),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: config.AppColors().textFieldBackgroundColor(1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: state.cookProfile!.data!.kitchen!
                                              .dineIn ==
                                          1
                                      ? true
                                      : false,
                                  onChanged: (value) {},
                                ),
                                Text(
                                  'Dine-in',
                                  style: GoogleFonts.gothicA1(
                                      fontSize: config.AppConfig(context)
                                          .appHeight(2),
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(3),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(3),
                    ),
                    Container(
                      width: config.AppConfig(context).appWidth(45),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: config.AppColors().textFieldBackgroundColor(1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: state.cookProfile!.data!.kitchen!
                                              .takeAway ==
                                          1
                                      ? true
                                      : false,
                                  onChanged: (value) {},
                                ),
                                Text(
                                  'Takeaway',
                                  style: GoogleFonts.gothicA1(
                                      fontSize: config.AppConfig(context)
                                          .appHeight(2),
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FlutterSwitch(
                      activeText: '',
                      inactiveText: '',
                      value: state.cookProfile!.data!.kitchen!.available == 1
                          ? true
                          : false,
                      valueFontSize: config.AppConfig(context).appWidth(1),
                      width: config.AppConfig(context).appWidth(16),
                      height: config.AppConfig(context).appHeight(4),
                      borderRadius: 30.0,
                      showOnOff: true,
                      onToggle: (val) {},
                    ),
                  ],
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timings:',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    InkWell(
                      onTap: () {

                        showDialog(
                            context: context,
                            builder: (contexts) {
                              return BlocProvider.value(
                                value: context.read<ProfileCookCubit>(),
                                child: TimingViewDialog(),
                              );
                            });
                      },
                      child: Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
                // Text(
                //   'Verification Details',
                //   style: GoogleFonts.gothicA1(
                //       color: Theme.of(context).primaryColorDark,
                //       fontSize: config.AppConfig(context).appWidth(4)),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),
                // SizedBox(
                //   height: config.AppConfig(context).appHeight(3),
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       'ABN',
                //       style: GoogleFonts.gothicA1(
                //           color: Theme.of(context).primaryColorDark,
                //           fontSize: config.AppConfig(context).appWidth(4)),
                //       maxLines: 2,
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //     Text(
                //       state.cookProfile!.data!.kitchen!.abn ?? '-',
                //       style: GoogleFonts.gothicA1(
                //           color: Theme.of(context).primaryColorDark,
                //           fontSize: config.AppConfig(context).appWidth(4)),
                //       maxLines: 2,
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //   ],
                // ),
                // SizedBox(
                //   height: config.AppConfig(context).appHeight(3),
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       'Certificate Number',
                //       style: GoogleFonts.gothicA1(
                //           color: Theme.of(context).primaryColorDark,
                //           fontSize: config.AppConfig(context).appWidth(4)),
                //       maxLines: 2,
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //     Text(
                //       state.cookProfile!.data!.kitchen!.certificateNo ?? '-',
                //       style: GoogleFonts.gothicA1(
                //           color: Theme.of(context).primaryColorDark,
                //           fontSize: config.AppConfig(context).appWidth(4)),
                //       maxLines: 2,
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //   ],
                // ),
                // SizedBox(
                //   height: config.AppConfig(context).appHeight(3),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer reviews',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    InkWell(
                      onTap: () {
                        navigatorKey.currentState!.pushNamed(
                            '/CustomerReviewPage',
                            arguments: RouteArguments(
                                kitchen: state.cookProfile!.data!.kitchen!));
                      },
                      child: SvgPicture.asset(
                        'assets/img/next.svg',
                        height: config.AppConfig(context).appHeight(3),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    alignment: Alignment.center,
                    height: config.AppConfig(context).appHeight(6),
                    width: config.AppConfig(context).appWidth(80),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
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
                          'Edit Info',
                          style: GoogleFonts.gothicA1(
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: Colors.white),
                        ),
                        height: config.AppConfig(context).appHeight(6),
                        minWidth: config.AppConfig(context).appWidth(100),
                        onPressed: () {
                          navigatorKey.currentState!
                              .pushNamed('/EditKitchenProfile',
                                  arguments: RouteArguments(
                                      kitchen:
                                          state.cookProfile!.data!.kitchen!))
                              .then((value) {
                            if (value != null && value == true) {
                              context.read<ProfileCookCubit>().getCookProfile();
                            }
                          });
                        }),
                  ),
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
