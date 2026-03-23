import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
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
  bool _isLoading = true;

  // Revenue period breakdown
  double _revenueToday = 0;
  double _revenueThisWeek = 0;
  double _revenueThisMonth = 0;

  // From route arguments (fallback)
  int _totalEarning = 0;
  int _nBookings = 0;

  // Top dishes from API
  List<_DishStat> _topDishes = [];

  // Daily trend from API
  List<_DailyTrend> _dailyTrend = [];

  double get _averageOrderValue {
    if (_nBookings == 0) return 0;
    return _totalEarning / _nBookings;
  }

  @override
  void initState() {
    super.initState();
    // Seed from route arguments
    final data = widget.routeArguments?.data;
    if (data is Map<String, dynamic>) {
      final te = data['totalEarning'];
      _totalEarning =
          te is int ? te : (te is double ? te.toInt() : 0);
      final nb = data['nBookings'];
      _nBookings =
          nb is int ? nb : (nb is double ? nb.toInt() : 0);
    }
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final headers = authorizedHeadersForUser(
        userModel,
        includeJsonContentType: true,
      );

      final response = await http.get(
        ApiContract.uri('v2/account/dashboard'),
        headers: headers,
      ).timeout(ApiContract.requestTimeout);

      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        // Parse revenue period breakdown
        final revToday = body['revenue_today'];
        final revWeek = body['revenue_this_week'];
        final revMonth = body['revenue_this_month'];
        _revenueToday = _toDouble(revToday);
        _revenueThisWeek = _toDouble(revWeek);
        _revenueThisMonth = _toDouble(revMonth);

        // Update totals if available
        final te = body['totalEarning'] ?? body['total_earning'];
        if (te != null) {
          _totalEarning = te is int ? te : (te is double ? te.toInt() : _totalEarning);
        }
        final nb = body['nBookings'] ?? body['n_bookings'];
        if (nb != null) {
          _nBookings = nb is int ? nb : (nb is double ? nb.toInt() : _nBookings);
        }

        // Parse top dishes
        final topDishesRaw = body['top_dishes'];
        if (topDishesRaw is List && topDishesRaw.isNotEmpty) {
          final maxOrders = topDishesRaw.fold<int>(0, (prev, d) {
            final oc = d['order_count'];
            final count = oc is int ? oc : (oc is double ? oc.toInt() : 0);
            return count > prev ? count : prev;
          });
          _topDishes = topDishesRaw.map((d) {
            final name = (d['name'] ?? 'Unknown').toString();
            final oc = d['order_count'];
            final orders = oc is int ? oc : (oc is double ? oc.toInt() : 0);
            final tr = d['total_revenue'];
            final revenue = _toDouble(tr);
            return _DishStat(
              name: name,
              orders: orders,
              revenue: revenue,
              fraction: maxOrders > 0 ? orders / maxOrders : 0,
            );
          }).toList();
        }

        // Parse daily trend
        final trendRaw = body['daily_trend'];
        if (trendRaw is List && trendRaw.isNotEmpty) {
          _dailyTrend = trendRaw.map((d) {
            final date = (d['date'] ?? '').toString();
            final rev = _toDouble(d['revenue']);
            final oc = d['orders'];
            final orders = oc is int ? oc : (oc is double ? oc.toInt() : 0);
            return _DailyTrend(date: date, revenue: rev, orders: orders);
          }).toList();
        }

        setState(() => _isLoading = false);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('Vendor Hub')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MitablColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(MitablSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  const Text(
                    'Revenue Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Monthly / Yearly toggle pills ──
                  Row(
                    children: [
                      MitablChip(
                        label: 'Monthly',
                        selected: _isMonthly,
                        onSelected: (_) =>
                            setState(() => _isMonthly = true),
                      ),
                      const SizedBox(width: 8),
                      MitablChip(
                        label: 'Yearly',
                        selected: !_isMonthly,
                        onSelected: (_) =>
                            setState(() => _isMonthly = false),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Large total revenue with comparison badge ──
                  Text(
                    '\$${_totalEarning.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MitablColors.accent.withValues(alpha: 0.1),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Text(
                      _isMonthly
                          ? '+12% vs last month'
                          : '+8% vs last year',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MitablColors.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Period breakdown cards: Today / This Week / This Month ──
                  Row(
                    children: [
                      Expanded(
                        child: _periodCard(
                          'Today',
                          '\$${_revenueToday.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _periodCard(
                          'This Week',
                          '\$${_revenueThisWeek.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _periodCard(
                          'This Month',
                          '\$${_revenueThisMonth.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Orders card with bar chart ──
                  MitablCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Orders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_nBookings',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Avg. Order',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${_averageOrderValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bar chart from daily_trend (up to 7 bars)
                        _buildBarChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: MitablSpacing.breathe),

                  // ── Top Dishes section ──
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

                  if (_topDishes.isEmpty)
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
                    ..._topDishes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dish = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDishBar(
                          rank: index + 1,
                          name: dish.name,
                          fraction: dish.fraction,
                          orders: dish.orders,
                          revenue: dish.revenue,
                        ),
                      );
                    }),

                  const SizedBox(height: MitablSpacing.breathe),

                  // ── Transaction History from daily_trend ──
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

                  if (_dailyTrend.isEmpty)
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
                    ..._dailyTrend.map((trend) {
                      return _buildTransaction(
                        trend.date,
                        '\$${trend.revenue.toStringAsFixed(2)}',
                        '${trend.orders} orders',
                      );
                    }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _periodCard(String label, String amount) {
    return MitablCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: MitablColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Use up to 7 most recent daily_trend entries for the bar chart
    final bars = _dailyTrend.length > 7
        ? _dailyTrend.sublist(_dailyTrend.length - 7)
        : _dailyTrend;

    if (bars.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No trend data',
            style: TextStyle(
              fontSize: 13,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxRevenue = bars.fold<double>(
      0,
      (prev, t) => t.revenue > prev ? t.revenue : prev,
    );
    final effectiveMax = maxRevenue > 0 ? maxRevenue : 1.0;

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((trend) {
          final fraction = trend.revenue / effectiveMax;
          // Extract short day label from date
          final dayLabel = trend.date.length >= 10
              ? trend.date.substring(8, 10)
              : trend.date;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: math.max(4.0, fraction * 72),
                    decoration: const BoxDecoration(
                      color: MitablColors.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDishBar({
    required int rank,
    required String name,
    required double fraction,
    required int orders,
    required double revenue,
  }) {
    return MitablCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#$rank  $name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$orders orders  \$${revenue.toStringAsFixed(2)}',
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

  Widget _buildTransaction(String date, String amount, String orderCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MitablCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: MitablColors.onSurfaceVariant,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurface,
                  ),
                ),
                Text(
                  orderCount,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
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
    required this.revenue,
    required this.fraction,
  });

  final String name;
  final int orders;
  final double revenue;
  final double fraction;
}

class _DailyTrend {
  const _DailyTrend({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  final String date;
  final double revenue;
  final int orders;
}
