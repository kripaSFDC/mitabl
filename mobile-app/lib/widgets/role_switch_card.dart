import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class RoleSwitchCard extends StatelessWidget {
  const RoleSwitchCard({
    required this.actionText,
    required this.isDisabled,
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final String actionText;
  final bool isDisabled;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDisabled ? MitablColors.surfaceContainerLow : null,
        gradient: isDisabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MitablColors.primaryFixed.withValues(alpha: 0.65),
                  MitablColors.surfaceContainerLowest,
                ],
              ),
        border: Border.all(
          color: isDisabled
              ? MitablColors.outlineVariant
              : MitablColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(MitablRadius.card),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MitablRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MitablSpacing.cardPadding + 4,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? MitablColors.surfaceContainerHighest
                        : MitablColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDisabled
                          ? MitablColors.outlineVariant
                          : MitablColors.primary.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horizontal_circle_rounded,
                    size: 26,
                    color: isDisabled
                        ? MitablColors.onSurfaceVariant
                        : MitablColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Switch Profile Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurfaceVariant,
                          fontFamily: 'DM Sans',
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurface,
                          fontFamily: 'DM Sans',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MitablColors.primary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? MitablColors.surfaceContainerHighest
                          : MitablColors.primary,
                      borderRadius: BorderRadius.circular(MitablRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.compare_arrows_rounded,
                          size: 16,
                          color: isDisabled
                              ? MitablColors.onSurfaceVariant
                              : MitablColors.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDisabled
                                ? MitablColors.onSurfaceVariant
                                : MitablColors.onPrimary,
                            fontFamily: 'DM Sans',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}