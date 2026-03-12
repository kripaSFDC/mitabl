import 'dart:convert';

class ApiErrorParser {
  const ApiErrorParser._();

  static String parseMessage(
    String body, {
    List<String> keys = const ['isError', 'message', 'error'],
    String fallbackMessage = 'Something went wrong...',
  }) {
    if (body.trim().isEmpty) {
      return fallbackMessage;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in keys) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    } on FormatException {
      // Fall through and return a safe plain-text fallback below.
    }

    return body.trim();
  }
}
