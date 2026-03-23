import 'package:flutter/material.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Horizontal scrolling category filter chips for the discovery feed.
///
/// Prepends a hardcoded "All" chip (id: null). When "All" is selected
/// [selectedId] should be null.
class DiscoveryCategoryPills extends StatelessWidget {
  const DiscoveryCategoryPills({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  /// List of cooking style items (id, name).
  final List<CookingStyleData>? categories;

  /// Currently selected category id. Null means "All".
  final int? selectedId;

  /// Called with the id of the selected category (null for "All").
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = categories ?? const [];

    return Container(
      height: 50,
      color: MitablColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: MitablSpacing.pagePadding,
        ),
        itemCount: items.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isSelected;
          final String label;
          final VoidCallback onTap;

          if (index == 0) {
            label = 'All';
            isSelected = selectedId == null;
            onTap = () => onSelected(null);
          } else {
            final item = items[index - 1];
            label = item.name ?? '';
            isSelected = selectedId == item.id;
            onTap = () => onSelected(item.id);
          }

          return GestureDetector(
            onTap: onTap,
            child: Center(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MitablColors.primary
                      : MitablColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? MitablColors.onPrimary
                        : MitablColors.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
