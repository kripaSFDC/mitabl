import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages_cook/home_page/view/home_cook_page.dart';
import 'package:mitabl_user/pages_cook/menu/view/menu_page.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/view/profile_cook_page.dart';
import 'package:mitabl_user/pages_cook/requests/cubit/requests_cubit.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/mitabl_bottom_nav.dart';

import '../../requests/view/requests_page.dart';
import '../cubit/dashboard_cook_cubit.dart';

class DashBoardCookPage extends StatefulWidget {
  const DashBoardCookPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const DashBoardCookPage());
  }

  @override
  State<DashBoardCookPage> createState() => _DashBoardCookPageState();
}

class _DashBoardCookPageState extends State<DashBoardCookPage> {
  List<Widget>? pagesBottom = [
    const HomePageCook(),
    const MenuPage(),
    BlocProvider(
      create: (context) =>
          RequestsCubit(BookingRepository(context.read<UserRepository>())),
      child: const RequestsPage(),
    ),
    const ProfileCookPage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProfileCookCubit>().getCookProfile();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCookCubit, DashboardCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Center(child: pagesBottom!.elementAt(state.selectedIndex!)),
            bottomNavigationBar: MitablBottomNav(
              currentIndex: state.selectedIndex!,
              onTap: (i) {
                context.read<DashboardCookCubit>().onTabChange(index: i);
              },
              items: const [
                MitablNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                MitablNavItem(
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu,
                  label: 'Menu',
                ),
                MitablNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Requests',
                ),
                MitablNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
