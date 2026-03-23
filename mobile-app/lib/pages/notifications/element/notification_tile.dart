import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'mock_notifications.dart';

/// A tile displaying a single notification with icon, title, body, timestamp,
/// and unread indicator.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final MockNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MitablCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored icon avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _typeColor(notification.type).withValues(alpha: 0.12),
            child: Icon(
              notification.iconData,
              color: _typeColor(notification.type),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: MitablColors.onSurface,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _timeAgo(notification.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Unread dot
          if (!notification.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: MitablColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return MitablColors.accent;
      case NotificationType.promo:
        return const Color(0xFFF59E0B);
      case NotificationType.social:
        return MitablColors.primary;
      case NotificationType.system:
        return const Color(0xFF2563EB);
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
