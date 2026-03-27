import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Slide to confirm payment widget.
/// Design: h-14 bg-surface rounded-full, border border-primary/20,
/// skillet icon on draggable thumb, "Slide to Pay $xx.xx" centered text,
/// double arrow right icon pulsing.
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
    with TickerProviderStateMixin {
  static const double _trackHeight = 56.0;
  static const double _thumbSize = 48.0;
  static const double _triggerFraction = 0.80;

  late final AnimationController _resetController;
  late final AnimationController _pulseController;
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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pulseController.dispose();
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
          decoration: BoxDecoration(
            color: Colors.white, // surface
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFFEA580C).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered text with pulsing arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Slide to Pay \$${widget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: const Color(0xFFEA580C).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.4 + (_pulseController.value * 0.4),
                        child: Icon(
                          Icons.keyboard_double_arrow_right,
                          size: 20,
                          color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Draggable thumb with skillet icon
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
                            HapticFeedback.mediumImpact();
                            widget.onConfirmed();
                          } else {
                            final startOffset = _dragOffset;
                            _resetController.reset();
                            _resetController.forward().then((_) {
                              if (mounted) {
                                setState(() => _dragOffset = 0);
                              }
                            });
                            _dragOffset = startOffset;
                          }
                        },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C), // primary
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.soup_kitchen,
                        color: Colors.white,
                        size: 24,
                      ),
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
