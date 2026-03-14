import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class _SpyUserRepository extends UserRepository {
  _SpyUserRepository({required http.Client httpClient, this.throwOnSync = false})
      : super(httpClient: httpClient);

  final bool throwOnSync;
  int syncCalls = 0;
  String? syncedRole;
  dynamic syncedRoleId;

  @override
  Future<Map<String, String>> authorizedHeaders({
    bool includeJsonContentType = false,
    Map<String, String> additionalHeaders = const {},
  }) async {
    return {
      'authorization': 'Bearer test-token',
      if (includeJsonContentType) 'content-type': 'application/json',
      ...additionalHeaders,
    };
  }

  @override
  Future<void> syncCurrentUserRole({String? roleName, dynamic roleId}) async {
    syncCalls += 1;
    syncedRole = roleName;
    syncedRoleId = roleId;
    if (throwOnSync) {
      throw Exception('forced sync failure');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('UserRepository.switchRole', () {
    String fixture(String relativePath) {
      return File('test/fixtures/$relativePath').readAsStringSync();
    }

    test('sends expected request and syncs role on 200', () async {
      late http.Request capturedRequest;

      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': 200,
            'isSuccess': true,
            'data': {'role': 'Restaurant', 'role_id': 2}
          }),
          200,
        );
      });

      final repository = _SpyUserRepository(httpClient: client);

      final response = await repository.switchRole(roleId: 2);

      expect(response.statusCode, 200);
      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v2/account/switch-role',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer test-token');
      expect(capturedRequest.headers['content-type'], 'application/json');
      expect(jsonDecode(capturedRequest.body), {'role_id': 2});
      expect(repository.syncCalls, 1);
      expect(repository.syncedRole, 'Restaurant');
      expect(repository.syncedRoleId, 2);
    });


    test('syncs role from nested user payload contract fixture', () async {
      final client = MockClient((_) async {
        return http.Response(
          fixture('switch_role/success_nested_onboarding.json'),
          200,
        );
      });

      final repository = _SpyUserRepository(httpClient: client);

      final response = await repository.switchRole(roleId: 2);

      expect(response.statusCode, 200);
      expect(repository.syncCalls, 1);
      expect(repository.syncedRole, 'Restaurant');
      expect(repository.syncedRoleId, 2);
    });

    test('syncs role from flat success payload contract fixture', () async {
      final client = MockClient((_) async {
        return http.Response(
          fixture('switch_role/success_flat_ready.json'),
          200,
        );
      });

      final repository = _SpyUserRepository(httpClient: client);

      final response = await repository.switchRole(roleId: 3);

      expect(response.statusCode, 200);
      expect(repository.syncCalls, 1);
      expect(repository.syncedRole, 'Foodie');
      expect(repository.syncedRoleId, 3);
    });

    test('does not sync local role when API is not successful', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 422,
            'isSuccess': false,
            'isError': 'micook profile is not available for this account.'
          }),
          422,
        );
      });

      final repository = _SpyUserRepository(httpClient: client);

      final response = await repository.switchRole(roleId: 2);

      expect(response.statusCode, 422);
      expect(repository.syncCalls, 0);
    });

    test('returns success response even when local sync throws', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 200,
            'isSuccess': true,
            'data': {'role': 'Foodie', 'role_id': 3}
          }),
          200,
        );
      });

      final repository = _SpyUserRepository(
        httpClient: client,
        throwOnSync: true,
      );

      final response = await repository.switchRole(roleId: 3);

      expect(response.statusCode, 200);
      expect(repository.syncCalls, 1);
    });
  });
}
