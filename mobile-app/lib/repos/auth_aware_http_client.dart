import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/session_repository.dart';

class AuthAwareHttpClient extends http.BaseClient {
  AuthAwareHttpClient({
    required http.Client inner,
    required SessionRepository sessionRepository,
  })  : _inner = inner,
        _sessionRepository = sessionRepository;

  final http.Client _inner;
  final SessionRepository _sessionRepository;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final accessToken = _extractBearerToken(request);
    final retryRequest = await _cloneRequest(request);
    final response = await _inner.send(request);

    if (accessToken == null || response.statusCode != 401) {
      return response;
    }

    final refreshedToken = await _sessionRepository.refreshAccessToken(
      failedAccessToken: accessToken,
    );

    if (refreshedToken != null && retryRequest != null) {
      retryRequest.headers['Authorization'] = 'Bearer $refreshedToken';
      final retriedResponse = await _inner.send(retryRequest);
      if (retriedResponse.statusCode != 401) {
        return retriedResponse;
      }
    } else if (retryRequest == null) {
      AppLogger.warn(
        'Unable to retry ${request.method} ${request.url} after refreshing the token.',
      );
      if (refreshedToken != null) {
        return response;
      }
    }

    _sessionRepository.notifyUnauthorized();

    return response;
  }

  String? _extractBearerToken(http.BaseRequest request) {
    for (final header in request.headers.entries) {
      if (header.key.toLowerCase() != 'authorization') {
        continue;
      }

      final value = header.value.trim();
      if (value.length <= 7 || !value.toLowerCase().startsWith('bearer ')) {
        return null;
      }

      return value.substring(7).trim();
    }

    return null;
  }

  Future<http.BaseRequest?> _cloneRequest(http.BaseRequest request) async {
    if (request is http.Request) {
      final cloned = http.Request(request.method, request.url)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..headers.addAll(request.headers)
        ..bodyBytes = Uint8List.fromList(request.bodyBytes);
      return cloned;
    }

    return null;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
