import 'package:flutter/material.dart';

enum NotificationType { order, promo, social, system }

class MockNotification {
  MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    required this.iconData,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final IconData iconData;
}

final List<MockNotification> mockNotifications = [
  MockNotification(
    id: '1',
    title: 'Order Confirmed',
    body: 'Your order #MF-1042 from Chef Priya\'s Kitchen has been confirmed. Get ready for a delicious meal!',
    type: NotificationType.order,
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    iconData: Icons.check_circle_outline,
  ),
  MockNotification(
    id: '2',
    title: 'New Kitchen Near You',
    body: 'Chef Marco\'s Italian Bistro just opened in your area. Check out their menu!',
    type: NotificationType.promo,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    iconData: Icons.store,
  ),
  MockNotification(
    id: '3',
    title: 'Rate Your Last Order',
    body: 'How was your meal from Sakura Sushi? Leave a review and help other foodies!',
    type: NotificationType.social,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    iconData: Icons.star_outline,
  ),
  MockNotification(
    id: '4',
    title: 'Weekend Special',
    body: '20% off on all orders this weekend! Use code MITABL20 at checkout.',
    type: NotificationType.promo,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    iconData: Icons.local_offer_outlined,
  ),
  MockNotification(
    id: '5',
    title: 'Order Delivered',
    body: 'Your order #MF-1038 has been delivered. Enjoy your meal!',
    type: NotificationType.order,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    isRead: true,
    iconData: Icons.delivery_dining,
  ),
  MockNotification(
    id: '6',
    title: 'Payment Successful',
    body: 'Payment of \$42.50 for order #MF-1038 was processed successfully.',
    type: NotificationType.system,
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
    iconData: Icons.payment,
  ),
  MockNotification(
    id: '7',
    title: 'New Favourite Alert',
    body: 'Chef Maria\'s Kitchen just added new desserts to their menu. Don\'t miss out!',
    type: NotificationType.promo,
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
    iconData: Icons.favorite_border,
  ),
  MockNotification(
    id: '8',
    title: 'Account Security',
    body: 'A new device was used to login to your account. If this wasn\'t you, please update your password.',
    type: NotificationType.system,
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
    iconData: Icons.security,
  ),
];
