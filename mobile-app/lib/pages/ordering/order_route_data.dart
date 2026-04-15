import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';

/// Route data for the menu item detail page.
class MenuItemDetailRouteData {
  const MenuItemDetailRouteData({
    required this.item,
    required this.session,
  });

  final OrderMenuItem item;
  final OrderSessionController session;
}

/// Route data for the order confirmation page.
/// Cart data must be captured BEFORE calling session.submit() since it clears the cart.
class OrderConfirmationRouteData {
  const OrderConfirmationRouteData({
    required this.result,
    required this.kitchenName,
    required this.kitchenAddress,
    required this.items,
    required this.totalAmount,
    required this.scheduledDate,
    required this.timeLabel,
    this.isDineIn = false,
    this.persons,
  });

  final OrderSubmissionResult result;
  final String kitchenName;
  final String kitchenAddress;
  final List<CartLineItem> items;
  final double totalAmount;
  final DateTime scheduledDate;
  final String timeLabel;
  final bool isDineIn;
  final int? persons;
}

/// Route data for the order tracking page (mock/static for demo).
class OrderTrackingRouteData {
  const OrderTrackingRouteData({
    required this.orderId,
    required this.kitchenName,
    this.itemSummary,
  });

  final String orderId;
  final String kitchenName;
  final String? itemSummary;
}
