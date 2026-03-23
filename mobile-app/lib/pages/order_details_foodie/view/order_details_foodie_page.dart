import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/order_details_foodie/element/order_item_row.dart';
import 'package:mitabl_user/pages/ordering/element/order_status_timeline.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

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
    final kitchenAvatar = kitchen is Map<String, dynamic>
        ? (kitchen['avatar']?.toString() ?? '')
        : '';
    final avatarUrl = kitchenAvatar.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$kitchenAvatar'
        : '';
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
      appBar: const GlassAppBar(title: Text('Order Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          children: [
            // Order header card
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#MF-$orderId',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurface,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(status: _status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _defaultAvatar(),
                              )
                            : _defaultAvatar(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kitchenName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  date,
                                  if (timeFrom.isNotEmpty && timeTo.isNotEmpty)
                                    '$timeFrom - $timeTo',
                                ].join(' | '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Items card
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items Ordered',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isNotEmpty)
                    ...items.map((item) {
                      final itemMap = item is Map<String, dynamic>
                          ? item
                          : <String, dynamic>{};
                      return OrderItemRow(item: itemMap);
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No items available',
                        style: TextStyle(
                          color: MitablColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Divider(color: MitablColors.outlineVariant),
                  const SizedBox(height: 8),
                  _PriceLine(label: 'Subtotal', value: totalPrice),
                  const SizedBox(height: 4),
                  _PriceLine(
                    label: 'Taxes & Fees',
                    value: order['tax']?.toString() ?? '0.00',
                  ),
                  const Divider(color: MitablColors.outlineVariant),
                  _PriceLine(
                    label: 'Total',
                    value: totalPrice,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Order Status Timeline
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OrderStatusTimeline(steps: _buildTimelineSteps()),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Action buttons
            ..._buildActionButtons(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.restaurant,
        color: MitablColors.onSurfaceVariant,
        size: 22,
      ),
    );
  }

  List<TimelineStepData> _buildTimelineSteps() {
    final statusInt = int.tryParse(_status) ?? -1;

    return [
      TimelineStepData(
        title: 'Order Placed',
        subtitle: 'Your order has been submitted',
        status: statusInt >= 2
            ? TimelineStepStatus.completed
            : TimelineStepStatus.pending,
      ),
      TimelineStepData(
        title: 'Confirmed',
        subtitle: 'Kitchen has accepted your order',
        status: statusInt >= 3
            ? TimelineStepStatus.completed
            : statusInt == 2
                ? TimelineStepStatus.active
                : TimelineStepStatus.pending,
      ),
      TimelineStepData(
        title: 'In Progress',
        subtitle: 'Your meal is being prepared',
        status: statusInt >= 5
            ? TimelineStepStatus.completed
            : statusInt == 3
                ? TimelineStepStatus.active
                : TimelineStepStatus.pending,
      ),
      TimelineStepData(
        title: 'Completed',
        subtitle: 'Order has been fulfilled',
        status: statusInt == 1
            ? TimelineStepStatus.completed
            : statusInt == 5
                ? TimelineStepStatus.active
                : TimelineStepStatus.pending,
      ),
    ];
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final widgets = <Widget>[];

    // Cancel button (status == 2: Requested)
    if (_status == '2') {
      widgets.add(
        MitablButton(
          label: _isCancelling ? 'Cancelling...' : 'Cancel Order',
          onPressed: _isCancelling ? null : () => _cancelOrder(context),
          variant: MitablButtonVariant.outline,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: MitablRadius.pillBorder,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold
                  ? MitablColors.onSurface
                  : MitablColors.onSurfaceVariant,
            ),
          ),
          Text(
            '\$$value',
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: MitablColors.onSurface,
              fontFamily: isBold ? 'Nunito' : null,
            ),
          ),
        ],
      ),
    );
  }
}
