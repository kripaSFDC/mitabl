import 'package:mitabl_user/helper/api_error_parser.dart';

class RepositoryHttpException implements Exception {
  RepositoryHttpException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  factory RepositoryHttpException.fromResponse({
    required int statusCode,
    required String body,
    required String fallbackMessage,
  }) {
    return RepositoryHttpException(
      statusCode: statusCode,
      message: ApiErrorParser.parseMessage(
        body,
        keys: const ['isError', 'message', 'error'],
        fallbackMessage: fallbackMessage,
      ),
    );
  }

  @override
  String toString() => 'RepositoryHttpException(statusCode: $statusCode, message: $message)';
}
