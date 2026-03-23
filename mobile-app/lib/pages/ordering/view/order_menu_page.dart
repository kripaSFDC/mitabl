import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/element/floating_cart_bar.dart';
import 'package:mitabl_user/pages/ordering/element/menu_item_tile.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/repos/ordering_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class OrderMenuPage extends StatelessWidget {
  const OrderMenuPage({super.key});

  static Route route({required RouteArguments routeArguments}) {
    final routeData = routeArguments.data;
    if (routeData is! OrderRouteData || routeData.kitchenId == null) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(child: Text('Missing route arguments for /OrderMenu')),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderMenu'),
      builder: (context) {
        final userRepository = context.read<UserRepository>();
        final orderingRepository = OrderingRepository(
          userRepository,
          httpClient: userRepository.httpClient,
        );
        return _OrderMenuFlow(
          kitchenId: routeData.kitchenId!,
          repository: orderingRepository,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _OrderMenuFlow extends StatefulWidget {
  const _OrderMenuFlow({required this.kitchenId, required this.repository});

  final int kitchenId;
  final OrderingRepository repository;

  @override
  State<_OrderMenuFlow> createState() => _OrderMenuFlowState();
}

class _OrderMenuFlowState extends State<_OrderMenuFlow> {
  late final OrderSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = OrderSessionController(
      repository: widget.repository,
      kitchenId: widget.kitchenId,
    )..load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: MitablColors.surface,
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_session.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_session.errorMessage != null && _session.kitchen == null) {
      return _LoadError(
        message: _displayError(_session.errorMessage!),
        onRetry: _session.load,
      );
    }

    final kitchen = _session.kitchen;
    if (kitchen == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: _MenuContent(
            kitchen: kitchen,
            session: _session,
          ),
        ),
        FloatingCartBar(session: _session),
      ],
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.kitchen,
    required this.session,
  });

  final OrderKitchenSummary kitchen;
  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final imagePath = kitchen.images.isNotEmpty ? kitchen.images.first : null;
    final imageBaseUrl = GlobalConfiguration().getValue<String>(
      'image_base_url',
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: MitablColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: MitablColors.surface.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: MitablColors.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imagePath == null
                  ? Container(
                      color: MitablColors.surfaceContainerLow,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: '$imageBaseUrl$imagePath',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: MitablColors.surfaceContainerLow,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: MitablColors.surfaceContainerLow,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
            ),
          ),
          // Cook avatar overlapping hero image bottom-left
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MitablSpacing.pagePadding,
                    12,
                    MitablSpacing.pagePadding,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cook / kitchen name
                      Padding(
                        padding: const EdgeInsets.only(left: 60),
                        child: Text(
                          kitchen.name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating row: star + "4.9" + "(170+ reviews)"
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            kitchen.rating?.toStringAsFixed(1) ?? '--',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(170+ reviews)',
                            style: TextStyle(
                              fontSize: 13,
                              color: MitablColors.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),

                      // Description text below rating
                      if ((kitchen.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          kitchen.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],

                      if ((session.errorMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _displayError(session.errorMessage!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: MitablColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Cook avatar circle overlapping hero (48px, offset -24px)
                Positioned(
                  top: -24,
                  left: MitablSpacing.pagePadding,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MitablColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MitablColors.surface,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 20,
                      color: MitablColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              const TabBar(
                labelColor: MitablColors.primary,
                unselectedLabelColor: MitablColors.onSurfaceVariant,
                indicatorColor: MitablColors.primary,
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(text: 'Menu'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        children: [
          // Menu tab
          _MenuTab(session: session),
          // About tab
          _AboutTab(kitchen: kitchen),
        ],
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    if (session.isRefreshingMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    if (session.menuItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(MitablSpacing.pagePadding),
          child: Text(
            'No menu items are available for this kitchen yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        MitablSpacing.pagePadding,
        MitablSpacing.pagePadding,
        MitablSpacing.pagePadding,
        session.totalItems > 0 ? 100 : MitablSpacing.pagePadding,
      ),
      itemCount: session.menuItems.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: MitablSpacing.listItem),
      itemBuilder: (context, index) {
        final item = session.menuItems[index];
        return MenuItemTile(
          item: item,
          session: session,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/MenuItemDetail',
              arguments: RouteArguments(
                data: MenuItemDetailRouteData(
                  item: item,
                  session: session,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.kitchen});

  final OrderKitchenSummary kitchen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(MitablSpacing.pagePadding),
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MitablColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (kitchen.description ?? '').trim().isNotEmpty
              ? kitchen.description!
              : 'No description available.',
          style: const TextStyle(
            fontSize: 14,
            color: MitablColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Address',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MitablColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: MitablColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                kitchen.address.isNotEmpty
                    ? kitchen.address
                    : 'Address not available.',
                style: const TextStyle(
                  fontSize: 14,
                  color: MitablColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Service info
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (kitchen.dineInAvailable)
              const _AboutInfoChip(
                icon: Icons.table_restaurant_outlined,
                label: 'Dine in available',
              ),
            if (kitchen.takeAwayAvailable)
              const _AboutInfoChip(
                icon: Icons.shopping_bag_outlined,
                label: 'Take away available',
              ),
          ],
        ),
      ],
    );
  }
}

class _AboutInfoChip extends StatelessWidget {
  const _AboutInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MitablColors.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MitablColors.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MitablColors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: MitablColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayError(String raw) {
  const marker = 'message: ';
  final markerIndex = raw.indexOf(marker);
  if (markerIndex == -1) {
    return raw;
  }

  final start = markerIndex + marker.length;
  final trimmed = raw.substring(start).trimRight();
  return trimmed.endsWith(')')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
