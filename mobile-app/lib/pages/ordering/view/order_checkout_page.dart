import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';

class OrderCheckoutPage extends StatelessWidget {
  const OrderCheckoutPage({
    super.key,
    required this.session,
  });

  final OrderSessionController session;

  static Route route({required RouteArguments routeArguments}) {
    final routeData = routeArguments.data;
    if (routeData is! OrderRouteData || routeData.session == null) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body:
              SafeArea(child: Text('Missing route arguments for /OrderCheckout')),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderCheckout'),
      builder: (_) => OrderCheckoutPage(session: routeData.session!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final kitchen = session.kitchen;
        final serviceLabel = session.serviceType == OrderServiceType.dineIn
            ? 'Dine in'
            : 'Take away';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Review order'),
          ),
          body: kitchen == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      kitchen.name,
                      style: GoogleFonts.gothicA1(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(kitchen.address),
                    const SizedBox(height: 20),
                    _CheckoutSection(
                      title: 'Order details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service: $serviceLabel'),
                          const SizedBox(height: 6),
                          Text(
                            'Date: ${DateFormat('EEE, d MMM yyyy').format(session.scheduledDate)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Time: ${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}',
                          ),
                          if (session.serviceType == OrderServiceType.dineIn) ...[
                            const SizedBox(height: 6),
                            Text('Guests: ${session.persons}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutSection(
                      title: 'Items',
                      child: Column(
                        children: session.cartItems
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${line.quantity} x ${line.item.name}',
                                      ),
                                    ),
                                    Text(
                                      '\$${line.lineTotal.toStringAsFixed(2)}',
                                      style: GoogleFonts.gothicA1(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutSection(
                      title: 'Pricing',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryRow(
                            label: 'Items',
                            value: '\$${session.itemTotal.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Taxes',
                            value: '\$${session.taxTotal.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Estimated total',
                            value:
                                '\$${session.estimatedTotal.toStringAsFixed(2)}',
                            emphasize: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Any eligible introductory discount is applied by the server when the order is created.',
                            style: GoogleFonts.gothicA1(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((session.errorMessage ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _displayError(session.errorMessage!),
                        style: GoogleFonts.gothicA1(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: session.isSubmitting
                          ? null
                          : () => _placeOrder(context),
                      child: session.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Place order'),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    try {
      final result = await session.submit();
      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order placed'),
          content: Text(
            'Order #${result.orderId} has been created.\n'
            'Server total: \$${result.totalPrice}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('View orders'),
            ),
          ],
        ),
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamed('/MiOrders');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_displayError(session.errorMessage ?? 'Unable to place order.'))),
      );
    }
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.gothicA1(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.gothicA1(
      fontSize: emphasize ? 16 : 14,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
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
