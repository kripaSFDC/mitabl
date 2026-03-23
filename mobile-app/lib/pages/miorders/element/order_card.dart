import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';


/// A card widget displaying an order summary with kitchen info, date,
/// status chip, total, and action buttons.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.index,
    this.onTap,
    this.onCancel,
    this.isCancelling = false,
  });

  final Map<String, dynamic> order;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final kitchen = order['mikitchn'];
    final kitchenName = kitchen is Map<String, dynamic>
        ? (kitchen['name']?.toString() ?? 'Kitchen')
        : 'Kitchen';
    final kitchenAvatar = kitchen is Map<String, dynamic>
        ? (kitchen['avatar']?.toString() ?? '')
        : '';
    final avatarUrl = kitchenAvatar.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$kitchenAvatar'
        : '';

    final orderId = order['order_id']?.toString() ??
        order['id']?.toString() ??
        '${index + 1}';
    final date = order['date']?.toString() ?? '';
    final totalPrice = order['total_price']?.toString() ?? '';
    final status = '${order['status']}';

    return MitablCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar, kitchen name, status chip
          Row(
            children: [
              // Kitchen avatar
              ClipOval(
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _defaultAvatar(),
                      )
                    : _defaultAvatar(),
              ),
              const SizedBox(width: 12),
              // Kitchen name and order date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kitchenName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),

          const SizedBox(height: 12),

          // Order number and price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#MF-$orderId',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
              if (totalPrice.isNotEmpty)
                Text(
                  '\$$totalPrice',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurface,
                    fontFamily: 'Nunito',
                  ),
                ),
            ],
          ),

          // Cancel button for requested orders
          if (_canCancel(status)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isCancelling ? null : onCancel,
                  child: Text(
                    isCancelling ? 'Cancelling...' : 'Cancel',
                    style: TextStyle(
                      color: isCancelling
                          ? MitablColors.onSurfaceVariant
                          : MitablColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.restaurant,
        color: MitablColors.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  bool _canCancel(String status) => status == '2';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      '0' || '4' => ('Cancelled', MitablColors.error),
      '1' => ('Completed', MitablColors.accent),
      '2' => ('Requested', const Color(0xFF2563EB)),
      '3' => ('Confirmed', const Color(0xFF2563EB)),
      '5' => ('In Progress', const Color(0xFFF59E0B)),
      _ => ('Unknown', MitablColors.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
