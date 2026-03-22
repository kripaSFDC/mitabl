import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Status of an individual timeline step.
enum TimelineStepStatus { completed, active, pending }

/// Data for a single timeline step.
class TimelineStepData {
  const TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final TimelineStepStatus status;
}

/// Vertical 4-step timeline showing order progress.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.steps,
  });

  final List<TimelineStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicator column
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    _StepIndicator(status: step.status),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.status == TimelineStepStatus.completed
                              ? MitablColors.primary
                              : MitablColors.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: step.status == TimelineStepStatus.pending
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: step.status == TimelineStepStatus.pending
                              ? MitablColors.onSurfaceVariant
                              : MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.status});

  final TimelineStepStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TimelineStepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: MitablColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: MitablColors.onPrimary),
        );

      case TimelineStepStatus.active:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: MitablColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: MitablColors.primary, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: MitablColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

      case TimelineStepStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: MitablColors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: MitablColors.outlineVariant, width: 2),
          ),
        );
    }
  }
}
