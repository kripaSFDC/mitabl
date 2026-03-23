import 'package:flutter/material.dart';

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
/// Design: border-l-2 vertical stepper, ml-4, space-y-8.
/// Completed: filled primary circle with border-4 border-background-light.
/// Active: pulsing primary circle with glow shadow.
/// Pending: filled slate-200 circle with border-4 border-background-light, content opacity-50.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.steps,
  });

  final List<TimelineStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: indicator dot + connecting line
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      _StepDot(status: step.status),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: step.status == TimelineStepStatus.completed
                                ? const Color(0xFFEF6034) // primary
                                : const Color(0xFFE2E8F0), // slate-200
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                    child: Opacity(
                      opacity: step.status == TimelineStepStatus.pending
                          ? 0.5
                          : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: step.status == TimelineStepStatus.active
                                  ? const Color(0xFFEF6034) // primary for active
                                  : const Color(0xFF0F172A), // slate-900
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: step.status == TimelineStepStatus.active
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: step.status == TimelineStepStatus.active
                                  ? const Color(0xFF475569) // slate-600
                                  : const Color(0xFF64748B), // slate-500
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Step dot indicator matching the HTML design.
class _StepDot extends StatefulWidget {
  const _StepDot({required this.status});

  final TimelineStepStatus status;

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.status == TimelineStepStatus.active) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
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
    const bgColor = Color(0xFFF8F6F6); // background-light

    switch (widget.status) {
      case TimelineStepStatus.completed:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFEF6034), // primary
            shape: BoxShape.circle,
            border: Border.all(color: bgColor, width: 4),
          ),
        );

      case TimelineStepStatus.active:
        final controller = _pulseController!;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Outer pulse ring
                Positioned(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6034)
                          .withValues(alpha: 0.3 * controller.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Inner dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF6034),
                    shape: BoxShape.circle,
                    border: Border.all(color: bgColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF6034).withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );

      case TimelineStepStatus.pending:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0), // slate-200
            shape: BoxShape.circle,
            border: Border.all(color: bgColor, width: 4),
          ),
        );
    }
  }
}
