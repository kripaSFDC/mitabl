import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

class PersonalTabView extends StatefulWidget {
  const PersonalTabView({Key? key}) : super(key: key);

  @override
  State<PersonalTabView> createState() => _PersonalTabViewState();
}

class _PersonalTabViewState extends State<PersonalTabView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: config.AppConfig(context).appHeight(3),
            ),
            CachedNetworkImage(
              imageUrl:
                  "${GlobalConfiguration().getValue<String>('base_url')}/${state.cookProfile != null ? state.cookProfile!.data!.avatar : ''}",
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
              errorWidget: (context, url, error) => Container(
                  height: config.AppConfig(context).appWidth(18),
                  width: config.AppConfig(context).appWidth(18),
                  padding:
                      EdgeInsets.all(config.AppConfig(context).appWidth(3)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: config.AppConfig(context).appWidth(8),
                  )),
              imageBuilder: (context, imageProvider) => Container(
                height: config.AppConfig(context).appWidth(18),
                width: config.AppConfig(context).appWidth(18),
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(1),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.firstName : ''} ${state.cookProfile != null ? state.cookProfile!.data!.lastName : ''}',
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(5),
                      fontWeight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(1),
                ),
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.email : ''}',
                  style: GoogleFonts.gothicA1(
                      color: Color(0xffAEAEAE),
                      fontSize: config.AppConfig(context).appWidth(3.5),
                      fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(0.5),
                ),
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.phone : ''}',
                  style: GoogleFonts.gothicA1(
                      color: Color(0xffAEAEAE),
                      fontSize: config.AppConfig(context).appWidth(3.5),
                      fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
                Text(
                  state.cookProfile != null
                      ? state.cookProfile!.data!.description ?? ''
                      : '',
                  style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(4),
                      fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Divider(
              color: Color(0xffAEAEAE),
              thickness: 0.4,
              height: config.AppConfig(context).appHeight(5),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ListTile(
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/foodi.png',
                            height: config.AppConfig(context).appHeight(3),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'Became mifoodi',
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontSize: config.AppConfig(context).appWidth(5),
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                      trailing: Container(
                        width: config.AppConfig(context).appWidth(20),
                        child: FlutterSwitch(
                          value: false,
                          activeText: '',
                          inactiveText: '',
                          valueFontSize: config.AppConfig(context).appWidth(4),
                          width: config.AppConfig(context).appWidth(14.5),
                          height: config.AppConfig(context).appHeight(4.2),
                          inactiveColor: Theme.of(context).primaryColorDark,
                          borderRadius: 30.0,
                          showOnOff: true,
                          onToggle: (val) {},
                        ),
                      ),
                    ),
                    ListTile(
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/payments.png',
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'payments',
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontSize:
                                    config.AppConfig(context).appWidth(4.5),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    ListTile(
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/contact.png',
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'contact us',
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontSize:
                                    config.AppConfig(context).appWidth(4.5),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    ListTile(
                      onTap: () {
                        navigatorKey.currentState!.pushNamed('/SettingsCook',
                            arguments: RouteArguments(id: 'cook'));
                      },
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/setting.png',
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'settings',
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontSize:
                                    config.AppConfig(context).appWidth(4.5),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    ListTile(
                      onTap: () {
                        context.read<DashboardCookCubit>().doLogout();
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
                                  height:
                                      config.AppConfig(context).appHeight(4.5),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                widthFactor:
                                    config.AppConfig(context).appWidth(0.38),
                                child: Icon(
                                  Icons.exit_to_app,
                                  size: config.AppConfig(context).appWidth(5.5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'logout',
                            style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColorDark,
                                fontSize:
                                    config.AppConfig(context).appWidth(4.5),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
