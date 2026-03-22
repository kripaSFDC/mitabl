import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Bottom bar showing cart total. Only visible when session.totalItems > 0.
class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({
    super.key,
    required this.session,
  });

  final OrderSessionController session;

  @override
  Widget build(BuildContext context) {
    if (session.totalItems <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: MitablSpacing.pagePadding,
      right: MitablSpacing.pagePadding,
      bottom: MediaQuery.of(context).padding.bottom + 12,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/OrderCart',
            arguments: RouteArguments(
              data: OrderRouteData(session: session),
            ),
          );
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: MitablColors.primaryGradient,
            borderRadius: MitablRadius.pillBorder,
            boxShadow: MitablShadows.ambient,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'View Cart \u00B7 ${session.totalItems} item${session.totalItems == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onPrimary,
                  ),
                ),
              ),
              Text(
                '\$${session.itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
