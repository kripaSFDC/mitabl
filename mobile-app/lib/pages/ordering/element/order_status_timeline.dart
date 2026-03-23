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
              // Indicator column - 32px wide
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
                      // Step title: 15pt, w600
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: step.status == TimelineStepStatus.pending
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: step.status == TimelineStepStatus.pending
                              ? MitablColors.onSurfaceVariant
                              : MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Step subtitle: 13pt, onSurfaceVariant
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

/// 32px diameter step indicator with appropriate styling per status.
class _StepIndicator extends StatefulWidget {
  const _StepIndicator({required this.status});

  final TimelineStepStatus status;

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.status == TimelineStepStatus.active) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    } else {
      _pulseController = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.status) {
      case TimelineStepStatus.completed:
        // Filled primary circle with white check icon - 32px
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: MitablColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 18,
            color: MitablColors.onPrimary,
          ),
        );

      case TimelineStepStatus.active:
        // Pulsing primary circle
        final controller = _pulseController!;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final scale = 1.0 + (controller.value * 0.15);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MitablColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: MitablColors.primary, width: 2.5),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: MitablColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case TimelineStepStatus.pending:
        // Outlined circle in outlineVariant - 32px
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: MitablColors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: MitablColors.outlineVariant, width: 2),
          ),
        );
    }
  }
}
