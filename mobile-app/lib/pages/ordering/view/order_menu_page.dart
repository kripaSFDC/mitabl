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
  bool _isFavoriteKitchen = false;

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
          backgroundColor: const Color(0xFFFFFFFF), // background-light
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
            isFavoriteKitchen: _isFavoriteKitchen,
            onToggleFavorite: () {
              setState(() {
                _isFavoriteKitchen = !_isFavoriteKitchen;
              });
            },
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
    required this.isFavoriteKitchen,
    required this.onToggleFavorite,
  });

  final OrderKitchenSummary kitchen;
  final OrderSessionController session;
  final bool isFavoriteKitchen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final imagePath = kitchen.images.isNotEmpty ? kitchen.images.first : null;
    final imageBaseUrl = GlobalConfiguration().getValue<String>(
      'image_base_url',
    );

    return CustomScrollView(
      slivers: [
        // Hero image h-[320px] with gradient overlay and back/heart buttons
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Hero image
              SizedBox(
                height: 320,
                width: double.infinity,
                child: imagePath == null
                    ? Container(
                        color: const Color(0xFFE2E8F0), // slate-200
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
                        height: 320,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFE2E8F0),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFE2E8F0),
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
              ),
              // Gradient overlay from-black/50 to-transparent
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.4],
                      colors: [
                        Color(0x80000000), // black/50
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Back + Heart buttons
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Heart (favorite) button
                    GestureDetector(
                      onTap: () {
                        onToggleFavorite();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavoriteKitchen
                                  ? 'Kitchen saved to favourites.'
                                  : 'Kitchen removed from favourites.',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isFavoriteKitchen
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sliding content surface: -mt-10 rounded-t-xl bg-white
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar & Basic Info
                  Container(
                    padding: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFF1F5F9), // slate-100
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Overlapping Avatar: 80px centered, -mt-10, border-4 white
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const ClipOval(
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: 36,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Negative margin compensation
                        const SizedBox(height: 0),
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Column(
                            children: [
                              // Kitchen name centered
                              Text(
                                kitchen.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A), // slate-900
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Rating row centered
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Color(0xFFEA580C), // primary filled
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    kitchen.rating?.toStringAsFixed(1) ?? '--',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B), // slate-800
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(120 reviews)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569), // slate-600
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '\u00B7',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '1.2 mi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              // Description italic centered in quotes
                              if ((kitchen.description ?? '').trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 280),
                                    child: Text(
                                      '"${kitchen.description!}"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF64748B), // slate-500
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error message
                  if ((session.errorMessage ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _displayError(session.errorMessage!),
                        style: const TextStyle(
                          fontSize: 13,
                          color: MitablColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Tab bar: rounded-full bg-background-light with white active pill
        SliverPersistentHeader(
          pinned: true,
          delegate: _SegmentedControlDelegate(
            child: Container(
              color: Colors.white.withValues(alpha: 0.95),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const _SegmentedTabBar(),
            ),
          ),
        ),

        // Menu content
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -40),
            child: _MenuTab(session: session),
          ),
        ),
      ],
    );
  }
}

class _SegmentedTabBar extends StatefulWidget {
  const _SegmentedTabBar();

  @override
  State<_SegmentedTabBar> createState() => _SegmentedTabBarState();
}

class _SegmentedTabBarState extends State<_SegmentedTabBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // background-light
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTab('Menu', 0),
          _buildTab('About', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = index);
          DefaultTabController.of(context).animateTo(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A) // slate-900
                    : const Color(0xFF64748B), // slate-500
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedControlDelegate extends SliverPersistentHeaderDelegate {
  _SegmentedControlDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SegmentedControlDelegate oldDelegate) => false;
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    if (session.isRefreshingMenu) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        session.totalItems > 0 ? 100 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Specials Today" section header
          const Text(
            'Specials Today',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A), // slate-900
            ),
          ),
          const SizedBox(height: 24),

          // Menu items
          ...List.generate(session.menuItems.length, (index) {
            final item = session.menuItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: MenuItemTile(
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
              ),
            );
          }),
        ],
      ),
    );
  }
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
