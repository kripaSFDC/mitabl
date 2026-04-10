import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Detail screen for a single food item.
/// Design: hero h-[442px], gradient to surface from bottom,
/// content card with tags, price, bento info grid, description,
/// Key Ingredients section, Kitchen Performance section.
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
              // Fixed top app bar
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Hero image h-[442px]
                    SizedBox(
                      height: 442,
                      width: double.infinity,
                      child: imagePath == null
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
                    // Gradient from surface at bottom to transparent
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.4],
                            colors: [
                              MitablColors.surface,
                              MitablColors.surface.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top app bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 64 + MediaQuery.of(context).padding.top,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                          left: 24,
                          right: 24,
                        ),
                        color: MitablColors.surface.withValues(alpha: 0.8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.transparent,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: MitablColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content card
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (item.dineInAvailable)
                                const _TagBadge(
                                  label: 'Dine-in Available',
                                  bgColor: Color(0xFFF8FAFC), // surface-container-high
                                  textColor: MitablColors.onSurfaceVariant,
                                ),
                              if (item.takeAwayAvailable)
                                const _TagBadge(
                                  label: 'Takeaway',
                                  bgColor: MitablColors.secondaryContainer,
                                  textColor: MitablColors.onSecondaryContainer,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Item name
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: MitablColors.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: MitablColors.primary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Bento info grid
                          const Row(
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  label: 'PREP TIME',
                                  value: '15-20 min',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _InfoBox(
                                  label: 'CATEGORY',
                                  value: 'Main Course',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  label: 'ORDERS',
                                  value: '124',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _InfoBoxWithIcon(
                                  label: 'RATING',
                                  value: '4.9',
                                  icon: Icons.star,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Description section
                          if ((item.description ?? '').trim().isNotEmpty) ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: MitablColors.primary,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: MitablColors.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Key Ingredients section
                          const Row(
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                color: MitablColors.primary,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Key Ingredients',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _IngredientChip(label: 'Fresh Ingredients'),
                              _IngredientChip(label: 'Homemade'),
                              _IngredientChip(label: 'Herbs'),
                              _IngredientChip(label: 'Spices'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Kitchen Performance section
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Performance note
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5E9BF)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kitchen Performance',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF364C32),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This item is a customer favorite. Consider trying it during your next order!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF364C32)
                                        .withValues(alpha: 0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Popularity stat
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  size: 30,
                                  color: MitablColors.primary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '+15%',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9A3412),
                                  ),
                                ),
                                Text(
                                  'Popularity this month',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF9A3412)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Add to cart / quantity counter
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: quantity == 0
                      ? GestureDetector(
                          onTap: () => session.addItem(item),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: MitablColors.primary,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.primary
                                      .withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _QuantityCounter(
                          quantity: quantity,
                          onAdd: () => session.addItem(item),
                          onRemove: () => session.removeItem(item),
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBoxWithIcon extends StatelessWidget {
  const _InfoBoxWithIcon({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: MitablColors.primary),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB9CDA4).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF431407), // on-tertiary-fixed
        ),
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
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
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
