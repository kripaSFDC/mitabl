import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Receipt breakdown showing subtotal, taxes, community fee, and total.
class CheckoutReceipt extends StatelessWidget {
  const CheckoutReceipt({
    super.key,
    required this.itemTotal,
    required this.taxTotal,
    required this.estimatedTotal,
  });

  final double itemTotal;
  final double taxTotal;
  final double estimatedTotal;

  static const double _communityFee = 1.50;

  @override
  Widget build(BuildContext context) {
    final grandTotal = estimatedTotal + _communityFee;

    return Container(
      padding: const EdgeInsets.all(MitablSpacing.cardPadding),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: MitablRadius.cardBorder,
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Subtotal: 14pt, normal weight, onSurfaceVariant
          _ReceiptRow(label: 'Subtotal', value: itemTotal),
          const SizedBox(height: 8),
          // Taxes: 14pt, normal weight, onSurfaceVariant
          _ReceiptRow(label: 'Taxes', value: taxTotal),
          const SizedBox(height: 8),
          // Community Fee: 14pt, normal weight, onSurfaceVariant
          const _ReceiptRow(label: 'Community Fee', value: _communityFee),
          // Divider before total row
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: MitablColors.outlineVariant,
            ),
          ),
          // Total row: 18pt, w700 for both label and amount
          _ReceiptRow(
            label: 'Total',
            value: grandTotal,
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isBold;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: isTotal ? 18 : 14,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
      color: isTotal ? MitablColors.onSurface : MitablColors.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('\$${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
