import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/element/cook_contact_card.dart';
import 'package:mitabl_user/pages/ordering/element/order_status_timeline.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';

/// Order tracking page that polls the order status every 15 seconds.
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({
    super.key,
    required this.data,
  });

  final OrderTrackingRouteData data;

  static Route route({required RouteArguments? routeArguments}) {
    final routeData = routeArguments?.data;
    if (routeData is! OrderTrackingRouteData) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(
            child: Text('Missing route arguments for /OrderTracking'),
          ),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderTracking'),
      builder: (_) => OrderTrackingPage(data: routeData),
    );
  }

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Timer? _pollTimer;
  final MiOrdersRepository _repository = MiOrdersRepository();

  // Default status: Requested (2)
  int _orderStatus = 2;
  String _cookLabel = 'Your cook';
  String _etaLabel = '...';

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchOrderStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final orders = await _repository.fetchOrdersHistory(
        userModel: userModel,
        limit: 50,
      );

      if (!mounted) return;

      // Find matching order by orderId
      final targetId = widget.data.orderId;
      Map<String, dynamic>? matchingOrder;
      for (final order in orders) {
        final oid = (order['order_id'] ?? order['id'] ?? '').toString();
        if (oid == targetId) {
          matchingOrder = order;
          break;
        }
      }

      if (matchingOrder != null) {
        final rawStatus = matchingOrder['status'];
        final status = rawStatus is int
            ? rawStatus
            : int.tryParse(rawStatus?.toString() ?? '') ?? _orderStatus;

        // Extract cook name from kitchen data
        final kitchen = matchingOrder['mikitchn'];
        String cookName = _cookLabel;
        if (kitchen is Map<String, dynamic>) {
          final cock = kitchen['cock'];
          if (cock is Map<String, dynamic>) {
            cookName = (cock['name'] ?? '').toString();
          }
          if (cookName.isEmpty) {
            cookName = (kitchen['name'] ?? 'Your cook').toString();
          }
        }

        setState(() {
          _orderStatus = status;
          _cookLabel = cookName;
          _etaLabel = _estimateEta(status);
        });

        // Stop polling when order is completed or cancelled
        if (status == 1 || status == 0 || status == 4) {
          _pollTimer?.cancel();
        }
      }
    } catch (_) {
      // Silently fail on poll -- will retry next interval
    }
  }

  String _estimateEta(int status) {
    switch (status) {
      case 2:
        return 'Awaiting confirmation';
      case 3:
        return 'Preparing soon';
      case 5:
        return '~15 mins';
      case 1:
        return 'Ready!';
      default:
        return '...';
    }
  }

  List<TimelineStepData> _buildTimelineSteps(int status) {
    switch (status) {
      case 2: // Requested
        return const [
          TimelineStepData(
            title: 'Order Placed',
            subtitle: 'Waiting for cook to accept',
            status: TimelineStepStatus.active,
          ),
          TimelineStepData(
            title: 'Order Confirmed',
            subtitle: 'Cook will confirm shortly',
            status: TimelineStepStatus.pending,
          ),
          TimelineStepData(
            title: 'Cooking',
            subtitle: 'Your meal is being prepared',
            status: TimelineStepStatus.pending,
          ),
          TimelineStepData(
            title: 'Ready for Pickup',
            subtitle: 'Collect your order',
            status: TimelineStepStatus.pending,
          ),
        ];
      case 3: // Confirmed
        return const [
          TimelineStepData(
            title: 'Order Placed',
            subtitle: 'Your order has been confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Order Confirmed',
            subtitle: 'Cook is getting ready',
            status: TimelineStepStatus.active,
          ),
          TimelineStepData(
            title: 'Cooking',
            subtitle: 'Your meal is being prepared',
            status: TimelineStepStatus.pending,
          ),
          TimelineStepData(
            title: 'Ready for Pickup',
            subtitle: 'Collect your order',
            status: TimelineStepStatus.pending,
          ),
        ];
      case 5: // In Progress
        return const [
          TimelineStepData(
            title: 'Order Placed',
            subtitle: 'Your order has been confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Order Confirmed',
            subtitle: 'Cook accepted your order',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Cooking',
            subtitle: 'Your meal is being cooked',
            status: TimelineStepStatus.active,
          ),
          TimelineStepData(
            title: 'Ready for Pickup',
            subtitle: 'Almost there!',
            status: TimelineStepStatus.pending,
          ),
        ];
      case 1: // Completed
        return const [
          TimelineStepData(
            title: 'Order Placed',
            subtitle: 'Your order was confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Order Confirmed',
            subtitle: 'Cook accepted your order',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Cooking',
            subtitle: 'Meal was prepared',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Ready for Pickup',
            subtitle: 'Order is ready!',
            status: TimelineStepStatus.completed,
          ),
        ];
      default: // Cancelled or unknown
        return const [
          TimelineStepData(
            title: 'Order Placed',
            subtitle: 'Your order was placed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Cancelled',
            subtitle: 'This order has been cancelled',
            status: TimelineStepStatus.active,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildTimelineSteps(_orderStatus);

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('Order Status')),
      body: ListView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        children: [
          // Map placeholder
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: MitablColors.surfaceContainerLow,
              borderRadius: MitablRadius.cardBorder,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 48,
                  color: MitablColors.onSurfaceVariant,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: MitablColors.primary,
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Text(
                      _etaLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Heading
          Text(
            '$_cookLabel is cooking your meal',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Order #${widget.data.orderId}',
            style: const TextStyle(
              fontSize: 14,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Timeline
          OrderStatusTimeline(steps: steps),
          const SizedBox(height: 32),

          // Cook contact card
          CookContactCard(cookName: widget.data.kitchenName),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
