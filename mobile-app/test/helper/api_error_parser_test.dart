import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';

void main() {
  group('ApiErrorParser.parseMessage', () {
    test('returns friendly upload message for explicit 413 status', () {
      final message = ApiErrorParser.parseMessage(
        '<html><body><h1>413 Request Entity Too Large</h1></body></html>',
        statusCode: 413,
      );

      expect(message, ApiErrorParser.requestTooLargeMessage);
    });

    test('returns friendly upload message for 413 html body', () {
      final message = ApiErrorParser.parseMessage(
        '<html><body><h1>413 Request Entity Too Large</h1></body></html>',
      );

      expect(message, ApiErrorParser.requestTooLargeMessage);
    });

    test('does not surface raw html for non-413 errors', () {
      final message = ApiErrorParser.parseMessage(
        '<html><body><h1>500 Internal Server Error</h1></body></html>',
        fallbackMessage: 'Could not complete the request.',
      );

      expect(message, 'Could not complete the request.');
    });

    test('does not treat unrelated 413 text as upload limit error', () {
      final message = ApiErrorParser.parseMessage(
        'Reference number 413 is unavailable right now.',
      );

      expect(message, 'Reference number 413 is unavailable right now.');
    });

    test('returns json error message when available', () {
      final message = ApiErrorParser.parseMessage(
        '{"message":"Validation failed"}',
      );

      expect(message, 'Validation failed');
    });
  });
}
