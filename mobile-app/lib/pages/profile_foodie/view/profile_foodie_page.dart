import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:formz/formz.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class ProfileFoodiePage extends StatefulWidget {
  const ProfileFoodiePage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => ProfileFoodiePage());
    // );
  }

  @override
  _ProfileFoodiePageState createState() => _ProfileFoodiePageState();
}

class _ProfileFoodiePageState extends State<ProfileFoodiePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
      builder: (context, state) {
        return SafeArea(
            child: Scaffold(
          appBar: AppBar(
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: config.AppConfig(context).appWidth(5),
                color: Theme.of(context).primaryColorDark,
              ),
              onPressed: () => {navigatorKey.currentState!.pop()},
            ),
          ),
          backgroundColor: Colors.white,
          body: Padding(
              padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(3),
                right: config.AppConfig(context).appWidth(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.firstName : ''} ${state.foodieProfile != null ? state.foodieProfile!.data!.lastName : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.gothicA1(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      config.AppConfig(context).appWidth(5)),
                            ),
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.email : ''}',
                              style: GoogleFonts.gothicA1(
                                  color: Color(0xffAEAEAE),
                                  fontSize:
                                      config.AppConfig(context).appWidth(3.5),
                                  fontWeight: FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.phone : ''}',
                              style: GoogleFonts.gothicA1(
                                  color: Color(0xffAEAEAE),
                                  fontSize:
                                      config.AppConfig(context).appWidth(3.5),
                                  fontWeight: FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl:
                            "${GlobalConfiguration().getValue<String>('base_url')}/${state.foodieProfile != null ? state.foodieProfile!.data!.avatar : ''}",
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Container(
                            height: config.AppConfig(context).appWidth(18),
                            width: config.AppConfig(context).appWidth(18),
                            padding: EdgeInsets.all(
                                config.AppConfig(context).appWidth(3)),
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
                    ],
                  ),
                  SizedBox(
                    height: config.AppConfig(context).appHeight(1),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    constraints: BoxConstraints(
                      minHeight: config.AppConfig(context).appHeight(8.0),
                      minWidth: double.infinity,
                    ),
                    child: Text(
                      state.foodieProfile != null
                          ? state.foodieProfile!.data!.description ?? ''
                          : '',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4),
                          fontWeight: FontWeight.normal),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ListTile(
                    minVerticalPadding: 0,
                    contentPadding: EdgeInsets.zero,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/img/cook.png',
                          height: config.AppConfig(context).appHeight(3),
                        ),
                        SizedBox(
                          width: config.AppConfig(context).appWidth(4),
                        ),
                        Text(
                          'Became micook',
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
                  Divider(
                    color: Color(0xffAEAEAE),
                    thickness: 0.4,
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
                                  'assets/img/miorders.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'miorders',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
                                  'assets/img/favourites.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'favourites',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
                                  'assets/img/payments.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'payments',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
                                  'assets/img/faq.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'faq',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'contact us',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
                                  'assets/img/my_partners.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'my partners',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
                                      fontWeight: FontWeight.w400),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              navigatorKey.currentState!.pushNamed(
                                  '/SettingsCook',
                                  arguments: RouteArguments(id: 'foodie'));
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/setting.png',
                                  height:
                                      config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'settings',
                                  style: GoogleFonts.gothicA1(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(context)
                                          .appWidth(4.5),
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
              )),
        ));
      },
    );
  }
}
