import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';

class SettingsCookPage extends StatefulWidget {
  const SettingsCookPage({Key? key, this.routeArguments}) : super(key: key);

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder:
          (_) => /*BlocProvider(
          create: (context) => CookProfileCubit(
              context.read<AuthenticationRepository>(), routeArguments),
          child:*/
              SettingsCookPage(routeArguments: routeArguments),
      // ));
    );
  }

  @override
  State<SettingsCookPage> createState() => _SettingsCookPageState();
}

class _SettingsCookPageState extends State<SettingsCookPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Settings',
          isFilter: false,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: Column(
            children: [
              SizedBox(
                height: config.AppConfig(context).appHeight(3),
              ),
              ListTile(
                onTap: () {
                  if (widget.routeArguments!.id == 'foodie') {
                    navigatorKey.currentState!.pushNamed('/EditProfileFoodie');
                  } else {
                    navigatorKey.currentState!.pushNamed('/ProfileCook');
                  }
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/img/background.svg',
                            height: config.AppConfig(context).appHeight(4.5),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          widthFactor: 2,
                          child: SvgPicture.asset(
                            'assets/img/edit.svg',
                            height: config.AppConfig(context).appHeight(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Edit profile',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              ListTile(
                onTap: () {
                  // navigatorKey.currentState!.pushNamed('/SettingsCook');
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/notification.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Notification',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: Container(
                  width: config.AppConfig(context).appWidth(18),
                  child: FlutterSwitch(
                    value: true,
                    activeText: '',
                    inactiveText: '',
                    valueFontSize: config.AppConfig(context).appWidth(4),
                    width: config.AppConfig(context).appWidth(13.8),
                    height: config.AppConfig(context).appHeight(3.8),
                    inactiveColor: Theme.of(context).primaryColorDark,
                    borderRadius: 30.0,
                    showOnOff: true,
                    onToggle: (val) {},
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  // navigatorKey.currentState!.pushNamed('/SettingsCook');
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/delete.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
