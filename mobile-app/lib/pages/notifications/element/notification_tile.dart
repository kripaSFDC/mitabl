import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// A tile displaying a single notification with icon, title, body, timestamp,
/// and unread indicator. Calls PUT v2/notifications/{id}/read on tap.
class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.iconData,
    this.onMarkedRead,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final IconData iconData;
  final VoidCallback? onMarkedRead;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  late bool _isRead;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
  }

  @override
  void didUpdateWidget(covariant NotificationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRead != widget.isRead) {
      _isRead = widget.isRead;
    }
  }

  Future<void> _onTap() async {
    if (_isRead) return;

    // Optimistically mark as read
    setState(() => _isRead = true);
    widget.onMarkedRead?.call();

    try {
      final userRepository = context.read<UserRepository>();
      final headers = await userRepository.authorizedHeaders(
        includeJsonContentType: true,
      );
      final uri = ApiContract.uri('v2/notifications/${widget.id}/read');

      await http.put(uri, headers: headers).timeout(ApiContract.requestTimeout);
      // If it fails silently, the local state still shows read.
    } catch (_) {
      // Keep local read state even on failure to avoid flicker.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MitablCard(
      onTap: _onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored icon avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _typeColor(widget.type).withValues(alpha: 0.12),
            child: Icon(
              widget.iconData,
              color: _typeColor(widget.type),
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
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _isRead ? FontWeight.w500 : FontWeight.w700,
                    color: MitablColors.onSurface,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _timeAgo(widget.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Unread dot
          if (!_isRead) ...[
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

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return MitablColors.accent;
      case 'promo':
        return const Color(0xFFF59E0B);
      case 'social':
        return MitablColors.primary;
      case 'system':
        return const Color(0xFF2563EB);
      default:
        return MitablColors.onSurfaceVariant;
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
