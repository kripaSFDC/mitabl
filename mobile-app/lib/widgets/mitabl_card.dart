import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// A warm, 20px-radius card that uses tonal layering instead of drop shadows.
/// Place on a [MitablColors.surfaceContainerLow] background for the best effect.
class MitablCard extends StatelessWidget {
  const MitablCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.useGhostBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  /// When true, adds a subtle 15%-opacity outline-variant border for
  /// accessibility.
  final bool useGhostBorder;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? MitablColors.surfaceContainerLowest,
      borderRadius: MitablRadius.cardBorder,
      border: useGhostBorder ? MitablShadows.ghostBorder : null,
    );

    final content = Container(
      margin: margin,
      decoration: decoration,
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(MitablSpacing.cardPadding),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: MitablRadius.cardBorder,
          child: content,
        ),
      );
    }

    return content;
  }
}
