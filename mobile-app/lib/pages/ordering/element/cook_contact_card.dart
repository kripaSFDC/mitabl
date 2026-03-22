import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

/// Cook info card showing avatar, name, rating, and a "Message" button.
class CookContactCard extends StatelessWidget {
  const CookContactCard({
    super.key,
    required this.cookName,
  });

  final String cookName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MitablSpacing.cardPadding),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: MitablRadius.cardBorder,
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          const CircleAvatar(
            radius: 24,
            backgroundColor: MitablColors.surfaceContainerLow,
            child: Icon(
              Icons.person,
              size: 28,
              color: MitablColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),

          // Cook info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cookName,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        size: 14,
                        color: Colors.amber.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '120+ meals',
                      style: TextStyle(
                        fontSize: 12,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message button
          MitablButton(
            label: 'Message',
            fullWidth: false,
            variant: MitablButtonVariant.secondary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}
