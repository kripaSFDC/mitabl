import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// A row widget displaying a single transaction with icon, description,
/// date and amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
  });

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final amount = (transaction['amount'] ?? '').toString();
    final description =
        (transaction['description'] ?? transaction['status'] ?? 'Payment')
            .toString();
    final date = (transaction['date'] ?? transaction['created_at'] ?? '')
        .toString();
    final status = (transaction['status'] ?? '').toString().toLowerCase();

    final isSuccess = status.contains('success') || status.contains('paid');

    return MitablCard(
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSuccess
                  ? MitablColors.accent.withValues(alpha: 0.1)
                  : MitablColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_outline : Icons.payment,
              color: isSuccess ? MitablColors.accent : MitablColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Description and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Amount
          if (amount.isNotEmpty)
            Text(
              '\$$amount',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
        ],
      ),
    );
  }
}
