import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thrown by [AuthAwareHttpClient] when the device is offline.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException: No internet connection.';
}

/// Singleton that exposes a connectivity stream and an async online check.
///
/// Usage:
/// ```dart
/// // Check once
/// final online = await ConnectivityService.instance.isOnline();
///
/// // Listen to changes
/// ConnectivityService.instance.onConnectivityChanged.listen((online) { ... });
/// ```
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _initialized = false;

  /// Broadcast stream that emits `true` when online, `false` when offline.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Initialise the listener. Call once from [main] or [App].
  void init() {
    if (_initialized) return;
    _initialized = true;

    isOnline().then(_controller.add);
    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isOnline(results));
    });
  }

  /// Returns `true` if the device currently has a usable connection.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
