import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

class RevenueAnalyticsPage extends StatefulWidget {
  const RevenueAnalyticsPage({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) =>
          RevenueAnalyticsPage(routeArguments: routeArguments),
    );
  }

  @override
  State<RevenueAnalyticsPage> createState() => _RevenueAnalyticsPageState();
}

class _RevenueAnalyticsPageState extends State<RevenueAnalyticsPage> {
  bool _isMonthly = true;
  bool _isLoadingHistory = true;
  List<Bookings> _completedOrders = [];
  List<_DishStat> _topDishes = [];

  int get _totalEarning {
    final data = widget.routeArguments?.data;
    if (data is Map<String, dynamic>) {
      final val = data['totalEarning'];
      if (val is int) return val;
      if (val is double) return val.toInt();
    }
    return 0;
  }

  int get _nBookings {
    final data = widget.routeArguments?.data;
    if (data is Map<String, dynamic>) {
      final val = data['nBookings'];
      if (val is int) return val;
      if (val is double) return val.toInt();
    }
    return 0;
  }

  double get _averageOrderValue {
    if (_nBookings == 0) return 0;
    return _totalEarning / _nBookings;
  }

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    try {
      final repo = BookingRepository(context.read<UserRepository>());
      final response = await repo.getBookings(
        isUpcoming: false,
        limit: 50,
        page: 1,
      );
      if (response.statusCode == 200) {
        final booking = Booking.fromJson(jsonDecode(response.body));
        final orders = booking.data?.bookings ?? [];
        // Filter to completed orders (status 1)
        final completed =
            orders.where((o) => o.status == 1).toList();

        // Aggregate top dishes
        final dishCounts = <String, int>{};
        final dishRevenue = <String, double>{};
        for (final order in completed) {
          if (order.items != null) {
            for (final item in order.items!) {
              final name = item.food ?? 'Unknown';
              final qty = item.quantity ?? 1;
              final price = (item.price is num)
                  ? (item.price as num).toDouble()
                  : double.tryParse(item.price?.toString() ?? '0') ?? 0;
              dishCounts[name] = (dishCounts[name] ?? 0) + qty;
              dishRevenue[name] =
                  (dishRevenue[name] ?? 0) + (price * qty);
            }
          }
        }

        // Sort by order count descending, take top 5
        final sortedDishes = dishCounts.keys.toList()
          ..sort((a, b) => dishCounts[b]!.compareTo(dishCounts[a]!));
        final maxOrders = sortedDishes.isNotEmpty
            ? dishCounts[sortedDishes.first]!
            : 1;
        final topDishes = sortedDishes.take(5).map((name) {
          final count = dishCounts[name]!;
          return _DishStat(
            name: name,
            orders: count,
            fraction: maxOrders > 0 ? count / maxOrders : 0,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _completedOrders = completed;
            _topDishes = topDishes;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(title: const Text('Revenue Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly / Yearly toggle
            Row(
              children: [
                MitablChip(
                  label: 'Monthly',
                  selected: _isMonthly,
                  onSelected: (_) => setState(() => _isMonthly = true),
                ),
                const SizedBox(width: 8),
                MitablChip(
                  label: 'Yearly',
                  selected: !_isMonthly,
                  onSelected: (_) => setState(() => _isMonthly = false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Total Revenue card
            MitablCard(
              color: MitablColors.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Revenue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MitablColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AUD $_totalEarning',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isMonthly
                        ? '+12% vs last month'
                        : '+8% vs last year',
                    style: TextStyle(
                      fontSize: 13,
                      color: MitablColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Orders card
            MitablCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Orders',
                          style: TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_nBookings',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: MitablColors.outlineVariant,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Avg Order Value',
                            style: TextStyle(
                              fontSize: 13,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AUD ${_averageOrderValue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.breathe),

            // Top Dishes section
            const Text(
              'Top Dishes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: MitablColors.primary,
                  ),
                ),
              )
            else if (_topDishes.isEmpty)
              const MitablCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No dish data available yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ..._topDishes.map((dish) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDishBar(
                      dish.name, dish.fraction, dish.orders),
                );
              }),

            const SizedBox(height: MitablSpacing.breathe),

            // Transaction History
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: MitablColors.primary,
                  ),
                ),
              )
            else if (_completedOrders.isEmpty)
              const MitablCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ..._completedOrders.map((order) {
                final date = order.date ?? order.createdAt ?? '';
                final price = order.itemTotalPrice ?? 0;
                final statusLabel =
                    order.status == 1 ? 'Completed' : 'Pending';
                return _buildTransaction(
                  date,
                  'AUD $price',
                  statusLabel,
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDishBar(String name, double fraction, int orders) {
    return MitablCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MitablColors.onSurface,
                ),
              ),
              Text(
                '$orders orders',
                style: const TextStyle(
                  fontSize: 12,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: MitablColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(
                MitablColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction(String date, String amount, String status) {
    final isRefunded = status == 'Refunded';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MitablCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isRefunded ? Icons.undo : Icons.check_circle_outline,
              size: 20,
              color: isRefunded ? MitablColors.error : MitablColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: MitablColors.onSurface,
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isRefunded
                    ? MitablColors.error.withValues(alpha: 0.1)
                    : MitablColors.accent.withValues(alpha: 0.1),
                borderRadius: MitablRadius.pillBorder,
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isRefunded ? MitablColors.error : MitablColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishStat {
  const _DishStat({
    required this.name,
    required this.orders,
    required this.fraction,
  });

  final String name;
  final int orders;
  final double fraction;
}
