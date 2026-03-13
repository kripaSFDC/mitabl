import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mitabl_user/helper/app_logger.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() is called in main.dart before this runs.
  AppLogger.info('FCM background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging registration, foreground display, and
/// tap-based navigation.
///
/// Initialise once in [_AppViewState.initState] by calling [init].
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;

  static const _channelId = 'mitabl_default';
  static const _channelName = 'Mitabl Notifications';

  /// Initialise FCM, local notifications, and navigation wiring.
  ///
  /// [navigatorKey] is used to push routes when the user taps a notification.
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Request permission (iOS / Android 13+).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Set up local notification channel for foreground messages.
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _routeFromPayload(navigatorKey, details.payload);
      },
    );

    // 3. Background handler (registered at app level).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground messages — show via local notifications.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: _buildPayload(message.data),
      );
    });

    // 5. Notification tapped from background/terminated state.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromData(navigatorKey, message.data);
    });

    // 6. App opened directly from a terminated-state notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _routeFromData(navigatorKey, initial.data);
    }
  }

  /// Returns the current FCM token (for registration with the backend).
  Future<String?> getToken() => _messaging.getToken();

  // ─── Routing helpers ────────────────────────────────────────────────────

  String? _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    if (type == null) return null;
    return id != null ? '$type:$id' : type;
  }

  void _routeFromPayload(
      GlobalKey<NavigatorState> key, String? payload) {
    if (payload == null) return;
    final parts = payload.split(':');
    _routeFromData(key, {
      'type': parts[0],
      if (parts.length > 1) 'id': parts[1],
    });
  }

  void _routeFromData(
      GlobalKey<NavigatorState> key, Map<String, dynamic> data) {
    final navigator = key.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    AppLogger.info('FCM route: type=$type id=$id');

    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
        navigator.pushNamed('/Bookings');
        break;
      case 'new_order':
        if (id != null) {
          navigator.pushNamed('/OrderDetails',
              arguments: _routeArgs({'id': id}));
        }
        break;
      case 'upcoming_booking':
        navigator.pushNamed('/UpcomingBookings');
        break;
      default:
        AppLogger.warn('FCM unknown notification type: $type');
    }
  }

  // ignore: prefer_typing_uninitialized_variables
  dynamic _routeArgs(Map<String, dynamic> data) => data;
}
