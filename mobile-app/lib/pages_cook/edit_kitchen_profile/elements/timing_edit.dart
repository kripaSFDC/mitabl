import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class EditTimingDialog extends StatelessWidget {
  EditTimingDialog({super.key});

  final DateTime nowDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: MitablColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: MitablColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => navigatorKey.currentState!.pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: MitablColors.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your kitchen availability. Use breaks to manage peak prep times or staff shift changes.',
                    style: TextStyle(
                      fontSize: 15,
                      color: MitablColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Status card
                  _QuickStatusRow(daysTiming: state.daysTiming),
                  const SizedBox(height: 20),

                  // Day cards
                  Column(
                    children:
                        List.generate(state.daysTiming.length, (index) {
                      final day = state.daysTiming[index];
                      final isOn = day.isOn ?? false;
                      final dayLabel = _dayAbbrev(day.day.toString());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isOn
                                ? MitablColors.surfaceContainerLowest
                                : MitablColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isOn
                                ? [
                                    BoxShadow(
                                      color: MitablColors.onSurface
                                          .withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              // Day name + toggle row
                              Row(
                                children: [
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isOn
                                            ? MitablColors.primary
                                            : MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  // Custom toggle
                                  GestureDetector(
                                    onTap: () {
                                      context
                                          .read<EditKitchenProfileCubit>()
                                          .onSwitchChanged(
                                            index: index,
                                            switchValue: !isOn,
                                          );
                                    },
                                    child: Container(
                                      width: 56,
                                      height: 32,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isOn
                                            ? MitablColors.primary
                                            : const Color(0xFFE5E2DD),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: AnimatedAlign(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        alignment: isOn
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: MitablColors.onSurface
                                                    .withValues(alpha: 0.10),
                                                blurRadius: 4,
                                                offset:
                                                    const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isOn ? 'Open' : 'Closed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isOn
                                          ? MitablColors.onSurface
                                          : MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isOn)
                                    TextButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Break scheduling coming soon'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add,
                                          size: 14,
                                          color: MitablColors.primary),
                                      label: const Text(
                                        'Add break',
                                        style: TextStyle(
                                          color: MitablColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFFDBD0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              MitablRadius.pillBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                ],
                              ),

                              // Time pickers (when open)
                              if (isOn) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TimePickerBox(
                                        label: 'START TIME',
                                        icon: Icons.schedule,
                                        time:
                                            day.timing?.startTime ?? '--:--',
                                        onTap: () {
                                          _showTimePicker(
                                            context: context,
                                            index: index,
                                            day: day,
                                            isStart: true,
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Container(
                                        width: 8,
                                        height: 2,
                                        color: MitablColors.outlineVariant,
                                      ),
                                    ),
                                    Expanded(
                                      child: _TimePickerBox(
                                        label: 'END TIME',
                                        icon: Icons.bedtime_outlined,
                                        time: day.timing?.endTime ?? '--:--',
                                        onTap: () {
                                          _showTimePicker(
                                            context: context,
                                            index: index,
                                            day: day,
                                            isStart: false,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D6548),
                        borderRadius: MitablRadius.pillBorder,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4D6548)
                                .withValues(alpha: 0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: MitablRadius.pillBorder,
                          onTap: () {
                            context
                                .read<EditKitchenProfileCubit>()
                                .onApplyDays();
                          },
                          child: const Center(
                            child: Text(
                              'Save All Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _dayAbbrev(String dayName) {
    if (dayName.length >= 3) {
      return dayName.substring(0, 3).toUpperCase();
    }
    return dayName.toUpperCase();
  }

  void _showTimePicker({
    required BuildContext context,
    required int index,
    required dynamic day,
    required bool isStart,
  }) {
    String date = DateFormat('yyyy-MM-dd ').format(nowDate);
    String datePrevious;
    if (isStart) {
      datePrevious = date + (day.timing?.startTime ?? '00:00');
    } else {
      datePrevious = date + (day.timing?.endTime ?? '23:59');
    }
    DateTime previousTime = DateTime.parse(datePrevious);

    _showDialog(
      CupertinoDatePicker(
        initialDateTime: previousTime,
        mode: CupertinoDatePickerMode.time,
        use24hFormat: true,
        onDateTimeChanged: (DateTime newTime) {
          if (isStart) {
            String dateStr = DateFormat('yyyy-MM-dd ').format(newTime);
            String dateEnd = dateStr + (day.timing?.endTime ?? '23:59');
            DateTime endTime = DateTime.parse(dateEnd);
            if (newTime.isBefore(endTime)) {
              context.read<EditKitchenProfileCubit>().onSwitchChanged(
                    index: index,
                    startTime: DateFormat('HH:mm').format(newTime),
                  );
            }
          } else {
            String dateStr = DateFormat('yyyy-MM-dd ').format(newTime);
            String dateStart = dateStr + (day.timing?.startTime ?? '00:00');
            DateTime startTime = DateTime.parse(dateStart);
            if (newTime.isAfter(startTime)) {
              context.read<EditKitchenProfileCubit>().onSwitchChanged(
                    index: index,
                    endTime: DateFormat('HH:mm').format(newTime),
                  );
            }
          }
        },
      ),
      context,
    );
  }

  void _showDialog(Widget child, BuildContext? context) {
    showCupertinoModalPopup<void>(
      context: context!,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

class _QuickStatusRow extends StatelessWidget {
  const _QuickStatusRow({required this.daysTiming});

  final List daysTiming;

  @override
  Widget build(BuildContext context) {
    int totalMinutes = 0;
    final List<String> openDayNames = [];

    for (final day in daysTiming) {
      if (day.isOn == true) {
        final name = (day.day ?? '').toString();
        if (name.length >= 3) {
          openDayNames.add(name.substring(0, 3));
        }
        final timing = day.timing;
        if (timing != null &&
            timing.startTime != null &&
            timing.endTime != null) {
          try {
            final startParts = timing.startTime!.split(':');
            final endParts = timing.endTime!.split(':');
            final startMins =
                int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
            final endMins =
                int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
            if (endMins > startMins) {
              totalMinutes += (endMins - startMins);
            }
          } catch (_) {}
        }
      }
    }

    final totalHours = totalMinutes ~/ 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MitablColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Status',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Total',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: MitablColors.onSecondaryContainer
                      .withValues(alpha: 0.80),
                ),
              ),
              Text(
                '$totalHours Hours',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: MitablColors.onSecondaryContainer
                      .withValues(alpha: 0.80),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.40),
                  borderRadius: MitablRadius.pillBorder,
                ),
                child: Text(
                  openDayNames.isNotEmpty ? 'LIVE NOW' : 'CLOSED',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSecondaryContainer,
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

class _TimePickerBox extends StatelessWidget {
  const _TimePickerBox({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: MitablColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MitablColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
