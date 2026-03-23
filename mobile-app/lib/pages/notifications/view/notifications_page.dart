import 'package:flutter/material.dart';
import 'package:mitabl_user/pages/notifications/element/mock_notifications.dart';
import 'package:mitabl_user/pages/notifications/element/notification_tile.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const NotificationsPage(),
    );
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<MockNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<MockNotification>.from(mockNotifications);
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _toggleRead(int index) {
    setState(() {
      _notifications[index].isRead = !_notifications[index].isRead;
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _unreadCount > 0 ? _markAllRead : null,
            child: Text(
              'Mark All Read',
              style: TextStyle(
                color: _unreadCount > 0
                    ? MitablColors.primary
                    : MitablColors.onSurfaceVariant.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        itemCount: _notifications.length + 1, // +1 for weekly digest card
        itemBuilder: (context, index) {
          // Weekly Digest card at top
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: MitablSpacing.listItem),
              child: MitablCard(
                color: MitablColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MitablColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: MitablColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Digest',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You ordered 3 meals this week and saved \$12 with promotions.',
                            style: TextStyle(
                              fontSize: 13,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifIndex = index - 1;
          final notification = _notifications[notifIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: MitablSpacing.listItem / 2),
            child: NotificationTile(
              notification: notification,
              onTap: () => _toggleRead(notifIndex),
            ),
          );
        },
      ),
    );
  }
}
