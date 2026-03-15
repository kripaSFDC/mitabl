import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';

class OrderCartPage extends StatelessWidget {
  const OrderCartPage({
    super.key,
    required this.session,
  });

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
          appBar: AppBar(
            title: Text(kitchen == null ? 'Your cart' : '${kitchen.name} cart'),
          ),
          body: session.cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Items',
                      style: GoogleFonts.gothicA1(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...session.cartItems.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartLine(
                          line: line,
                          onAdd: () => session.addItem(line.item),
                          onRemove: () => session.removeItem(line.item),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ServiceSection(session: session),
                    const SizedBox(height: 20),
                    _DateTimeSection(session: session),
                    if (session.serviceType == OrderServiceType.dineIn) ...[
                      const SizedBox(height: 20),
                      _PersonsSection(session: session),
                    ],
                    const SizedBox(height: 20),
                    _SummaryCard(session: session),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: session.canCheckout
                          ? () {
                              Navigator.of(context).pushNamed(
                                '/OrderCheckout',
                                arguments: RouteArguments(
                                  data: OrderRouteData(session: session),
                                ),
                              );
                            }
                          : null,
                      child: const Text('Review order'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.line,
    required this.onAdd,
    required this.onRemove,
  });

  final CartLineItem line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  style: GoogleFonts.gothicA1(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${line.item.price.toStringAsFixed(2)} each',
                  style: GoogleFonts.gothicA1(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.remove)),
          Text(
            '${line.quantity}',
            style: GoogleFonts.gothicA1(fontWeight: FontWeight.w700),
          ),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
          const SizedBox(width: 8),
          Text(
            '\$${line.lineTotal.toStringAsFixed(2)}',
            style: GoogleFonts.gothicA1(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final kitchen = session.kitchen;
    if (kitchen == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service type',
          style: GoogleFonts.gothicA1(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            if (kitchen.dineInAvailable)
              ChoiceChip(
                label: const Text('Dine in'),
                selected: session.serviceType == OrderServiceType.dineIn,
                onSelected: (_) =>
                    session.selectServiceType(OrderServiceType.dineIn),
              ),
            if (kitchen.takeAwayAvailable)
              ChoiceChip(
                label: const Text('Take away'),
                selected: session.serviceType == OrderServiceType.takeAway,
                onSelected: (_) =>
                    session.selectServiceType(OrderServiceType.takeAway),
              ),
          ],
        ),
      ],
    );
  }
}

class _DateTimeSection extends StatelessWidget {
  const _DateTimeSection({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final isDineIn = session.serviceType == OrderServiceType.dineIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup or table time',
          style: GoogleFonts.gothicA1(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: session.scheduledDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    if (!context.mounted) {
                      return;
                    }
                    session.updateScheduledDate(selected);
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  DateFormat('EEE, d MMM').format(session.scheduledDate),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isDineIn) ...[
          if (session.isLoadingDineInSlots) const LinearProgressIndicator(),
          if (session.isLoadingDineInSlots) const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey<String>(
              'dine-in-slot-${session.selectedDineInSlotId}-${session.dineInSlots.length}',
            ),
            initialValue: session.selectedDineInSlotId,
            items: session.dineInSlots
                .map(
                  (slot) => DropdownMenuItem<int>(
                    value: slot.id,
                    child: Text('${slot.startLabel} - ${slot.endLabel}'),
                  ),
                )
                .toList(growable: false),
            onChanged: session.dineInSlots.isEmpty
                ? null
                : (value) => session.selectDineInSlot(value),
            decoration: const InputDecoration(
              labelText: 'Available table slot',
              border: OutlineInputBorder(),
            ),
          ),
          if (session.dineInSlotError != null) ...[
            const SizedBox(height: 8),
            Text(
              session.dineInSlotError!,
              style: GoogleFonts.gothicA1(color: Colors.red.shade700),
            ),
          ],
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: session.scheduledTime.startHour,
                        minute: session.scheduledTime.startMinute,
                      ),
                    );
                    if (picked != null) {
                      final nextStartTotal = (picked.hour * 60) + picked.minute;
                      final currentEndTotal =
                          (session.scheduledTime.endHour * 60) +
                              session.scheduledTime.endMinute;
                      if (nextStartTotal >= currentEndTotal) {
                        final adjustedEndTotal = (nextStartTotal + 60)
                            .clamp(1, (23 * 60) + 59)
                            .toInt();
                        if (adjustedEndTotal <= nextStartTotal) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please choose a start time earlier in the day.',
                              ),
                            ),
                          );
                          return;
                        }
                        session.updateTime(
                          startHour: picked.hour,
                          startMinute: picked.minute,
                          endHour: adjustedEndTotal ~/ 60,
                          endMinute: adjustedEndTotal % 60,
                        );
                        return;
                      }
                      session.updateTime(
                        startHour: picked.hour,
                        startMinute: picked.minute,
                      );
                    }
                  },
                  child: Text('From ${session.scheduledTime.startLabel}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: session.scheduledTime.endHour,
                        minute: session.scheduledTime.endMinute,
                      ),
                    );
                    if (picked == null) {
                      return;
                    }
                    final startTotal = (session.scheduledTime.startHour * 60) +
                        session.scheduledTime.startMinute;
                    final endTotal = (picked.hour * 60) + picked.minute;
                    if (endTotal <= startTotal) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time.'),
                        ),
                      );
                      return;
                    }
                    session.updateTime(
                      endHour: picked.hour,
                      endMinute: picked.minute,
                    );
                  },
                  child: Text('To ${session.scheduledTime.endLabel}'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PersonsSection extends StatelessWidget {
  const _PersonsSection({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guests',
          style: GoogleFonts.gothicA1(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: () => session.updatePersons(session.persons - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${session.persons}',
              style: GoogleFonts.gothicA1(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => session.updatePersons(session.persons + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    final serviceLabel = session.serviceType == OrderServiceType.dineIn
        ? 'Dine in'
        : 'Take away';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order snapshot',
            style: GoogleFonts.gothicA1(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text('Service: $serviceLabel'),
          const SizedBox(height: 6),
          Text(
            'When: ${DateFormat('EEE, d MMM').format(session.scheduledDate)} '
            '${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}',
          ),
          if (session.serviceType == OrderServiceType.dineIn) ...[
            const SizedBox(height: 6),
            Text('Guests: ${session.persons}'),
          ],
          const SizedBox(height: 10),
          Text(
            'Items total: \$${session.itemTotal.toStringAsFixed(2)}',
            style: GoogleFonts.gothicA1(fontWeight: FontWeight.w700),
          ),
          if (session.taxTotal > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Estimated tax: \$${session.taxTotal.toStringAsFixed(2)}',
              style: GoogleFonts.gothicA1(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Estimated total: \$${session.estimatedTotal.toStringAsFixed(2)}',
            style: GoogleFonts.gothicA1(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
