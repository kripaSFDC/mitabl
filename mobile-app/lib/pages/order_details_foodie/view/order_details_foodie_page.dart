import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/order_details_foodie/element/order_item_row.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

class OrderDetailsFoodiePage extends StatefulWidget {
  const OrderDetailsFoodiePage({super.key, required this.order});

  final Map<String, dynamic> order;

  static Route route({RouteArguments? routeArguments}) {
    final order = routeArguments?.data is Map<String, dynamic>
        ? routeArguments!.data as Map<String, dynamic>
        : <String, dynamic>{};
    return MaterialPageRoute<void>(
      builder: (_) => OrderDetailsFoodiePage(order: order),
    );
  }

  @override
  State<OrderDetailsFoodiePage> createState() => _OrderDetailsFoodiePageState();
}

class _OrderDetailsFoodiePageState extends State<OrderDetailsFoodiePage> {
  bool _isCancelling = false;

  Map<String, dynamic> get order => widget.order;

  String get _status => '${order['status']}';

  @override
  Widget build(BuildContext context) {
    final kitchen = order['mikitchn'];
    final kitchenName = kitchen is Map<String, dynamic>
        ? (kitchen['name']?.toString() ?? 'Kitchen')
        : 'Kitchen';
    final orderId = order['order_id']?.toString() ??
        order['id']?.toString() ??
        '';
    final date = order['date']?.toString() ?? '';
    final timeFrom = order['time_from']?.toString() ?? '';
    final timeTo = order['time_to']?.toString() ?? '';
    final totalPrice = order['total_price']?.toString() ?? '0.00';
    final items = order['items'] is List ? order['items'] as List : [];

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: Text('Order #MF-$orderId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MitablSpacing.pagePadding,
          vertical: MitablSpacing.pagePadding,
        ),
        child: Column(
          children: [
            // ── Order Status Timeline (horizontal) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      _StatusBadge(status: _status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HorizontalTimeline(status: _status),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Customer & Delivery Info ──
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: MitablColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Customer Info',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onSurface,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          kitchenName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: MitablColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping, color: MitablColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Delivery',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Doorstep Delivery',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        if (timeFrom.isNotEmpty && timeTo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 12, color: MitablColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$timeFrom - $timeTo',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Order Items ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isNotEmpty)
                    ...items.map((item) {
                      final itemMap = item is Map<String, dynamic>
                          ? item
                          : <String, dynamic>{};
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: OrderItemRow(item: itemMap),
                      );
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No items available',
                        style: TextStyle(
                          color: MitablColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Totals & Breakdown ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PriceLine(label: 'Subtotal', value: totalPrice),
                  const SizedBox(height: 8),
                  _PriceLine(
                    label: 'Taxes & Fees',
                    value: order['tax']?.toString() ?? '0.00',
                  ),
                  const SizedBox(height: 8),
                  _PriceLine(
                    label: 'Delivery Fee',
                    value: order['delivery_fee']?.toString() ?? '0.00',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: const Color(0xFFE5E2DD),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$$totalPrice',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: MitablColors.primary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: MitablColors.primary.withValues(alpha: 0.1),
                          borderRadius: MitablRadius.pillBorder,
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Action Buttons ──
            ..._buildActionButtons(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final widgets = <Widget>[];

    // Cancel button (status == 2: Requested)
    if (_status == '2') {
      widgets.add(
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: Material(
                  color: const Color(0xFFE5E2DD),
                  borderRadius: MitablRadius.pillBorder,
                  child: InkWell(
                    borderRadius: MitablRadius.pillBorder,
                    onTap: _isCancelling ? null : () => _cancelOrder(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close,
                            color: MitablColors.onSurfaceVariant, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isCancelling ? 'Cancelling...' : 'Cancel Order',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MitablButton(
                label: 'Track Order',
                onPressed: () {},
                variant: MitablButtonVariant.primary,
                icon: const Icon(Icons.check_circle,
                    color: MitablColors.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Rate Order button (status == 1: Completed)
    if (_status == '1') {
      widgets.add(
        MitablButton(
          label: 'Rate Order',
          onPressed: () {
            final kitchen = order['mikitchn'];
            final kitchenId = kitchen is Map<String, dynamic>
                ? (kitchen['id']?.toString() ?? '')
                : '';
            final kitchenName = kitchen is Map<String, dynamic>
                ? (kitchen['name']?.toString() ?? '')
                : '';
            final kitchenAvatar = kitchen is Map<String, dynamic>
                ? (kitchen['avatar']?.toString() ?? '')
                : '';
            Navigator.of(context).pushNamed(
              '/SubmitReview',
              arguments: RouteArguments(
                data: {
                  'order_id': order['order_id'] ?? order['id'],
                  'restaurant_id': kitchenId,
                  'kitchen_name': kitchenName,
                  'kitchen_avatar': kitchenAvatar,
                },
              ),
            );
          },
          variant: MitablButtonVariant.primary,
          icon: const Icon(Icons.star, color: MitablColors.onPrimary, size: 20),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Track button (status == 5: In progress)
    if (_status == '5') {
      widgets.add(
        MitablButton(
          label: 'Track Order',
          onPressed: () {
            Navigator.of(context).pushNamed(
              '/OrderTracking',
              arguments: RouteArguments(data: order),
            );
          },
          variant: MitablButtonVariant.primary,
          icon: const Icon(Icons.location_on, color: MitablColors.onPrimary, size: 20),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a short cancellation reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || reason == null || reason.trim().isEmpty) return;

    setState(() => _isCancelling = true);
    try {
      final repository = MiOrdersRepository();
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      await repository.cancelOrder(
        userModel: userModel,
        orderId: order['order_id'] ?? order['id'] ?? '',
        cancelComment: reason,
      );
      repository.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel this order right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}

/// Horizontal timeline with evenly spaced dots and labels.
class _HorizontalTimeline extends StatelessWidget {
  const _HorizontalTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final statusInt = int.tryParse(status) ?? -1;

    final steps = [
      ('Placed', statusInt >= 2),
      ('Confirmed', statusInt >= 3),
      ('Cooking', statusInt >= 5 || statusInt == 1),
      ('Ready', statusInt == 1),
      ('Picked', statusInt == 1),
    ];

    return Column(
      children: [
        // Dots + lines row
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isEven) {
              // Dot
              final stepIdx = i ~/ 2;
              final isActive = steps[stepIdx].$2;
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4D6548)
                      : const Color(0xFFE5E2DD),
                  shape: BoxShape.circle,
                ),
              );
            } else {
              // Line between dots
              final leftIdx = i ~/ 2;
              final isActive = steps[leftIdx].$2 && steps[leftIdx + 1].$2;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isActive
                      ? const Color(0xFF4D6548)
                      : const Color(0xFFE5E2DD),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((step) {
            final (label, isActive) = step;
            return Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isActive
                    ? const Color(0xFF4D6548)
                    : MitablColors.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MitablColors.secondaryContainer,
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MitablColors.onSecondaryContainer,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          Text(
            '\$$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
