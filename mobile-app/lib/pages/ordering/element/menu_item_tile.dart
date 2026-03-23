import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Menu item row for the cook profile / menu page.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    super.key,
    required this.item,
    required this.session,
    this.onTap,
  });

  final OrderMenuItem item;
  final OrderSessionController session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.images.isNotEmpty ? item.images.first : null;
    final imageBaseUrl = GlobalConfiguration().getValue<String>(
      'image_base_url',
    );
    final quantity = session.quantityFor(item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MitablRadius.card),
      child: Container(
        padding: const EdgeInsets.all(MitablSpacing.cardPadding),
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLowest,
          borderRadius: MitablRadius.cardBorder,
          border: Border.all(
            color: MitablColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image - 72x72 square with 12px radius
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath == null
                  ? Container(
                      width: 72,
                      height: 72,
                      color: MitablColors.surfaceContainerLow,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fastfood_outlined,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: '$imageBaseUrl$imagePath',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 72,
                        height: 72,
                        color: MitablColors.surfaceContainerLow,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: MitablColors.surfaceContainerLow,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Name, description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name: 15pt, w600
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  // Description: 13pt, max 2 lines, onSurfaceVariant
                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MitablColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Dietary chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.dineInAvailable)
                        const _DietaryChip(label: 'Dine-in'),
                      if (item.takeAwayAvailable)
                        const _DietaryChip(label: 'Takeaway'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price (right-aligned, 16pt, w700, primary) and quantity counter
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price: right-aligned, 16pt, w700, primary color
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity counter: compact +/- buttons with count between
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onPressed: quantity > 0
                          ? () => session.removeItem(item)
                          : null,
                    ),
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onPressed: () => session.addItem(item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DietaryChip extends StatelessWidget {
  const _DietaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MitablColors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(MitablRadius.chipSmall),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: MitablColors.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onPressed == null
              ? MitablColors.tertiaryFixedDim
              : MitablColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? MitablColors.onSurfaceVariant
              : MitablColors.onPrimary,
        ),
      ),
    );
  }
}
