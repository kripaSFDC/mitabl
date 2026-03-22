import 'package:flutter/material.dart';
import 'package:mitabl_user/pages/home/view/home_page.dart';
import 'package:mitabl_user/pages/miorders/view/miorders_page.dart';
import 'package:mitabl_user/pages/profile_foodie/view/profile_foodie_page.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      _buildOrdersPage(),
      const ProfileFoodiePage(),
    ];
  }

  Widget _buildOrdersPage() {
    return const MiOrdersPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: MitablBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }
}
