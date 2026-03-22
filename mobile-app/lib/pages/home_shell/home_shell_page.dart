import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/pages/home/view/home_page.dart';
import 'package:mitabl_user/pages/miorders/view/miorders_page.dart';
import 'package:mitabl_user/pages/profile_foodie/view/profile_foodie_page.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/home_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/mitabl_bottom_nav.dart';

/// Wraps the foodie experience with a persistent bottom navigation bar.
/// Tabs: Discovery | Orders | Profile
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const HomeShellPage(),
    );
  }

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;

  static const _navItems = [
    MitablNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discovery',
    ),
    MitablNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Orders',
    ),
    MitablNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(context),
          const MiOrdersPage(),
          const ProfileFoodiePage(),
        ],
      ),
      bottomNavigationBar: MitablBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }

  /// Wraps HomePage with the same providers that HomePage.route() uses.
  Widget _buildHomePage(BuildContext context) {
    final userRepo = context.read<UserRepository>();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => HomeRepository(
            httpClient: userRepo.httpClient,
          ),
          dispose: (repository) => repository.dispose(),
        ),
        RepositoryProvider(
          create: (_) => CookRepository(
            userRepo,
            httpClient: userRepo.httpClient,
          ),
          dispose: (repository) => repository.dispose(),
        ),
      ],
      child: BlocProvider(
        create: (ctx) => HomeCubit(
          repo: userRepo,
          homeRepository: ctx.read<HomeRepository>(),
          cookRepository: ctx.read<CookRepository>(),
        ),
        child: const HomePage(),
      ),
    );
  }
}
