import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final suffix = error == null ? '' : ' | error: $error';

    if (kDebugMode) {
      debugPrint('[ERROR] $message$suffix');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return;
    }

    final details = FlutterErrorDetails(
      exception: error ?? Exception(message),
      stack: stackTrace,
      library: 'mitabl_user',
      context: ErrorDescription(message),
      informationCollector: () sync* {
        yield StringProperty('log_message', message);
      },
    );

    FlutterError.reportError(details);
  }
}
