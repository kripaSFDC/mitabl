import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// Order success / confirmation screen.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.data,
  });

  final OrderConfirmationRouteData data;

  static Route route({required RouteArguments? routeArguments}) {
    final routeData = routeArguments?.data;
    if (routeData is! OrderConfirmationRouteData) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(
            child: Text('Missing route arguments for /OrderConfirmation'),
          ),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderConfirmation'),
      builder: (_) => OrderConfirmationPage(data: routeData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = data.result.orderId;
    final dateLabel = DateFormat('EEE, d MMM').format(data.scheduledDate);

    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: MitablSpacing.pagePadding,
            vertical: 32,
          ),
          children: [
            const SizedBox(height: 24),

            // Success icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MitablColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: MitablColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // "Success!" heading
            const Center(
              child: Text(
                'Success!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: MitablColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Order number + confirmed badge
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#MF-$orderId',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MitablColors.accent.withValues(alpha: 0.12),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: const Text(
                      'Confirmed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Order Summary card
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data.items.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.quantity}x ${line.item.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: MitablColors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '\$${line.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    height: 20,
                    color: MitablColors.outlineVariant,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: MitablColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '\$${data.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: MitablColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Estimated Delivery card
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 18,
                        color: MitablColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateLabel, ${data.timeLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: MitablColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.kitchenAddress.isNotEmpty
                              ? data.kitchenAddress
                              : 'Address not available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Track Order button
            MitablButton(
              label: 'Track Order',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/OrderTracking',
                  arguments: RouteArguments(
                    data: OrderTrackingRouteData(
                      orderId: orderId.toString(),
                      kitchenName: data.kitchenName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Back to Home button
            MitablButton(
              label: 'Back to Home',
              variant: MitablButtonVariant.outline,
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/HomePage',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
