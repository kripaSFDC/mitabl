import 'package:flutter/material.dart';

/// Receipt breakdown: "RECEIPT" header, subtotal, taxes, community fee, divider, total.
/// Design: bg-surface rounded-2xl p-4 shadow-soft.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // surface
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "RECEIPT" header
          const Text(
            'RECEIPT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Color(0xFF64748B), // text-muted
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal
          _ReceiptRow(
            label: 'Subtotal',
            value: itemTotal,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(height: 8),

          // Taxes
          _ReceiptRow(
            label: 'Taxes',
            value: taxTotal,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 8),

          // Community Fee
          const _ReceiptRow(
            label: 'Community Fee',
            value: _communityFee,
            color: Color(0xFF64748B),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '\$${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
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
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }
}
