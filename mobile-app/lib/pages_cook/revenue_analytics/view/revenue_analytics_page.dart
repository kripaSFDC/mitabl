import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
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

            _buildDishBar('Butter Chicken', 0.85, 42),
            const SizedBox(height: 12),
            _buildDishBar('Lamb Biryani', 0.65, 31),
            const SizedBox(height: 12),
            _buildDishBar('Paneer Tikka', 0.50, 24),
            const SizedBox(height: 12),
            _buildDishBar('Mango Lassi', 0.35, 18),

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

            _buildTransaction('Mar 22, 2026', 'AUD 85', 'Completed'),
            _buildTransaction('Mar 21, 2026', 'AUD 120', 'Completed'),
            _buildTransaction('Mar 20, 2026', 'AUD 45', 'Refunded'),
            _buildTransaction('Mar 19, 2026', 'AUD 95', 'Completed'),
            _buildTransaction('Mar 18, 2026', 'AUD 68', 'Completed'),
            _buildTransaction('Mar 17, 2026', 'AUD 110', 'Completed'),

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
