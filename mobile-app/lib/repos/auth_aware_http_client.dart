import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/connectivity_service.dart';
import 'package:mitabl_user/repos/session_repository.dart';

class AuthAwareHttpClient extends http.BaseClient {
  AuthAwareHttpClient({
    required http.Client inner,
    required SessionRepository sessionRepository,
    Future<bool> Function()? onlineChecker,
  })  : _inner = inner,
        _sessionRepository = sessionRepository,
        _onlineChecker = onlineChecker ?? ConnectivityService.instance.isOnline;

  final http.Client _inner;
  final SessionRepository _sessionRepository;
  final Future<bool> Function() _onlineChecker;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final online = await _onlineChecker();
    if (!online) {
      throw const OfflineException();
    }

    final preparedRequest = await _prepareRequest(request);
    final accessToken = _extractBearerToken(request);
    final response = await _inner.send(preparedRequest.initialRequest);

    if (accessToken == null || response.statusCode != 401) {
      return response;
    }

    final refreshedToken = await _sessionRepository.refreshAccessToken(
      failedAccessToken: accessToken,
    );
    final retryRequest = await preparedRequest.createRetryRequest();

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

  Future<_PreparedRequest> _prepareRequest(http.BaseRequest request) async {
    if (request is http.MultipartRequest) {
      final snapshot = await _MultipartRequestSnapshot.fromRequest(request);
      return _PreparedRequest(
        initialRequest: snapshot.toRequest(),
        createRetryRequest: () async => snapshot.toRequest(),
      );
    }

    return _PreparedRequest(
      initialRequest: request,
      createRetryRequest: () => _cloneRequest(request),
    );
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

class _PreparedRequest {
  const _PreparedRequest({
    required this.initialRequest,
    required this.createRetryRequest,
  });

  final http.BaseRequest initialRequest;
  final Future<http.BaseRequest?> Function() createRetryRequest;
}

class _MultipartRequestSnapshot {
  const _MultipartRequestSnapshot({
    required this.method,
    required this.url,
    required this.followRedirects,
    required this.maxRedirects,
    required this.persistentConnection,
    required this.headers,
    required this.fields,
    required this.files,
  });

  final String method;
  final Uri url;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;
  final Map<String, String> headers;
  final Map<String, String> fields;
  final List<_MultipartFileSnapshot> files;

  static Future<_MultipartRequestSnapshot> fromRequest(
    http.MultipartRequest request,
  ) async {
    final files = <_MultipartFileSnapshot>[];
    for (final file in request.files) {
      files.add(await _MultipartFileSnapshot.fromFile(file));
    }

    return _MultipartRequestSnapshot(
      method: request.method,
      url: request.url,
      followRedirects: request.followRedirects,
      maxRedirects: request.maxRedirects,
      persistentConnection: request.persistentConnection,
      headers: Map<String, String>.from(request.headers),
      fields: Map<String, String>.from(request.fields),
      files: files,
    );
  }

  http.MultipartRequest toRequest() {
    final request = http.MultipartRequest(method, url)
      ..followRedirects = followRedirects
      ..maxRedirects = maxRedirects
      ..persistentConnection = persistentConnection
      ..headers.addAll(headers)
      ..fields.addAll(fields);

    for (final file in files) {
      request.files.add(file.toMultipartFile());
    }

    return request;
  }
}

class _MultipartFileSnapshot {
  const _MultipartFileSnapshot({
    required this.field,
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final String field;
  final List<int> bytes;
  final String? filename;
  final MediaType? contentType;

  static Future<_MultipartFileSnapshot> fromFile(
      http.MultipartFile file) async {
    final bytes = await file.finalize().toBytes();
    return _MultipartFileSnapshot(
      field: file.field,
      bytes: bytes,
      filename: file.filename,
      contentType: file.contentType,
    );
  }

  http.MultipartFile toMultipartFile() {
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
