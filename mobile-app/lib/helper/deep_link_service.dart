import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/route_arguement.dart';

/// Listens for incoming deep links and routes them to named routes.
///
/// Supported URI patterns (scheme: `mitabl://` or HTTPS universal links):
/// ```
/// /cook/{id}      → /CookProfile
/// /booking/{id}   → /Bookings
/// /order/{id}     → /OrderDetails
/// ```
///
/// Call [init] once from [_AppViewState.initState].
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    // Handle the link that launched the app from a terminated state.
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _route(navigatorKey, initialLink);
      }
    } catch (e) {
      AppLogger.warn('DeepLinkService: initial link error — $e');
    }

    // Handle links while app is running.
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _route(navigatorKey, uri),
      onError: (e) =>
          AppLogger.warn('DeepLinkService: stream error — $e'),
    );
  }

  void _route(GlobalKey<NavigatorState> key, Uri uri) {
    final navigator = key.currentState;
    if (navigator == null) return;

    AppLogger.info('Deep link: $uri');

    final segments = uri.pathSegments;
    if (segments.isEmpty) return;

    switch (segments[0]) {
      case 'cook':
        final id = segments.length > 1 ? segments[1] : null;
        if (id != null) {
          navigator.pushNamed(
            '/CookProfile',
            arguments: RouteArguments(id: id),
          );
        }
        break;

      case 'booking':
        navigator.pushNamed('/Bookings');
        break;

      case 'order':
        final id = segments.length > 1 ? segments[1] : null;
        if (id != null) {
          navigator.pushNamed(
            '/OrderDetails',
            arguments: RouteArguments(id: id),
          );
        }
        break;

      default:
        AppLogger.warn('DeepLinkService: unhandled path "${uri.path}"');
    }
  }
}
