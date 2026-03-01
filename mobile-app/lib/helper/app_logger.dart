import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      final suffix = error == null ? '' : ' | error: $error';
      debugPrint('[ERROR] $message$suffix');
    }
  }
}
