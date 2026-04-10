import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/helper/route_arguement.dart';

class HomePageCook extends StatefulWidget {
  const HomePageCook({super.key});

  @override
  State<HomePageCook> createState() => _HomePageCookState();
}

class _HomePageCookState extends State<HomePageCook> {
  bool _kitchenLive = true;
  bool _kitchenToggling = false;
  List<Bookings> _queueOrders = [];
  bool _queueLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCookCubit>().getDashBoardData();
    _loadCookingQueue();
  }

  Future<void> _toggleKitchenLive(bool desired) async {
    if (_kitchenToggling) return;

    final previous = _kitchenLive;
    setState(() {
      _kitchenLive = desired;
      _kitchenToggling = true;
    });

    try {
      final userRepository = context.read<UserRepository>();
      final headers = await userRepository.authorizedHeaders(
        includeJsonContentType: true,
      );
      final uri = ApiContract.uri('v2/mikitchn/toggle-open');
      final response = await http
          .post(uri, headers: headers)
          .timeout(ApiContract.requestTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final serverOpen = body['open'] as bool? ?? desired;
        setState(() {
          _kitchenLive = serverOpen;
          _kitchenToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serverOpen ? 'Kitchen is now live' : 'Kitchen is now offline',
            ),
          ),
        );
      } else {
        setState(() {
          _kitchenLive = previous;
          _kitchenToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update kitchen status')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kitchenLive = previous;
        _kitchenToggling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  Future<void> _loadCookingQueue() async {
    try {
      final repo = BookingRepository(context.read<UserRepository>());
      final response = await repo.getBookings(
        isUpcoming: true,
        limit: 5,
        page: 1,
      );
      if (response.statusCode == 200) {
        final booking = Booking.fromJson(jsonDecode(response.body));
        if (mounted) {
          setState(() {
            _queueOrders = booking.data?.bookings ?? [];
            _queueLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _queueLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _queueLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MitablColors.surface,
        body: BlocBuilder<DashboardCookCubit, DashboardCookState>(
          builder: (context, state) {
            final dashData = state.dashboardData?.data;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header (sticky style) ──
                  Container(
                    padding: const EdgeInsets.only(
                      top: 48,
                      bottom: 16,
                      left: 24,
                      right: 24,
                    ),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      boxShadow: [
                        BoxShadow(
                          color: MitablColors.onSurface.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title row + avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: MitablColors.surfaceContainerLow,
                                border: Border.all(
                                  color: MitablColors.surfaceContainerLowest,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: MitablColors.onSurface
                                        .withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: MitablColors.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Go Live Toggle ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: MitablColors.onSurface
                                    .withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cell_tower,
                                color: Color(0xFF687A57),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kitchen Live',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: MitablColors.onSurface,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _kitchenLive
                                          ? 'Accepting orders'
                                          : 'Kitchen offline',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Toggle switch
                              SizedBox(
                                width: 64,
                                height: 32,
                                child: FittedBox(
                                  child: Switch(
                                    value: _kitchenLive,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF687A57),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor:
                                        MitablColors.onSurfaceVariant,
                                    onChanged: _kitchenToggling
                                        ? null
                                        : (v) => _toggleKitchenLive(v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Metrics Row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        // Active Orders metric
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Orders',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dashData?.nUpcomingBookings ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Today's Earnings metric
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Earnings",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${dashData?.totalEarning ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Cooking Queue Section ──
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Cooking Queue',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_queueLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: MitablColors.primary,
                        ),
                      ),
                    )
                  else if (_queueOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: MitablColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: MitablColors.onSurface
                                  .withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color:
                                MitablColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No active orders in the queue',
                            style: TextStyle(
                              fontSize: 14,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_queueOrders.length, (index) {
                      final order = _queueOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 16,
                        ),
                        child: _buildQueueTicket(
                          order: order,
                          isDelayed: index == 1, // mock delayed state
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // ── View Revenue Button ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: MitablButton(
                      label: 'View Revenue',
                      onPressed: () {
                        navigatorKey.currentState!.pushNamed(
                          '/RevenueAnalytics',
                          arguments: RouteArguments(
                            data: <String, dynamic>{
                              'totalEarning': dashData?.totalEarning ?? 0,
                              'nBookings': dashData?.nBookings ?? 0,
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markOrderReady(dynamic orderId) async {
    if (orderId == null) return;
    try {
      final repo = BookingRepository(context.read<UserRepository>());
      final response = await repo.updateOrderStatus(
        data: {
          'order_id': orderId,
          'status': 1,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as ready')),
        );
        await _loadCookingQueue();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update order status')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  void _delayOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer notified of delay')),
    );
  }

  Widget _buildQueueTicket({
    required Bookings order,
    bool isDelayed = false,
  }) {
    final customerName = order.customer?.name ?? 'Customer';
    final ticketId = '#${order.orderTypeId ?? order.orderId ?? ''}';
    final timeLabel = '${order.timeFrom ?? ''} - ${order.timeTo ?? ''}';
    final itemCount = order.items?.length ?? 0;
    final borderColor = isDelayed
        ? MitablColors.primary.withValues(alpha: 0.3)
        : MitablColors.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MitablColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top danger highlight for delayed
          if (isDelayed)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: MitablColors.primary,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: ticket# + customer + elapsed badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ticketId,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeLabel.isNotEmpty ? timeLabel : 'Delivery',
                            style: const TextStyle(
                              fontSize: 14,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Elapsed time badge
                    if (isDelayed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MitablColors.primary.withValues(alpha: 0.1),
                          borderRadius: MitablRadius.pillBorder,
                          border: Border.all(
                            color:
                                MitablColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: MitablColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delayed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MitablColors.surfaceContainerLow,
                          borderRadius: MitablRadius.pillBorder,
                          border: Border.all(
                            color: MitablColors.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'In progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Items list with left border
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        width: 2,
                        color: isDelayed
                            ? MitablColors.primary.withValues(alpha: 0.3)
                            : MitablColors.outlineVariant,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (itemCount > 0)
                        ...order.items!.take(3).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity ?? 1}x ${item.food ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        const Text(
                          'Take-away order',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MitablColors.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: MitablColors.outlineVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isDelayed)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _delayOrder,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: MitablRadius.pillBorder,
                              ),
                            ),
                            child: const Text(
                              'Delay',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: MitablColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      if (!isDelayed) const SizedBox(width: 12),
                      Expanded(
                        flex: isDelayed ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: () => _markOrderReady(order.orderId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MitablColors.primary,
                            foregroundColor: MitablColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 4,
                            shadowColor:
                                MitablColors.primary.withValues(alpha: 0.15),
                            shape: const RoundedRectangleBorder(
                              borderRadius: MitablRadius.pillBorder,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Mark Ready',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
