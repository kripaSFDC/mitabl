import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// A visual credit card widget with a gradient background showing card details.
class VisualCreditCard extends StatelessWidget {
  const VisualCreditCard({
    super.key,
    this.brand = 'Card',
    this.last4 = '',
    this.expMonth = '',
    this.expYear = '',
    this.cardholderName = '',
  });

  final String brand;
  final String last4;
  final String expMonth;
  final String expYear;
  final String cardholderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: MitablColors.primaryGradient,
        borderRadius: BorderRadius.circular(MitablRadius.card),
        boxShadow: MitablShadows.ambient,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand icon and name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _brandIcon(brand),
                color: Colors.white,
                size: 32,
              ),
              Text(
                brand.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Masked card number
          Text(
            last4.isNotEmpty
                ? '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  $last4'
                : '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 16),

          // Expiry and cardholder name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expMonth.isNotEmpty && expYear.isNotEmpty
                        ? '$expMonth/$expYear'
                        : 'MM/YY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  cardholderName.isNotEmpty
                      ? cardholderName.toUpperCase()
                      : 'CARDHOLDER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _brandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}
