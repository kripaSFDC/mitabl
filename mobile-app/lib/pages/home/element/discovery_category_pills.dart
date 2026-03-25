import 'package:flutter/material.dart';
import 'package:mitabl_user/model/cooking_style.dart';

/// Horizontal scrolling category filter chips for the discovery feed.
/// Design: h-9 rounded-full pills, active = bg-primary text-white,
/// inactive = bg-surface text-text-muted border border-text-muted/20.
class DiscoveryCategoryPills extends StatelessWidget {
  const DiscoveryCategoryPills({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CookingStyleData>? categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = categories ?? const [];

    return Container(
      height: 50,
      color: const Color(0xFFFFFFFF), // background-light
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEA580C) // primary
                      : const Color(0xFFFFFFFF), // surface
                  borderRadius: BorderRadius.circular(100),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: const Color(0xFF64748B)
                              .withValues(alpha: 0.2),
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B), // text-muted
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
