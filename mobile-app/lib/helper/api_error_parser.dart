import 'dart:convert';

class ApiErrorParser {
  const ApiErrorParser._();

  static const String requestTooLargeMessage =
      'Your upload is too large. Please reduce image size and try again.';

  static String parseMessage(
    String body, {
    int? statusCode,
    List<String> keys = const ['isError', 'message', 'error'],
    String fallbackMessage = 'Something went wrong...',
  }) {
    if (statusCode == 413) {
      return requestTooLargeMessage;
    }

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

    final trimmedBody = body.trim();
    if (_containsRequestEntityTooLarge(trimmedBody)) {
      return requestTooLargeMessage;
    }

    if (_looksLikeHtml(trimmedBody)) {
      return fallbackMessage;
    }

    return trimmedBody;
  }

  static bool _containsRequestEntityTooLarge(String body) {
    final normalized = body.toLowerCase();
    return normalized.contains('request entity too large') ||
      (normalized.contains('413') &&
        (normalized.contains('entity too large') ||
          normalized.contains('payload too large') ||
          normalized.contains('content too large')));
  }

  static bool _looksLikeHtml(String body) {
    final normalized = body.toLowerCase();
    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html') ||
        normalized.contains('<head>') ||
        normalized.contains('<body>');
  }
}
