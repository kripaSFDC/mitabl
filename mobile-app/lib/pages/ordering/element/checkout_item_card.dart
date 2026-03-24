import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';

/// Cart line item card for the checkout page.
/// Design: bg-surface rounded-2xl p-4 shadow-soft, image 64x64 rounded-xl,
/// VERTICAL quantity column on right (add on top, count in middle, remove on bottom).
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // surface
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3E3129).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image - 64x64 rounded-xl
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath == null
                ? Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFE5E7EB), // gray-200
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fastfood_outlined,
                      size: 24,
                      color: Color(0xFF8D7A6F),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: '$imageBaseUrl$imagePath',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5E7EB),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Item name, notes, price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF3E3129), // text-main
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${line.item.price.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D7A6F), // text-muted
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${line.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFFEF6034), // primary
                  ),
                ),
              ],
            ),
          ),

          // VERTICAL quantity column
          Container(
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE4DB).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Add button on top
                GestureDetector(
                  onTap: () => session.addItem(line.item),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 14, color: Color(0xFF3E3129)),
                    ),
                  ),
                ),
                // Count
                Text(
                  '${line.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E3129),
                  ),
                ),
                // Remove button on bottom
                GestureDetector(
                  onTap: () => session.removeItem(line.item),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.remove,
                        size: 14,
                        color: Color(0xFF3E3129),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
