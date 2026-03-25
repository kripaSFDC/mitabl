import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/pages/notifications/element/notification_tile.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';

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
        // API returns {data: {notifications: [...]}} or {notifications: [...]}
        final dataObj = body['data'];
        List<dynamic> rawList;
        if (dataObj is Map<String, dynamic>) {
          rawList = (dataObj['notifications'] as List<dynamic>?) ?? <dynamic>[];
        } else {
          rawList = (body['notifications'] as List<dynamic>?) ?? <dynamic>[];
        }

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

          // Map backend fields to display fields
          final title = (data['title'] ?? data['message'] ?? 'Notification').toString();
          final body2 = (data['body'] ?? data['message'] ?? '').toString();
          final typeRaw = data['type'];
          String typeStr;
          if (typeRaw is int) {
            // Backend uses numeric types: map to string
            typeStr = const {1: 'order', 2: 'order', 3: 'order', 4: 'order', 5: 'order'}[typeRaw] ?? 'system';
          } else {
            typeStr = (typeRaw ?? 'system').toString();
          }

          parsed.add(_ApiNotification(
            id: (raw['id'] ?? '').toString(),
            title: title,
            body: title != body2 ? body2 : '',
            type: typeStr,
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
      appBar: const GlassAppBar(title: Text('Mitabl')),
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
              : ListView(
                  padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                  children: [
                    // ── Notification Header ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: MitablColors.onSurface,
                                    fontFamily: 'Nunito',
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Stay updated with your culinary journey',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mark all as read button
                          GestureDetector(
                            onTap: _unreadCount > 0 ? _markAllRead : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                'MARK ALL AS READ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: _unreadCount > 0
                                      ? MitablColors.primary
                                      : MitablColors.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Notification Items ──
                    ..._notifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final notification = entry.value;
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
                          onMarkedRead: () => _markRead(index),
                        ),
                      );
                    }),

                    // ── Weekly Digest Promotion Card ──
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 32),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: MitablColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            // Decorative circle
                            Positioned(
                              top: -32,
                              right: -32,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF506140)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 36,
                                  color: Color(0xFF3B4C2C),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Weekly Digest',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF3B4C2C),
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'You ordered 3 meals this week. See your performance analytics.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF3B4C2C),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF3B4C2C),
                                      foregroundColor:
                                          MitablColors.secondaryContainer,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            MitablRadius.pillBorder,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'View Report',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
