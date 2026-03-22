import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/element/cook_contact_card.dart';
import 'package:mitabl_user/pages/ordering/element/order_status_timeline.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';

/// Order tracking page with mock/static data.
class OrderTrackingPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                    child: const Text(
                      '15 mins',
                      style: TextStyle(
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
          const Text(
            'Maria is cooking your meal',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Order #${data.orderId}',
            style: const TextStyle(
              fontSize: 14,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Timeline
          const OrderStatusTimeline(
            steps: [
              TimelineStepData(
                title: 'Order Accepted',
                subtitle: 'Your order has been confirmed',
                status: TimelineStepStatus.completed,
              ),
              TimelineStepData(
                title: 'Prep & Chopping',
                subtitle: 'Ingredients are being prepared',
                status: TimelineStepStatus.completed,
              ),
              TimelineStepData(
                title: 'Cooking',
                subtitle: 'Your meal is being cooked',
                status: TimelineStepStatus.active,
              ),
              TimelineStepData(
                title: 'Ready for Pickup',
                subtitle: 'Estimated 15 minutes',
                status: TimelineStepStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Cook contact card
          CookContactCard(cookName: data.kitchenName),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
