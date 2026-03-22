import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// A pill-shaped selectable chip following the Warm Tactile design system.
/// Unselected: tertiary-fixed-dim background. Selected: primary background.
class MitablChip extends StatelessWidget {
  const MitablChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon,
      backgroundColor: MitablColors.tertiaryFixedDim,
      selectedColor: MitablColors.primary,
      labelStyle: TextStyle(
        color: selected ? MitablColors.onPrimary : MitablColors.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      checkmarkColor: MitablColors.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: MitablRadius.pillBorder,
        side: BorderSide.none,
      ),
      side: BorderSide.none,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
