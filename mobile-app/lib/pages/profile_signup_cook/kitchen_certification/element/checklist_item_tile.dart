import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

/// A simple row with a checkbox and a title label, optionally showing a status chip.
class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.statusLabel,
    this.statusSelected = false,
  });

  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? statusLabel;
  final bool statusSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: MitablColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(
                color: MitablColors.outlineVariant,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MitablColors.onSurface,
                decoration: value ? TextDecoration.lineThrough : null,
                decorationColor: MitablColors.onSurfaceVariant,
              ),
            ),
          ),
          if (statusLabel != null)
            MitablChip(
              label: statusLabel!,
              selected: statusSelected,
            ),
        ],
      ),
    );
  }
}
