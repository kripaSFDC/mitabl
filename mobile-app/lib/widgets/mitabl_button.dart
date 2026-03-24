import 'package:flutter/material.dart';
import 'design_tokens.dart';

enum MitablButtonVariant { primary, secondary, outline }

/// A pill-shaped (100px radius) button following the Warm Tactile design system.
///
/// - **primary**: Gradient from Roasted Earth to warm accent.
/// - **secondary**: Herb-green background.
/// - **outline**: Transparent with ghost border.
class MitablButton extends StatelessWidget {
  const MitablButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MitablButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MitablButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final foreground = switch (variant) {
      MitablButtonVariant.primary => MitablColors.onPrimary,
      MitablButtonVariant.secondary => MitablColors.onSecondaryContainer,
      MitablButtonVariant.outline => MitablColors.primary,
    };

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: icon!,
          ),
        Text(
          label,
          style: TextStyle(
            color: disabled ? foreground.withValues(alpha: 0.5) : foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: MitablRadius.pillBorder,
      side: variant == MitablButtonVariant.outline
          ? BorderSide(color: MitablColors.outlineVariant.withValues(alpha: 0.4))
          : BorderSide.none,
    );

    if (variant == MitablButtonVariant.primary) {
      return Container(
        width: fullWidth ? double.infinity : null,
        height: 52,
        decoration: BoxDecoration(
          gradient: disabled ? null : MitablColors.primaryGradient,
          color: disabled ? MitablColors.tertiaryFixedDim : null,
          borderRadius: MitablRadius.pillBorder,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: MitablRadius.pillBorder,
            child: Center(child: child),
          ),
        ),
      );
    }

    final bgColor = switch (variant) {
      MitablButtonVariant.secondary => MitablColors.secondaryContainer,
      MitablButtonVariant.outline => Colors.transparent,
      _ => MitablColors.primary,
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: foreground,
          shape: shape,
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
