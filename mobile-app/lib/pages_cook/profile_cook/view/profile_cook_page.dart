import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/view/mikitchn_view.dart';
import 'package:mitabl_user/pages_cook/profile_cook/view/personal_view.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class ProfileCookPage extends StatefulWidget {
  const ProfileCookPage({super.key});

  @override
  State<ProfileCookPage> createState() => _ProfileCookPageState();
}

class _ProfileCookPageState extends State<ProfileCookPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    _tabController.addListener(() {
      context.read<ProfileCookCubit>().onTabChanged(
        index: _tabController.index,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Heading ──
            const Padding(
              padding: EdgeInsets.only(
                left: MitablSpacing.pagePadding,
                top: 24,
                bottom: 16,
              ),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: MitablColors.onSurface,
                ),
              ),
            ),

            // ── Segmented tab control ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MitablSpacing.pagePadding,
              ),
              child: BlocBuilder<ProfileCookCubit, ProfileCookState>(
                builder: (context, state) {
                  return Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MitablRadius.pill),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: MitablColors.primary,
                        borderRadius:
                            BorderRadius.circular(MitablRadius.pill),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: MitablColors.onPrimary,
                      unselectedLabelColor: MitablColors.onSurface,
                      labelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      splashBorderRadius:
                          BorderRadius.circular(MitablRadius.pill),
                      tabs: const [
                        Tab(text: 'Personal View'),
                        Tab(text: 'mikitchn'),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [PersonalTabView(), MikitchnTabView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
