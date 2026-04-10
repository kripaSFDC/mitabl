import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Bottom navigation bar item definition.
class MitablNavItem {
  const MitablNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// A warm, tactile bottom navigation bar with no elevation,
/// using tonal layering and the design system colors.
class MitablBottomNav extends StatelessWidget {
  const MitablBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MitablNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: MitablColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: '${item.label} tab',
                  hint: isActive
                      ? 'Current tab'
                      : 'Double tap to switch to ${item.label}',
                  child: InkWell(
                    onTap: () => onTap(index),
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 24,
                            color: isActive
                                ? MitablColors.primary
                                : MitablColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive
                                  ? MitablColors.primary
                                  : MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
