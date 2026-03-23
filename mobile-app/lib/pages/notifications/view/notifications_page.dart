import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/pages/notifications/element/notification_tile.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// A notification item parsed from the v2/notifications API.
class _ApiNotification {
  _ApiNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  bool isRead;

  IconData get iconData {
    switch (type) {
      case 'order':
        return Icons.check_circle_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'social':
        return Icons.star_outline;
      case 'system':
        return Icons.security;
      default:
        return Icons.notifications_outlined;
    }
  }
}

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
  List<_ApiNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userRepository = context.read<UserRepository>();
      final headers = await userRepository.authorizedHeaders();
      final uri = ApiContract.uri('v2/notifications');

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiContract.requestTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList =
            (body['notifications'] as List<dynamic>?) ?? <dynamic>[];

        final parsed = <_ApiNotification>[];
        for (final raw in rawList) {
          if (raw is! Map<String, dynamic>) continue;

          // Parse the nested `data` JSON for title/body/type
          Map<String, dynamic> data = {};
          final rawData = raw['data'];
          if (rawData is String) {
            try {
              data = jsonDecode(rawData) as Map<String, dynamic>;
            } catch (_) {}
          } else if (rawData is Map<String, dynamic>) {
            data = rawData;
          }

          parsed.add(_ApiNotification(
            id: (raw['id'] ?? '').toString(),
            title: (data['title'] ?? 'Notification').toString(),
            body: (data['body'] ?? '').toString(),
            type: (data['type'] ?? 'system').toString(),
            createdAt: DateTime.tryParse(
                    (raw['created_at'] ?? '').toString()) ??
                DateTime.now(),
            isRead: raw['read_at'] != null,
          ));
        }

        setState(() {
          _notifications = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _isLoading = false;
        _errorMessage = 'Could not load notifications';
      });
    }
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MitablColors.primary),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: MitablColors.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ?? 'No notifications yet',
                        style: const TextStyle(
                          fontSize: 15,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                  itemCount: _notifications.length + 1,
                  itemBuilder: (context, index) {
                    // Weekly Digest card at top
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: MitablSpacing.listItem),
                        child: MitablCard(
                          color:
                              MitablColors.primary.withValues(alpha: 0.08),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: MitablColors.primary
                                      .withValues(alpha: 0.15),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                        color:
                                            MitablColors.onSurfaceVariant,
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
                      padding: const EdgeInsets.only(
                          bottom: MitablSpacing.listItem / 2),
                      child: NotificationTile(
                        id: notification.id,
                        title: notification.title,
                        body: notification.body,
                        type: notification.type,
                        createdAt: notification.createdAt,
                        isRead: notification.isRead,
                        iconData: notification.iconData,
                        onMarkedRead: () => _markRead(notifIndex),
                      ),
                    );
                  },
                ),
    );
  }
}
