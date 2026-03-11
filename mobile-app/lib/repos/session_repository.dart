import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/user_repository.dart';

enum SessionEvent {
  unauthorized,
}

class SessionRepository {
  SessionRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final _controller = StreamController<SessionEvent>.broadcast();
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  DateTime? _lastUnauthorizedAt;
  UserRepository? _userRepository;
  Future<String?>? _refreshInFlight;

  Stream<SessionEvent> get events => _controller.stream;

  void attachUserRepository(UserRepository userRepository) {
    _userRepository = userRepository;
  }

  Future<String?> refreshAccessToken({
    required String failedAccessToken,
  }) async {
    final repository = _userRepository;
    if (repository == null) {
      AppLogger.warn('SessionRepository has no attached UserRepository.');
      return null;
    }

    final normalizedFailedToken = failedAccessToken.trim();
    if (normalizedFailedToken.isEmpty) {
      return null;
    }

    final currentUser = await repository.getUser();
    if (currentUser == null) {
      return null;
    }

    final currentToken = requireAccessToken(currentUser);
    if (currentToken != normalizedFailedToken) {
      return currentToken;
    }

    final refreshInFlight = _refreshInFlight;
    if (refreshInFlight != null) {
      return refreshInFlight;
    }

    final refreshFuture = _performRefresh(repository, currentToken);
    _refreshInFlight = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<String?> _performRefresh(
    UserRepository repository,
    String accessToken,
  ) async {
    try {
      final response = await _httpClient
          .post(
            ApiContract.uri('token/refresh'),
            headers: buildBearerHeaders(accessToken),
          )
          .timeout(ApiContract.requestTimeout);

      if (response.statusCode != 200) {
        AppLogger.warn(
          'Token refresh failed with status ${response.statusCode}.',
        );
        return null;
      }

      await repository.setCurrentUser(response.body);
      return repository.requireAccessToken();
    } on Exception catch (error, stackTrace) {
      AppLogger.error('Token refresh failed', error, stackTrace);
      return null;
    }
  }

  void notifyUnauthorized() {
    final now = DateTime.now();
    if (_lastUnauthorizedAt != null &&
        now.difference(_lastUnauthorizedAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastUnauthorizedAt = now;
    _controller.add(SessionEvent.unauthorized);
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
    _controller.close();
  }
}
