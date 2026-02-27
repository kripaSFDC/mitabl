import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/home_page/view/home_cook_page.dart';
import 'package:mitabl_user/pages_cook/menu/view/menu_page.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/view/profile_cook_page.dart';
import 'package:mitabl_user/pages_cook/requests/cubit/requests_cubit.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../pages/profile_signup_cook/cook_profile/cubit/cook_profile_cubit.dart';
import '../../requests/view/requests_page.dart';
import '../cubit/dashboard_cook_cubit.dart';

class DashBoardCookPage extends StatefulWidget {
  const DashBoardCookPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => DashBoardCookPage());
  }

  @override
  State<DashBoardCookPage> createState() => _DashBoardCookPageState();
}

class _DashBoardCookPageState extends State<DashBoardCookPage> {
  List<Widget>? pagesBottom = [
    HomePageCook(),
    MenuPage(),
    BlocProvider(
      create: (context) =>
          RequestsCubit(BookingRepository(context.read<UserRepository>())),
      child: RequestsPage(),
    ),
    ProfileCookPage(),
  ];

  @override
  void initState() {
    context.read<ProfileCookCubit>().getCookProfile();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCookCubit, DashboardCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
              body: Center(
                child: pagesBottom!.elementAt(state.selectedIndex!),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      'assets/img/bottom_dash.svg',
                      height: config.AppConfig(context).appHeight(2.5),
                      width: config.AppConfig(context).appHeight(2.5),
                      color: state.selectedIndex == 0
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorDark,
                    ),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      'assets/img/menu.svg',
                      height: config.AppConfig(context).appHeight(2.5),
                      width: config.AppConfig(context).appHeight(2.5),
                      color: state.selectedIndex == 1
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorDark,
                    ),
                    label: 'Menu',
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      'assets/img/bottom_request.svg',
                      height: config.AppConfig(context).appHeight(2.5),
                      width: config.AppConfig(context).appHeight(2.5),
                      color: state.selectedIndex == 2
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorDark,
                    ),
                    label: 'Requests',
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      'assets/img/bottom_profile.svg',
                      height: config.AppConfig(context).appHeight(2.5),
                      width: config.AppConfig(context).appHeight(2.5),
                      color: state.selectedIndex == 3
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorDark,
                    ),
                    label: 'Profile',
                  ),
                ],
                currentIndex: state.selectedIndex!,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Theme.of(context).primaryColorDark,
                unselectedLabelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: config.FontFamily().book),
                selectedLabelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: config.FontFamily().book),
                onTap: (i) {
                  context.read<DashboardCookCubit>().onTabChange(index: i);
                },
              )),
        );
      },
    );
  }
}
