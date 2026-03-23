import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/element/cook_contact_card.dart';
import 'package:mitabl_user/pages/ordering/element/order_status_timeline.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

/// Order tracking page that polls the order status every 15 seconds.
/// Design: sticky header, aspect-video map, text-3xl heading,
/// border-l-2 vertical stepper, cook card with photo + online dot + Message.
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

  int _orderStatus = 2;
  String _cookLabel = 'Your cook';
  String _etaLabel = '...';
  String _itemSummary = '';

  @override
  void initState() {
    super.initState();
    _itemSummary = widget.data.itemSummary ?? '';
    _cookLabel = widget.data.kitchenName;
    _fetchOrderDetail();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchOrderDetail(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final userRepository = context.read<UserRepository>();
      final headers = await userRepository.authorizedHeaders();
      final targetId = widget.data.orderId;

      final uri = ApiContract.uri('v2/orders/$targetId');
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiContract.requestTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final order = jsonDecode(response.body) as Map<String, dynamic>;
        _applyOrderData(order);
        return;
      }

      await _fetchOrderStatusFallback();
    } catch (_) {
      try {
        await _fetchOrderStatusFallback();
      } catch (_) {
        // Silently fail on poll
      }
    }
  }

  Future<void> _fetchOrderStatusFallback() async {
    final userRepository = context.read<UserRepository>();
    final userModel =
        userRepository.currentUser ?? await userRepository.getUser();
    final orders = await _repository.fetchOrdersHistory(
      userModel: userModel,
      limit: 50,
    );

    if (!mounted) return;

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
      _applyOrderData(matchingOrder);
    }
  }

  void _applyOrderData(Map<String, dynamic> order) {
    final rawStatus = order['status'];
    final status = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus?.toString() ?? '') ?? _orderStatus;

    final kitchen = order['mikitchn'];
    String cookName = _cookLabel;
    if (kitchen is Map<String, dynamic>) {
      final cook = kitchen['cock'] ?? kitchen['cook'];
      if (cook is Map<String, dynamic>) {
        cookName = (cook['name'] ?? '').toString();
      }
      if (cookName.isEmpty || cookName == _cookLabel) {
        cookName = (kitchen['name'] ?? _cookLabel).toString();
      }
    }

    String itemSummary = _itemSummary;
    final items = order['items'] ?? order['order_items'];
    if (items is List && items.isNotEmpty) {
      itemSummary = items
          .take(3)
          .map((i) =>
              (i is Map<String, dynamic>
                  ? (i['food'] ?? i['name'] ?? '')
                  : '')
                  .toString())
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    setState(() {
      _orderStatus = status;
      _cookLabel = cookName;
      _etaLabel = _estimateEta(status);
      _itemSummary = itemSummary;
    });

    if (status == 1 || status == 0 || status == 4) {
      _pollTimer?.cancel();
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
      case 2:
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
      case 3:
        return const [
          TimelineStepData(
            title: 'Order Accepted',
            subtitle: 'Your order has been confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Prep & Chopping',
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
      case 5:
        return const [
          TimelineStepData(
            title: 'Order Accepted',
            subtitle: 'Your order has been confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Prep & Chopping',
            subtitle: 'Ingredients prepared',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Cooking',
            subtitle: 'Simmering the spices...',
            status: TimelineStepStatus.active,
          ),
          TimelineStepData(
            title: 'Ready for Pickup',
            subtitle: 'Almost there!',
            status: TimelineStepStatus.pending,
          ),
        ];
      case 1:
        return const [
          TimelineStepData(
            title: 'Order Accepted',
            subtitle: 'Your order was confirmed',
            status: TimelineStepStatus.completed,
          ),
          TimelineStepData(
            title: 'Prep & Chopping',
            subtitle: 'Ingredients prepared',
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
      default:
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
      backgroundColor: const Color(0xFFF8F6F6), // background-light
      body: Column(
        children: [
          // Sticky header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F6).withValues(alpha: 0.9),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back, size: 24),
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Spacer
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Map placeholder (aspect-video)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0), // slate-200
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8), // slate-400
                          ),
                          // ETA badge top-right
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F6F6),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Color(0xFFEF6034),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _etaLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
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

                // Dynamic status header - text-3xl centered
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        '$_cookLabel is cooking your meal',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _itemSummary.isNotEmpty
                            ? 'Order #${widget.data.orderId} \u00B7 $_itemSummary'
                            : 'Order #${widget.data.orderId}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B), // slate-500
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical progress stepper
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: OrderStatusTimeline(steps: steps),
                ),

                const SizedBox(height: 24),

                // Cook contact card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CookContactCard(cookName: widget.data.kitchenName),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
