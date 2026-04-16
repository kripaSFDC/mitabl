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

  void _handleSubmit(BuildContext context) {
    if (!session.canCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your order details first.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      '/OrderCheckout',
      arguments: RouteArguments(
        data: OrderRouteData(session: session),
      ),
    );
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
                        'Dine in',
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
    final isDineIn = session.serviceType == OrderServiceType.dineIn;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date picker row
          _InfoRow(
            icon: Icons.calendar_today,
            title: 'Date',
            subtitle: dateLabel,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: session.scheduledDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                session.updateScheduledDate(picked);
              }
            },
          ),

          _sectionDivider(),

          // Dine-in specific: party size
          if (isDineIn) ...[
            _InfoRow(
              icon: Icons.group,
              title: 'Guests',
              subtitle: '${session.persons} ${session.persons == 1 ? 'guest' : 'guests'}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleButton(
                    icon: Icons.remove,
                    onTap: session.persons > 1
                        ? () => session.updatePersons(session.persons - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${session.persons}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.add,
                    onTap: session.persons < 20
                        ? () => session.updatePersons(session.persons + 1)
                        : null,
                  ),
                ],
              ),
            ),

            _sectionDivider(),

            // Dine-in slot selector
            if (session.isLoadingDineInSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (session.dineInSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  session.dineInSlotError ??
                      'No dine-in slots available for this date.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'SELECT A TIME SLOT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: session.dineInSlots.map((slot) {
                  final isSelected = slot.id == session.selectedDineInSlotId;
                  final startLabel = TimeOfDayRange.fromApiRange(
                    start: slot.startTime,
                    end: slot.endTime,
                  );
                  final capacity = slot.seatCapacity;
                  final remaining = slot.remainingSeats;
                  final fillRatio = (capacity != null &&
                          capacity > 0 &&
                          remaining != null)
                      ? ((capacity - remaining) / capacity).clamp(0.0, 1.0)
                      : 0.0;
                  final fillColor = fillRatio >= 0.85
                      ? const Color(0xFFDC2626)
                      : fillRatio >= 0.6
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF16A34A);
                  final hasCapacityWarning = remaining != null &&
                      remaining > 0 &&
                      remaining < session.persons;

                  return GestureDetector(
                    onTap: () => session.selectDineInSlot(slot.id),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEA580C)
                              : hasCapacityWarning
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE2E8F0),
                          width: hasCapacityWarning && !isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${startLabel.startLabel} - ${startLabel.endLabel}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (remaining != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: SizedBox(
                                height: 4,
                                child: LinearProgressIndicator(
                                  value: fillRatio,
                                  backgroundColor: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : fillColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$remaining / ${capacity ?? '?'} seats left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: hasCapacityWarning
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : hasCapacityWarning
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              if (session.dineInSlotError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    session.dineInSlotError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              if (session.selectedDineInSlot != null &&
                  session.selectedDineInSlot!.remainingSeats != null &&
                  session.selectedDineInSlot!.remainingSeats! > 0 &&
                  session.selectedDineInSlot!.remainingSeats! <
                      session.persons)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only ${session.selectedDineInSlot!.remainingSeats} '
                            'seats available — reduce guests to '
                            '${session.selectedDineInSlot!.remainingSeats} or '
                            'pick another slot.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            _sectionDivider(),
          ],

          // Time (for take-away, or show selected slot time for dine-in)
          if (!isDineIn)
            _InfoRow(
              icon: Icons.schedule,
              title: 'Pickup Time',
              subtitle: timeLabel,
            )
          else if (session.selectedDineInSlot != null)
            _InfoRow(
              icon: Icons.schedule,
              title: 'Dine-in Time',
              subtitle: timeLabel,
            ),

          _sectionDivider(),

          // Location
          if (kitchen != null)
            _InfoRow(
              icon: Icons.location_on,
              title: kitchen.name,
              subtitle: kitchen.address.isNotEmpty
                  ? kitchen.address
                  : 'Address not available',
              trailing: const Text(
                'Map',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEA580C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 18, color: const Color(0xFFEA580C)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
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
        if (trailing != null) trailing!,
        if (onTap != null && trailing == null)
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFF64748B),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: row);
    }
    return row;
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFEA580C).withValues(alpha: 0.1)
              : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? const Color(0xFFEA580C)
                : const Color(0xFF94A3B8),
          ),
        ),
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
