import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('FCM background message: ${message.messageId}');
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    _firebaseMessagingBackgroundHandler(message);

/// Manages Firebase Cloud Messaging registration, foreground display, and
/// tap-based navigation.
///
/// Initialise once in [_AppViewState.initState] by calling [init].
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;

  static const _channelId = 'mitabl_default';
  static const _channelName = 'Mitabl Notifications';
  static const _notificationsPreferenceKeyCook =
      'settings_notifications_enabled_cook';

  bool _initialized = false;
  String? _lastSyncedToken;
  UserRepository? _userRepository;

  FirebaseMessaging? _messagingOrNull() {
    if (_messaging != null) {
      return _messaging;
    }

    try {
      if (Firebase.apps.isEmpty) {
        return null;
      }
      _messaging = FirebaseMessaging.instance;
      return _messaging;
    } catch (e) {
      AppLogger.warn('Firebase messaging unavailable: $e');
      return null;
    }
  }

  /// Initialise FCM, local notifications, and navigation wiring.
  ///
  /// [navigatorKey] is used to push routes when the user taps a notification.
  Future<void> init(
    GlobalKey<NavigatorState> navigatorKey, {
    UserRepository? userRepository,
  }) async {
    if (_initialized) return;

    final messaging = _messagingOrNull();
    if (messaging == null) {
      AppLogger.warn(
        'NotificationService init skipped: Firebase not initialized.',
      );
      return;
    }

    _initialized = true;
    _userRepository = userRepository;

    // 1. Request permission (iOS / Android 13+).
    await messaging.requestPermission(
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

    // 2.5 Keep token synced once a user is authenticated.
    await syncTokenWithBackendIfPossible();
    messaging.onTokenRefresh.listen((token) {
      syncTokenWithBackendIfPossible(tokenOverride: token);
    });

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _routeFromPayload(navigatorKey, details.payload);
      },
    );

    // 3. Foreground messages — show via local notifications.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: _buildPayload(message.data),
      );
    });

    // 4. Notification tapped from background/terminated state.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromData(navigatorKey, message.data);
    });

    // 5. App opened directly from a terminated-state notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _routeFromData(navigatorKey, initial.data);
    }
  }

  /// Tries to sync the current FCM token to backend.
  ///
  /// Safe to call repeatedly; no-op when token is unchanged or when user repo
  /// is unavailable.
  Future<void> syncTokenWithBackendIfPossible({String? tokenOverride}) async {
    final repository = _userRepository;
    if (repository == null) return;

    final messaging = _messagingOrNull();
    if (messaging == null) return;

    try {
      final token = tokenOverride ?? await messaging.getToken();
      if (token == null || token.isEmpty || token == _lastSyncedToken) return;

      final notificationsEnabled =
          await _resolveNotificationEnabledPreference();
      final response = await repository.updateNotificationPreference(
        enabled: notificationsEnabled,
        deviceToken: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastSyncedToken = token;
      } else {
        AppLogger.warn(
          'Failed to sync FCM token with backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.warn('Unable to sync FCM token with backend: $e');
    }
  }

  Future<bool> _resolveNotificationEnabledPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsPreferenceKeyCook) ?? true;
  }

  /// Returns the current FCM token (for registration with the backend).
  Future<String?> getToken() async {
    final messaging = _messagingOrNull();
    if (messaging == null) return null;
    return messaging.getToken();
  }

  // ─── Routing helpers ────────────────────────────────────────────────────

  String? _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    if (type == null) return null;
    return id != null ? '$type:$id' : type;
  }

  void _routeFromPayload(GlobalKey<NavigatorState> key, String? payload) {
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
        // OrderDetails requires a full booking object; notification payloads
        // may only provide an id. Route to list view to prevent null crashes.
        navigator.pushNamed('/Bookings', arguments: RouteArguments(id: id));
        break;
      case 'upcoming_booking':
        navigator.pushNamed('/UpcomingBookings');
        break;
      default:
        AppLogger.warn('FCM unknown notification type: $type');
    }
  }
}
