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
          _ReceiptRow(label: 'Subtotal', value: itemTotal),
          const SizedBox(height: 8),
          _ReceiptRow(label: 'Taxes', value: taxTotal),
          const SizedBox(height: 8),
          const _ReceiptRow(label: 'Community Fee', value: _communityFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: MitablColors.outlineVariant,
            ),
          ),
          _ReceiptRow(
            label: 'Total',
            value: grandTotal,
            isBold: true,
            isLarger: true,
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
    this.isLarger = false,
  });

  final String label;
  final double value;
  final bool isBold;
  final bool isLarger;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: isLarger ? 17 : 14,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: MitablColors.onSurface,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('\$${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
