import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

class EditTimingDialog extends StatelessWidget {
  EditTimingDialog({super.key});

  final DateTime nowDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: MitablColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Operating Hours',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: MitablColors.onSurface,
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
                  const SizedBox(height: 16),

                  // Quick Status summary row
                  _QuickStatusRow(daysTiming: state.daysTiming),

                  const SizedBox(height: 16),

                  // Day rows
                  Column(
                    children: List.generate(state.daysTiming.length, (index) {
                      final day = state.daysTiming[index];
                      final isOn = day.isOn ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            // Day name + switch row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _dayAbbrev(day.day.toString()),
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isOn,
                                  activeThumbColor: MitablColors.accent,
                                  onChanged: (val) {
                                    context
                                        .read<EditKitchenProfileCubit>()
                                        .onSwitchChanged(
                                          index: index,
                                          switchValue: val,
                                        );
                                  },
                                ),
                              ],
                            ),

                            // Time row or closed text
                            if (isOn)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Start time box
                                        _TimeBox(
                                          time: day.timing?.startTime ?? '--:--',
                                          onTap: () {
                                            String date = DateFormat(
                                              'yyyy-MM-dd ',
                                            ).format(nowDate);
                                            String datePreviousStart =
                                                date + (day.timing?.startTime ?? '00:00');
                                            DateTime startPreviousTime =
                                                DateTime.parse(datePreviousStart);

                                            _showDialog(
                                              CupertinoDatePicker(
                                                initialDateTime: startPreviousTime,
                                                mode: CupertinoDatePickerMode.time,
                                                use24hFormat: true,
                                                onDateTimeChanged: (DateTime newTime) {
                                                  String date = DateFormat(
                                                    'yyyy-MM-dd ',
                                                  ).format(newTime);
                                                  String dateStart =
                                                      date + (day.timing?.endTime ?? '23:59');
                                                  DateTime startTime =
                                                      DateTime.parse(dateStart);

                                                  if (newTime.isBefore(startTime)) {
                                                    context
                                                        .read<EditKitchenProfileCubit>()
                                                        .onSwitchChanged(
                                                          index: index,
                                                          startTime: DateFormat('HH:mm')
                                                              .format(newTime),
                                                        );
                                                  }
                                                },
                                              ),
                                              context,
                                            );
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            'to',
                                            style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              color: MitablColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        // End time box
                                        _TimeBox(
                                          time: day.timing?.endTime ?? '--:--',
                                          onTap: () {
                                            String date = DateFormat(
                                              'yyyy-MM-dd ',
                                            ).format(nowDate);
                                            String datePreviousEnd =
                                                date + (day.timing?.endTime ?? '23:59');
                                            DateTime endPreviousTime =
                                                DateTime.parse(datePreviousEnd);

                                            _showDialog(
                                              CupertinoDatePicker(
                                                initialDateTime: endPreviousTime,
                                                mode: CupertinoDatePickerMode.time,
                                                use24hFormat: true,
                                                onDateTimeChanged: (DateTime newTime) {
                                                  String date = DateFormat(
                                                    'yyyy-MM-dd ',
                                                  ).format(newTime);
                                                  String dateStart =
                                                      date + (day.timing?.startTime ?? '00:00');
                                                  DateTime startTime =
                                                      DateTime.parse(dateStart);
                                                  if (newTime.isAfter(startTime)) {
                                                    context
                                                        .read<EditKitchenProfileCubit>()
                                                        .onSwitchChanged(
                                                          index: index,
                                                          endTime: DateFormat('HH:mm')
                                                              .format(newTime),
                                                        );
                                                  }
                                                },
                                              ),
                                              context,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    // Add Break button
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Break scheduling coming soon'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '+ Add Break',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: MitablColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Closed',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: MitablColors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),

                            if (index < state.daysTiming.length - 1)
                              const Divider(
                                height: 8,
                                color: MitablColors.outlineVariant,
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Apply button
                  MitablButton(
                    label: 'Apply',
                    variant: MitablButtonVariant.primary,
                    fullWidth: true,
                    onPressed: () {
                      context.read<EditKitchenProfileCubit>().onApplyDays();
                    },
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

  void _showDialog(Widget child, BuildContext? context) {
    showCupertinoModalPopup<void>(
      context: context!,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
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
    // Count open days
    int totalMinutes = 0;
    final List<String> openDayNames = [];

    for (final day in daysTiming) {
      if (day.isOn == true) {
        final name = (day.day ?? '').toString();
        if (name.length >= 3) {
          openDayNames.add(name.substring(0, 3));
        }
        // Calculate hours from timing
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

    // Build summary label e.g. "Open Mon-Sat . 64hrs/week"
    String dayRange;
    if (openDayNames.isEmpty) {
      dayRange = 'Closed all week';
    } else if (openDayNames.length == 7) {
      dayRange = 'Open every day';
    } else if (openDayNames.length == 1) {
      dayRange = 'Open ${openDayNames.first}';
    } else {
      dayRange = 'Open ${openDayNames.first}-${openDayNames.last}';
    }

    final hoursLabel = totalHours > 0 ? ' \u00B7 ${totalHours}hrs/week' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MitablColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            size: 18,
            color: MitablColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dayRange$hoursLabel',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MitablColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.time, required this.onTap});

  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: MitablColors.onSurface,
          ),
        ),
      ),
    );
  }
}
