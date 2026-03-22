import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Cart line item card for the checkout page.
class CheckoutItemCard extends StatelessWidget {
  const CheckoutItemCard({
    super.key,
    required this.line,
    required this.session,
  });

  final CartLineItem line;
  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final imagePath =
        line.item.images.isNotEmpty ? line.item.images.first : null;
    final imageBaseUrl = GlobalConfiguration().getValue<String>(
      'image_base_url',
    );

    return Container(
      padding: const EdgeInsets.all(MitablSpacing.cardPadding),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: MitablRadius.cardBorder,
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Circular food image
          ClipOval(
            child: imagePath == null
                ? Container(
                    width: 48,
                    height: 48,
                    color: MitablColors.surfaceContainerLow,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fastfood_outlined,
                      size: 20,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: '$imageBaseUrl$imagePath',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: MitablColors.surfaceContainerLow,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: MitablColors.surfaceContainerLow,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Item name and notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${line.item.price.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Quantity +/- and line total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onPressed: () => session.removeItem(line.item),
                  ),
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(
                        '${line.quantity}',
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
                    onPressed: () => session.addItem(line.item),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '\$${line.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: MitablColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: MitablColors.onPrimary),
      ),
    );
  }
}
