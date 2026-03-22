import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

/// Detail screen for a single food item with add-to-cart.
class MenuItemDetailPage extends StatelessWidget {
  const MenuItemDetailPage({
    super.key,
    required this.item,
    required this.session,
  });

  final OrderMenuItem item;
  final OrderSessionController session;

  static Route route({required RouteArguments routeArguments}) {
    final routeData = routeArguments.data;
    if (routeData is! MenuItemDetailRouteData) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(
            child: Text('Missing route arguments for /MenuItemDetail'),
          ),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/MenuItemDetail'),
      builder: (_) => MenuItemDetailPage(
        item: routeData.item,
        session: routeData.session,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final imagePath = item.images.isNotEmpty ? item.images.first : null;
        final imageBaseUrl = GlobalConfiguration().getValue<String>(
          'image_base_url',
        );
        final quantity = session.quantityFor(item);

        return Scaffold(
          backgroundColor: MitablColors.surface,
          body: CustomScrollView(
            slivers: [
              // Hero image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: MitablColors.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor:
                        MitablColors.surface.withValues(alpha: 0.85),
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
                            Icons.fastfood_outlined,
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
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),

              // Body content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Info row: prep time placeholder, dietary tags
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          const _InfoTag(
                            icon: Icons.schedule_outlined,
                            label: '15-20 min',
                          ),
                          if (item.dineInAvailable)
                            const _InfoTag(
                              icon: Icons.table_restaurant_outlined,
                              label: 'Dine-in',
                            ),
                          if (item.takeAwayAvailable)
                            const _InfoTag(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Takeaway',
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if ((item.description ?? '').trim().isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Add to cart / quantity counter
                      if (quantity == 0)
                        MitablButton(
                          label: 'Add to Cart',
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: MitablColors.onPrimary,
                            size: 20,
                          ),
                          onPressed: () => session.addItem(item),
                        )
                      else
                        _QuantityCounter(
                          quantity: quantity,
                          onAdd: () => session.addItem(item),
                          onRemove: () => session.removeItem(item),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: MitablColors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityCounter extends StatelessWidget {
  const _QuantityCounter({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove, color: MitablColors.primary),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MitablColors.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: MitablColors.primary),
          ),
        ],
      ),
    );
  }
}
