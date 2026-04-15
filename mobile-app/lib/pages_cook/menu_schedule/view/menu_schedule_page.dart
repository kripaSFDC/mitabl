import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/model/food_menu.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class MenuSchedulePage extends StatelessWidget {
  const MenuSchedulePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/MenuSchedule'),
      builder: (_) => const MenuSchedulePage(),
    );
  }

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.background,
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: BlocBuilder<AddMenuCubit, AddMenuState>(
              builder: (context, state) {
                if (state.foodMenuStatus!.isSubmissionInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = state.foodMenu?.foodData ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No menu items yet.',
                      style: TextStyle(
                        fontSize: 15,
                        color: MitablColors.secondary,
                      ),
                    ),
                  );
                }

                final scheduled = items
                    .where((item) => _hasSchedule(item))
                    .toList(growable: false);
                final alwaysAvailable = items
                    .where((item) => !_hasSchedule(item))
                    .toList(growable: false);

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AddMenuCubit>().getFoodMenu();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      if (scheduled.isNotEmpty) ...[
                        const _SectionLabel(text: 'SCHEDULED ITEMS'),
                        const SizedBox(height: 8),
                        ...scheduled.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScheduledItemCard(item: item),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (alwaysAvailable.isNotEmpty) ...[
                        const _SectionLabel(text: 'ALWAYS AVAILABLE'),
                        const SizedBox(height: 8),
                        ...alwaysAvailable.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AlwaysAvailableCard(item: item),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static bool _hasSchedule(FoodData item) {
    return (item.availableDate != null && item.availableDate!.isNotEmpty) ||
        (item.availableDays != null && item.availableDays!.isNotEmpty) ||
        (item.availableFromTime != null &&
            item.availableFromTime!.isNotEmpty) ||
        (item.availableToTime != null && item.availableToTime!.isNotEmpty);
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: MitablColors.surface.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
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
                child: Icon(Icons.arrow_back, size: 24, color: MitablColors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Menu Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: MitablColors.secondary,
      ),
    );
  }
}

class _ScheduledItemCard extends StatelessWidget {
  const _ScheduledItemCard({required this.item});

  final FoodData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MitablColors.surface,
        borderRadius: BorderRadius.circular(MitablRadius.card),
        boxShadow: [
          BoxShadow(
            color: MitablColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName ?? 'Unnamed item',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                      ),
                    ),
                    if (item.price != null)
                      Text(
                        'AUD ${item.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MitablColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status == 1
                      ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                      : MitablColors.errorContainer,
                  borderRadius: BorderRadius.circular(MitablRadius.chipSmall),
                ),
                child: Text(
                  item.status == 1 ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.status == 1
                        ? const Color(0xFF16A34A)
                        : MitablColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (item.availableDate != null && item.availableDate!.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.event,
              label: 'Date',
              value: item.availableDate!,
            ),
            const SizedBox(height: 6),
          ],

          if (item.availableDays != null && item.availableDays!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _DayChips(activeDays: item.availableDays!),
            const SizedBox(height: 8),
          ],

          if ((item.availableFromTime != null &&
                  item.availableFromTime!.isNotEmpty) ||
              (item.availableToTime != null &&
                  item.availableToTime!.isNotEmpty))
            _DetailRow(
              icon: Icons.schedule,
              label: 'Time',
              value: _formatTimeRange(
                item.availableFromTime,
                item.availableToTime,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTimeRange(String? from, String? to) {
    final fromLabel =
        (from != null && from.isNotEmpty) ? _formatTime(from) : 'Open';
    final toLabel =
        (to != null && to.isNotEmpty) ? _formatTime(to) : 'Close';
    return '$fromLabel — $toLabel';
  }

  static String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.activeDays});

  final List<int> activeDays;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final isActive = activeDays.contains(index);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive
                  ? MitablColors.primary.withValues(alpha: 0.12)
                  : MitablColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? MitablColors.primary
                      : MitablColors.secondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MitablColors.secondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MitablColors.secondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: MitablColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlwaysAvailableCard extends StatelessWidget {
  const _AlwaysAvailableCard({required this.item});

  final FoodData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MitablColors.surface,
        borderRadius: BorderRadius.circular(MitablRadius.card),
        border: Border.all(color: MitablColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName ?? 'Unnamed item',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSurface,
                  ),
                ),
                if (item.price != null)
                  Text(
                    'AUD ${item.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: MitablColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MitablColors.secondaryContainer,
              borderRadius: BorderRadius.circular(MitablRadius.chipSmall),
            ),
            child: const Text(
              'All days',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MitablColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
