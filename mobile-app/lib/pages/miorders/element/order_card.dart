import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Order card matching the HTML design:
/// Active: bg-surface-container-lowest rounded-[20px] p-5, status tag top-right,
///   image 80x80 rounded-[16px], TOTAL AMOUNT label, Track Order button.
/// Completed: bg-surface-container-low, image 64x64, Order Details + Reorder buttons.
/// Cancelled: bg-surface-container-low opacity-80, grayscale image, View Receipt button.
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

    // Try cook avatar first, then first kitchen image, then kitchen-level avatar
    String kitchenAvatar = '';
    if (kitchen is Map<String, dynamic>) {
      final cock = kitchen['cock'];
      if (cock is Map<String, dynamic>) {
        kitchenAvatar = (cock['avatar'] ?? '').toString();
      }
      if (kitchenAvatar.isEmpty) {
        final images = kitchen['images'];
        if (images is List && images.isNotEmpty) {
          final firstImage = images.first;
          if (firstImage is Map) {
            kitchenAvatar = (firstImage['path'] ?? '').toString();
          } else if (firstImage is String) {
            kitchenAvatar = firstImage;
          }
        }
      }
      if (kitchenAvatar.isEmpty) {
        kitchenAvatar = (kitchen['avatar'] ?? '').toString();
      }
    }
    final avatarUrl = kitchenAvatar.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$kitchenAvatar'
        : '';

    final date = order['date']?.toString() ?? '';
    final totalPrice = order['total_price']?.toString() ?? '';
    final status = '${order['status']}';
    final isActive = status == '2' || status == '3' || status == '5';
    final isCancelled = status == '0' || status == '4';
    final isCompleted = status == '1';

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isCancelled ? 0.8 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive
                ? MitablColors.surfaceContainerLowest
                : MitablColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: image + kitchen info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kitchen image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColorFiltered(
                          colorFilter: isCancelled
                              ? const ColorFilter.mode(
                                  Colors.grey, BlendMode.saturation)
                              : const ColorFilter.mode(
                                  Colors.transparent, BlendMode.multiply),
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: isActive ? 80 : 64,
                                  height: isActive ? 80 : 64,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _defaultAvatar(isActive ? 80 : 64),
                                )
                              : _defaultAvatar(isActive ? 80 : 64),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Kitchen name + date + status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kitchenName,
                              style: TextStyle(
                                fontSize: isActive ? 20 : 18,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                                fontFamily: 'PlusJakartaSans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (date.isNotEmpty) ...[
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isActive) ...[
                              const SizedBox(height: 4),
                              _CompactStatusBadge(
                                status: status,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Price for non-active orders (top-right)
                      if (!isActive && totalPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$$totalPrice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isCancelled
                                ? MitablColors.onSurfaceVariant
                                : MitablColors.onSurface,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Active order: Total Amount section with Track Order button
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: MitablColors.outlineVariant
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Total Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL AMOUNT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (totalPrice.isNotEmpty)
                                Text(
                                  '\$$totalPrice',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: MitablColors.primary,
                                    fontFamily: 'PlusJakartaSans',
                                  ),
                                ),
                            ],
                          ),
                          // Track Order button
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: MitablColors.primary,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: MitablColors.primary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Track Order',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Completed order: Order Details + Reorder buttons
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: MitablColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Center(
                                child: Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Reorder action
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reorder coming soon'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: MitablColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Center(
                                child: Text(
                                  'Reorder',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Cancelled order: View Receipt button
                  if (isCancelled) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: MitablColors.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'View Receipt',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

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

              // Status tag top-right corner (active orders only)
              if (isActive)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: MitablColors.secondaryContainer,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: MitablColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.restaurant,
        color: MitablColors.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  bool _canCancel(String status) => status == '2';

  String _statusLabel(String status) {
    return switch (status) {
      '2' => 'REQUESTED',
      '3' => 'CONFIRMED',
      '5' => 'IN PROGRESS',
      _ => 'ACTIVE',
    };
  }
}

class _CompactStatusBadge extends StatelessWidget {
  const _CompactStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      '0' || '4' => (
          'Cancelled',
          MitablColors.error,
          Icons.cancel,
        ),
      '1' => (
          'Completed',
          const Color(0xFF4D6548), // secondary
          Icons.check_circle,
        ),
      _ => (
          'Unknown',
          MitablColors.onSurfaceVariant,
          Icons.help_outline,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
