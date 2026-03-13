import 'package:flutter/material.dart';

/// A semantics-aware tap target wrapper.
///
/// Use this whenever you build a custom tappable widget (icon, image-button,
/// branded tile, etc.) to ensure screen readers can announce a meaningful
/// label.
///
/// ```dart
/// SemanticButton(
///   label: 'Add to cart',
///   onTap: _addToCart,
///   child: Icon(Icons.add_shopping_cart),
/// )
/// ```
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.hint,
    this.enabled = true,
    this.excludeSemantics = false,
  });

  /// Accessible label announced by the screen reader (required).
  final String label;

  /// Optional hint (e.g., "double-tap to select").
  final String? hint;
  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;

  /// Set to `true` if descendant widgets already carry their own semantics.
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      excludeSemantics: excludeSemantics,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}

/// Wraps an [Image], [SvgPicture], or [CachedNetworkImage] with a semantic
/// label. Pass [decorative] as `true` to hide purely decorative images from
/// the accessibility tree.
class SemanticImage extends StatelessWidget {
  const SemanticImage({
    super.key,
    required this.label,
    required this.child,
    this.decorative = false,
  });

  final String label;
  final Widget child;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: decorative ? null : label,
      image: true,
      excludeSemantics: true,
      child: ExcludeSemantics(
        excluding: decorative,
        child: child,
      ),
    );
  }
}
