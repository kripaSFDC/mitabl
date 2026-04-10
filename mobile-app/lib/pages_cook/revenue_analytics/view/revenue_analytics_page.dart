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

class RevenueAnalyticsPage extends StatefulWidget {
  const RevenueAnalyticsPage({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => RevenueAnalyticsPage(routeArguments: routeArguments),
    );
  }

  @override
  State<RevenueAnalyticsPage> createState() => _RevenueAnalyticsPageState();
}

class _RevenueAnalyticsPageState extends State<RevenueAnalyticsPage> {
  bool _isWeekly = true;
  bool _isLoading = true;

  int _totalEarning = 0;
  int _nBookings = 0;

  List<_DishStat> _topDishes = [];
  List<_DailyTrend> _dailyTrend = [];

  Future<void> _showAllTransactions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue Timeline',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                if (_dailyTrend.isEmpty)
                  const Text(
                    'Revenue data is still loading.',
                    style: TextStyle(color: MitablColors.onSurfaceVariant),
                  )
                else
                  ..._dailyTrend.map(
                    (trend) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(trend.date),
                      subtitle: Text('${trend.orders} order(s)'),
                      trailing: Text(
                        '\$${trend.revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MitablColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double get _averageOrderValue {
    if (_nBookings == 0) return 0;
    return _totalEarning / _nBookings;
  }

  @override
  void initState() {
    super.initState();
    final data = widget.routeArguments?.data;
    if (data is Map<String, dynamic>) {
      final te = data['totalEarning'];
      _totalEarning = te is int ? te : (te is double ? te.toInt() : 0);
      final nb = data['nBookings'];
      _nBookings = nb is int ? nb : (nb is double ? nb.toInt() : 0);
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

      final response = await http
          .get(
            ApiContract.uri('v2/account/dashboard'),
            headers: headers,
          )
          .timeout(ApiContract.requestTimeout);

      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        final te = body['totalEarning'] ?? body['total_earning'];
        if (te != null) {
          _totalEarning =
              te is int ? te : (te is double ? te.toInt() : _totalEarning);
        }
        final nb = body['nBookings'] ?? body['n_bookings'];
        if (nb != null) {
          _nBookings =
              nb is int ? nb : (nb is double ? nb.toInt() : _nBookings);
        }

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MitablColors.primary),
            )
          : CustomScrollView(
              slivers: [
                // ── Top App Bar ──
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 24,
                      right: 24,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: MitablColors.surface.withValues(alpha: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu, color: MitablColors.onSurface),
                            SizedBox(width: 16),
                            Text(
                              'Vendor Hub',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: MitablColors.secondaryContainer,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: MitablColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Header Section ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        const Text(
                          'PERFORMANCE OVERVIEW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title + Toggle row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Revenue\nAnalytics',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                                color: MitablColors.onSurface,
                                height: 1.1,
                              ),
                            ),
                            // Weekly / Monthly toggle
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: MitablColors.surfaceContainerLow,
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              child: Row(
                                children: [
                                  _buildTogglePill('Weekly', _isWeekly, () {
                                    setState(() => _isWeekly = true);
                                  }),
                                  _buildTogglePill('Monthly', !_isWeekly, () {
                                    setState(() => _isWeekly = false);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Main Earnings Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Earnings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${_totalEarning.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 40,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: Color(0xFF506140),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isWeekly
                                            ? '+12.4% vs last week'
                                            : '+8% vs last month',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF506140),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Legend dot
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: MitablColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Gross Revenue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Chart area ──
                          _buildLineChart(),

                          // Day labels
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mon', style: _dayLabelStyle),
                              Text('Tue', style: _dayLabelStyle),
                              Text('Wed', style: _dayLabelStyle),
                              Text('Thu', style: _dayLabelStyle),
                              Text('Fri', style: _dayLabelStyle),
                              Text('Sat', style: _dayLabelStyle),
                              Text('Sun', style: _dayLabelStyle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Active Orders + Avg Order Value card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: MitablColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 36,
                            color: MitablColors.onSecondaryContainer,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Active Orders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: MitablColors.onSecondaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_nBookings',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 36,
                              color: MitablColors.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AVERAGE ORDER VALUE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: MitablColors.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_averageOrderValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: MitablColors.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Top Dishes ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top Dishes',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: MitablColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_topDishes.isEmpty)
                            const Center(
                              child: Text(
                                'No dish data available yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ..._topDishes.map((dish) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Row(
                                  children: [
                                    // Placeholder image
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: MitablColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dish.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: MitablColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${dish.orders} orders  \$${dish.revenue.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  MitablColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: MitablColors.secondaryContainer,
                                        borderRadius: MitablRadius.pillBorder,
                                      ),
                                      child: Text(
                                        '+${(dish.fraction * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF506140),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Transaction History ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transaction History',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildCircleIconButton(Icons.filter_list),
                                  const SizedBox(width: 8),
                                  _buildCircleIconButton(Icons.download),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Table header
                          const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child:
                                    Text('ORDER ID', style: _tableHeaderStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('DATE', style: _tableHeaderStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('STATUS', style: _tableHeaderStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('AMOUNT',
                                    style: _tableHeaderStyle,
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_dailyTrend.isEmpty)
                            const Center(
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
                            )
                          else
                            ..._dailyTrend.asMap().entries.map((entry) {
                              final trend = entry.value;
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: MitablColors.surfaceContainerLow,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '#VH-${entry.key + 9000}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: MitablColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        trend.date,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: MitablColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: const BoxDecoration(
                                            color:
                                                MitablColors.secondaryContainer,
                                            borderRadius:
                                                MitablRadius.pillBorder,
                                          ),
                                          child: const Text(
                                            'Completed',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: MitablColors
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${trend.revenue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: MitablColors.onSurface,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _showAllTransactions,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor:
                                    MitablColors.surfaceContainerLow,
                                side: BorderSide.none,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: MitablRadius.pillBorder,
                                ),
                              ),
                              child: const Text(
                                'View All Transactions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildTogglePill(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? MitablColors.primary : Colors.transparent,
          borderRadius: MitablRadius.pillBorder,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: MitablColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive
                ? MitablColors.onPrimary
                : MitablColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final bars = _dailyTrend.length > 7
        ? _dailyTrend.sublist(_dailyTrend.length - 7)
        : _dailyTrend;

    if (bars.isEmpty) {
      return SizedBox(
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                MitablColors.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'No trend data',
              style: TextStyle(
                fontSize: 13,
                color: MitablColors.onSurfaceVariant,
              ),
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
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((trend) {
          final fraction = trend.revenue / effectiveMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: math.max(4.0, fraction * 100),
                    decoration: const BoxDecoration(
                      color: MitablColors.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
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

  Widget _buildCircleIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MitablColors.surfaceContainerLow,
      ),
      child: Icon(icon, size: 20, color: MitablColors.onSurfaceVariant),
    );
  }

  static const _dayLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: MitablColors.onSurfaceVariant,
    letterSpacing: 1,
  );

  static const _tableHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: MitablColors.onSurfaceVariant,
    letterSpacing: 2,
  );
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
