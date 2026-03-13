import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_aware_http_client.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository({required UserModel user}) : _user = user;

  UserModel _user;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<String> requireAccessToken() async =>
      _user.data?.accessToken ?? (throw Exception('Missing token'));

  @override
  Future<void> setCurrentUser(String jsonString) async {
    _user = UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('AuthAwareHttpClient', () {
    test('refreshes expired bearer tokens and retries the request once',
        () async {
      final userRepository = _FakeUserRepository(
        user: UserModel.fromJson({
          'response_code': 200,
          'isSuccess': true,
          'data': {
            'access_token': 'expired-token',
            'token_type': 'bearer',
            'user': {'id': 1, 'role': 'Foodie'}
          }
        }),
      );

      final refreshClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/api/token/refresh',
        );
        expect(request.headers['authorization'], 'Bearer expired-token');

        return http.Response(
          jsonEncode({
            'response_code': 200,
            'isSuccess': true,
            'data': {
              'access_token': 'fresh-token',
              'token_type': 'bearer',
              'user': {'id': 1, 'role': 'Foodie'}
            }
          }),
          200,
        );
      });

      var protectedRequestCount = 0;
      final innerClient = MockClient((request) async {
        protectedRequestCount++;

        if (protectedRequestCount == 1) {
          expect(request.headers['authorization'], 'Bearer expired-token');
          return http.Response('expired', 401);
        }

        expect(request.headers['authorization'], 'Bearer fresh-token');
        return http.Response('ok', 200);
      });

      final sessionRepository = SessionRepository(httpClient: refreshClient);
      sessionRepository.attachUserRepository(userRepository);
      final client = AuthAwareHttpClient(
        inner: innerClient,
        sessionRepository: sessionRepository,
        onlineChecker: () async => true,
      );

      final response = await client.get(
        Uri.parse('https://api.example.com/api/v2/account/profile'),
        headers: {
          'Authorization': 'Bearer expired-token',
          'Accept': 'application/json',
        },
      );

      expect(response.statusCode, 200);
      expect(protectedRequestCount, 2);
      expect(await userRepository.requireAccessToken(), 'fresh-token');

      client.close();
      sessionRepository.dispose();
    });

    test('notifies unauthorized when token refresh fails', () async {
      final userRepository = _FakeUserRepository(
        user: UserModel.fromJson({
          'response_code': 200,
          'isSuccess': true,
          'data': {
            'access_token': 'expired-token',
            'token_type': 'bearer',
            'user': {'id': 1, 'role': 'Foodie'}
          }
        }),
      );

      final refreshClient = MockClient(
        (_) async => http.Response('unauthorized', 401),
      );
      final innerClient =
          MockClient((_) async => http.Response('expired', 401));

      final sessionRepository = SessionRepository(httpClient: refreshClient);
      sessionRepository.attachUserRepository(userRepository);
      final client = AuthAwareHttpClient(
        inner: innerClient,
        sessionRepository: sessionRepository,
        onlineChecker: () async => true,
      );

      final unauthorizedEventFuture = sessionRepository.events.first;
      final response = await client.get(
        Uri.parse('https://api.example.com/api/v2/account/profile'),
        headers: {
          'Authorization': 'Bearer expired-token',
          'Accept': 'application/json',
        },
      );

      expect(response.statusCode, 401);
      expect(
        await unauthorizedEventFuture.timeout(const Duration(seconds: 1)),
        SessionEvent.unauthorized,
      );

      client.close();
      sessionRepository.dispose();
    });

    test('retries multipart requests after refreshing the bearer token',
        () async {
      final userRepository = _FakeUserRepository(
        user: UserModel.fromJson({
          'response_code': 200,
          'isSuccess': true,
          'data': {
            'access_token': 'expired-token',
            'token_type': 'bearer',
            'user': {'id': 1, 'role': 'Foodie'}
          }
        }),
      );

      final refreshClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'response_code': 200,
            'isSuccess': true,
            'data': {
              'access_token': 'fresh-token',
              'token_type': 'bearer',
              'user': {'id': 1, 'role': 'Foodie'}
            }
          }),
          200,
        );
      });

      var requestCount = 0;
      final innerClient = MockClient((request) async {
        requestCount++;

        if (requestCount == 1) {
          expect(request.headers['authorization'], 'Bearer expired-token');
          return http.Response('expired', 401);
        }

        expect(request.headers['authorization'], 'Bearer fresh-token');
        return http.Response('ok', 200);
      });

      final sessionRepository = SessionRepository(httpClient: refreshClient);
      sessionRepository.attachUserRepository(userRepository);
      final client = AuthAwareHttpClient(
        inner: innerClient,
        sessionRepository: sessionRepository,
        onlineChecker: () async => true,
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.example.com/api/v2/mikitchn/editkitchen'),
      )
        ..headers.addAll({
          'Authorization': 'Bearer expired-token',
          'Accept': 'application/json',
        })
        ..fields['name'] = 'Kitchen';

      final response =
          await http.Response.fromStream(await client.send(request));

      expect(response.statusCode, 200);
      expect(requestCount, 2);
      expect(await userRepository.requireAccessToken(), 'fresh-token');

      client.close();
      sessionRepository.dispose();
    });
  });
}
