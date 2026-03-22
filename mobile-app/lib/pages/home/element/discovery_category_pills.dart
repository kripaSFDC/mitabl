import 'package:flutter/material.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

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
          if (index == 0) {
            // "All" chip
            return MitablChip(
              label: 'All',
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            );
          }

          final item = items[index - 1];
          return MitablChip(
            label: item.name ?? '',
            selected: selectedId == item.id,
            onSelected: (_) => onSelected(item.id),
          );
        },
      ),
    );
  }
}
