import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// A row displaying a single order item with circular image, name, quantity
/// and price.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.item,
  });

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? item['title'] ?? 'Item').toString();
    final qty = item['quantity']?.toString() ?? '1';
    final price = item['price']?.toString() ?? '';
    final imagePath = (item['image'] ?? item['avatar'] ?? '').toString();
    final imageUrl = imagePath.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$imagePath'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Circular item image
          ClipOval(
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _defaultIcon(),
                  )
                : _defaultIcon(),
          ),
          const SizedBox(width: 12),

          // Item name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MitablColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantity
          Text(
            'x$qty',
            style: const TextStyle(
              fontSize: 13,
              color: MitablColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),

          // Price
          if (price.isNotEmpty)
            Text(
              '\$$price',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MitablColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.fastfood,
        size: 20,
        color: MitablColors.onSurfaceVariant,
      ),
    );
  }
}
