import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Slide to confirm payment widget.
/// Draggable thumb slides from left to right. When it passes 80% of track
/// width, the [onConfirmed] callback fires. If released early, the thumb
/// animates back.
class SlideToPayButton extends StatefulWidget {
  const SlideToPayButton({
    super.key,
    required this.amount,
    required this.onConfirmed,
  });

  final double amount;
  final VoidCallback onConfirmed;

  @override
  State<SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<SlideToPayButton>
    with SingleTickerProviderStateMixin {
  static const double _trackHeight = 56.0;
  static const double _thumbSize = 48.0;
  static const double _triggerFraction = 0.80;

  late final AnimationController _resetController;
  double _dragOffset = 0.0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          _dragOffset = _dragOffset * (1 - _resetController.value);
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  double _maxDrag(double trackWidth) {
    return trackWidth - _thumbSize - 8; // 4px padding on each side
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = _maxDrag(trackWidth);

        return Container(
          height: _trackHeight,
          decoration: const BoxDecoration(
            color: MitablColors.surfaceContainerLow,
            borderRadius: MitablRadius.pillBorder,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered text
              Text(
                'Slide to Pay \$${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),

              // Draggable thumb
              Positioned(
                left: 4 + _dragOffset,
                child: GestureDetector(
                  onHorizontalDragUpdate: _confirmed
                      ? null
                      : (details) {
                          setState(() {
                            _dragOffset =
                                (_dragOffset + details.delta.dx).clamp(0, maxDrag);
                          });
                        },
                  onHorizontalDragEnd: _confirmed
                      ? null
                      : (_) {
                          if (_dragOffset >= maxDrag * _triggerFraction) {
                            setState(() {
                              _confirmed = true;
                              _dragOffset = maxDrag;
                            });
                            widget.onConfirmed();
                          } else {
                            final startOffset = _dragOffset;
                            _resetController.reset();
                            _resetController.forward().then((_) {
                              if (mounted) {
                                setState(() => _dragOffset = 0);
                              }
                            });
                            // Use the start offset for smooth animation
                            _dragOffset = startOffset;
                          }
                        },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      gradient: MitablColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: MitablColors.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
