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
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

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
        final kitchen = session.kitchen;

        return Scaffold(
          backgroundColor: MitablColors.surface,
          appBar: GlassAppBar(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Checkout'),
                if (kitchen != null)
                  Text(
                    kitchen.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          body: session.cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(
                      fontSize: 15,
                      color: MitablColors.onSurfaceVariant,
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MitablSpacing.pagePadding,
        MitablSpacing.pagePadding,
        MitablSpacing.pagePadding,
        32,
      ),
      children: [
        // Pickup / Delivery toggle
        if (kitchen != null) ...[
          const Text(
            'Service Type',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              if (kitchen.takeAwayAvailable)
                MitablChip(
                  label: 'Take away',
                  selected:
                      session.serviceType == OrderServiceType.takeAway,
                  onSelected: (_) =>
                      session.selectServiceType(OrderServiceType.takeAway),
                ),
              if (kitchen.dineInAvailable)
                MitablChip(
                  label: 'Dine in',
                  selected:
                      session.serviceType == OrderServiceType.dineIn,
                  onSelected: (_) =>
                      session.selectServiceType(OrderServiceType.dineIn),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // YOUR ORDER section
        const Text(
          'YOUR ORDER',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: MitablColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...session.cartItems.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: MitablSpacing.listItem),
            child: CheckoutItemCard(line: line, session: session),
          ),
        ),

        // + Add more items
        Center(
          child: MitablButton(
            label: '+ Add more items',
            variant: MitablButtonVariant.outline,
            fullWidth: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(height: 24),

        // Pickup info
        _PickupInfoSection(session: session),
        const SizedBox(height: 24),

        // Receipt breakdown
        CheckoutReceipt(
          itemTotal: session.itemTotal,
          taxTotal: session.taxTotal,
          estimatedTotal: session.estimatedTotal,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your payment method is attached to the order and charged when the miCook accepts it.',
          style: TextStyle(
            fontSize: 12,
            color: MitablColors.onSurfaceVariant,
          ),
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
            amount: session.estimatedTotal + 1.50, // include community fee
            onConfirmed: () => _handleSubmit(context),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    // 1. Capture cart data before submit clears it
    final items = List<CartLineItem>.from(session.cartItems);
    final kitchenName = session.kitchen?.name ?? '';
    final kitchenAddress = session.kitchen?.address ?? '';
    final totalAmount = session.estimatedTotal + 1.50;
    final scheduledDate = session.scheduledDate;
    final timeLabel =
        '${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}';

    try {
      // 2. Submit order
      final result = await session.submit();

      if (!context.mounted) return;

      // 3. Navigate to confirmation
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
      // 4. Show error
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
      padding: const EdgeInsets.all(MitablSpacing.cardPadding),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: MitablRadius.cardBorder,
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Info',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: dateLabel,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: timeLabel,
          ),
          if (kitchen != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: kitchen.address.isNotEmpty
                  ? kitchen.address
                  : 'Address not available',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MitablColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
        ),
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
