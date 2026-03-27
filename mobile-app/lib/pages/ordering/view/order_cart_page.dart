import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/element/checkout_item_card.dart';
import 'package:mitabl_user/pages/ordering/element/checkout_receipt.dart';
import 'package:mitabl_user/pages/ordering/element/slide_to_pay_button.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class OrderCartPage extends StatelessWidget {
  const OrderCartPage({super.key, required this.session});

  final OrderSessionController session;

  static Route route({required RouteArguments routeArguments}) {
    final routeData = routeArguments.data;
    if (routeData is! OrderRouteData || routeData.session == null) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(child: Text('Missing route arguments for /OrderCart')),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderCart'),
      builder: (_) => OrderCartPage(session: routeData.session!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF), // background-light
          body: session.cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              : _CartBody(session: session),
        );
      },
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final kitchen = session.kitchen;

    return Column(
      children: [
        // Sticky header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back, size: 24, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const Spacer(),
              // Centered title
              Column(
                children: [
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (kitchen != null)
                    Text(
                      kitchen.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 40), // Spacer for centering
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // Fulfillment toggle (sliding segmented control)
              if (kitchen != null) ...[
                _FulfillmentToggle(session: session, kitchen: kitchen),
                const SizedBox(height: 24),
              ],

              // YOUR ORDER section header
              const Text(
                'YOUR ORDER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),

              // Cart items
              ...session.cartItems.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CheckoutItemCard(line: line, session: session),
                ),
              ),

              // Add more items button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add more items',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Pickup info section
              _PickupInfoSection(session: session),
              const SizedBox(height: 16),

              // Receipt breakdown
              CheckoutReceipt(
                itemTotal: session.itemTotal,
                taxTotal: session.taxTotal,
                estimatedTotal: session.estimatedTotal,
              ),

              if ((session.errorMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _displayError(session.errorMessage!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Slide to pay
              if (session.isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                SlideToPayButton(
                  amount: session.estimatedTotal + 1.50,
                  onConfirmed: () => _handleSubmit(context),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final items = List<CartLineItem>.from(session.cartItems);
    final kitchenName = session.kitchen?.name ?? '';
    final kitchenAddress = session.kitchen?.address ?? '';
    final totalAmount = session.estimatedTotal + 1.50;
    final scheduledDate = session.scheduledDate;
    final timeLabel =
        '${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}';

    try {
      final result = await session.submit();

      if (!context.mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/OrderConfirmation',
        arguments: RouteArguments(
          data: OrderConfirmationRouteData(
            result: result,
            kitchenName: kitchenName,
            kitchenAddress: kitchenAddress,
            items: items,
            totalAmount: totalAmount,
            scheduledDate: scheduledDate,
            timeLabel: timeLabel,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _displayError(
              session.errorMessage ?? 'Unable to place order.',
            ),
          ),
        ),
      );
    }
  }
}

class _FulfillmentToggle extends StatelessWidget {
  const _FulfillmentToggle({required this.session, required this.kitchen});

  final OrderSessionController session;
  final OrderKitchenSummary kitchen;

  @override
  Widget build(BuildContext context) {
    final isPickup = session.serviceType == OrderServiceType.takeAway;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Stack(
        children: [
          // Animated highlight pill
          AnimatedAlign(
            alignment: isPickup ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              if (kitchen.takeAwayAvailable)
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        session.selectServiceType(OrderServiceType.takeAway),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'Pickup',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPickup ? FontWeight.w700 : FontWeight.w500,
                          color: isPickup
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              if (kitchen.dineInAvailable)
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        session.selectServiceType(OrderServiceType.dineIn),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'Delivery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              !isPickup ? FontWeight.w700 : FontWeight.w500,
                          color: !isPickup
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupInfoSection extends StatelessWidget {
  const _PickupInfoSection({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final kitchen = session.kitchen;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(session.scheduledDate);
    final timeLabel =
        '${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pickup time
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.schedule, size: 18, color: Color(0xFFEA580C)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$dateLabel, $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ),
          ),

          // Location
          if (kitchen != null)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on, size: 18, color: Color(0xFFEA580C)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kitchen.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        kitchen.address.isNotEmpty
                            ? kitchen.address
                            : 'Address not available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Map',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _displayError(String raw) {
  const marker = 'message: ';
  final markerIndex = raw.indexOf(marker);
  if (markerIndex == -1) {
    return raw;
  }

  final start = markerIndex + marker.length;
  final trimmed = raw.substring(start).trimRight();
  return trimmed.endsWith(')')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
