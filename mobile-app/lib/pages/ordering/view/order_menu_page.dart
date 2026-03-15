import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/repos/ordering_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

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
  const _OrderMenuFlow({
    required this.kitchenId,
    required this.repository,
  });

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
        final kitchen = _session.kitchen;
        final title = kitchen?.name ?? 'Kitchen menu';
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          floatingActionButton: _session.totalItems > 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/OrderCart',
                      arguments: RouteArguments(
                        data: OrderRouteData(session: _session),
                      ),
                    );
                  },
                  label: Text('Cart (${_session.totalItems})'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                )
              : null,
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _KitchenHero(kitchen: kitchen),
        const SizedBox(height: 16),
        if ((_session.errorMessage ?? '').isNotEmpty) ...[
          Text(
            _displayError(_session.errorMessage!),
            style: GoogleFonts.gothicA1(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ServiceTypeSelector(session: _session),
        const SizedBox(height: 16),
        Text(
          'Menu',
          style: GoogleFonts.gothicA1(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_session.isRefreshingMenu) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        if (_session.menuItems.isEmpty)
          const Text('No menu items are available for this kitchen yet.'),
        ..._session.menuItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MenuItemCard(
              item: item,
              quantity: _session.quantityFor(item),
              available: _session.isItemAvailable(item),
              onAdd: () => _session.addItem(item),
              onRemove: () => _session.removeItem(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _KitchenHero extends StatelessWidget {
  const _KitchenHero({required this.kitchen});

  final OrderKitchenSummary kitchen;

  @override
  Widget build(BuildContext context) {
    final imagePath = kitchen.images.isNotEmpty ? kitchen.images.first : null;
    final imageBaseUrl =
        GlobalConfiguration().getValue<String>('image_base_url');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imagePath == null
                ? Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu, size: 48),
                  )
                : CachedNetworkImage(
                    imageUrl: '$imageBaseUrl$imagePath',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kitchen.name,
                  style: GoogleFonts.gothicA1(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kitchen.address,
                  style: GoogleFonts.gothicA1(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if ((kitchen.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    kitchen.description!,
                    style: GoogleFonts.gothicA1(fontSize: 14, height: 1.45),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (kitchen.rating != null)
                      _InfoChip(
                        icon: Icons.star_border,
                        label: kitchen.rating!.toStringAsFixed(1),
                      ),
                    if (kitchen.dineInAvailable)
                      const _InfoChip(
                        icon: Icons.table_restaurant_outlined,
                        label: 'Dine in',
                      ),
                    if (kitchen.takeAwayAvailable)
                      const _InfoChip(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Take away',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTypeSelector extends StatelessWidget {
  const _ServiceTypeSelector({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final kitchen = session.kitchen;
    if (kitchen == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service type',
          style: GoogleFonts.gothicA1(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            if (kitchen.dineInAvailable)
              ChoiceChip(
                label: const Text('Dine in'),
                selected: session.serviceType == OrderServiceType.dineIn,
                onSelected: (_) =>
                    session.selectServiceType(OrderServiceType.dineIn),
              ),
            if (kitchen.takeAwayAvailable)
              ChoiceChip(
                label: const Text('Take away'),
                selected: session.serviceType == OrderServiceType.takeAway,
                onSelected: (_) =>
                    session.selectServiceType(OrderServiceType.takeAway),
              ),
          ],
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.available,
    required this.onAdd,
    required this.onRemove,
  });

  final OrderMenuItem item;
  final int quantity;
  final bool available;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.images.isNotEmpty ? item.images.first : null;
    final imageBaseUrl =
        GlobalConfiguration().getValue<String>('image_base_url');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: available ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imagePath == null
                ? Container(
                    width: 84,
                    height: 84,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.fastfood_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: '$imageBaseUrl$imagePath',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.gothicA1(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.gothicA1(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gothicA1(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (!available)
                  Text(
                    'Unavailable for the selected service type',
                    style: GoogleFonts.gothicA1(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onPressed: quantity > 0 ? onRemove : null,
                      ),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            '$quantity',
                            style: GoogleFonts.gothicA1(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onPressed: onAdd,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onPressed == null
              ? Colors.grey.shade200
              : Theme.of(context).primaryColorDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : Colors.white,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.gothicA1(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
  });

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
              style: GoogleFonts.gothicA1(fontSize: 15),
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
