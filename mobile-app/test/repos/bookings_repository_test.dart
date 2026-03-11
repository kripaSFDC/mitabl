import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/bookings_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository({UserModel? user}) : _user = user;

  final UserModel? _user;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel?> getUser() async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('BookingRepository', () {
    test('updateOrderStatus sends json payload with bearer headers', () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"status":200}', 200);
      });

      final userRepository = _FakeUserRepository(
        user: UserModel.fromJson({
          'status': 200,
          'isSuccess': true,
          'data': {
            'access_token': 'abc-token',
            'token_type': 'Bearer',
            'user': {'id': 1}
          }
        }),
      );

      final repository = BookingRepository(
        userRepository,
        httpClient: mockClient,
      );

      await repository.updateOrderStatus(
        data: {'order_id': '15', 'status': '1'},
      );

      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v2/updateorderstatus',
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
      expect(capturedRequest.headers['content-type'], 'application/json');
      expect(
        jsonDecode(capturedRequest.body),
        {'order_id': '15', 'status': '1'},
      );
    });
  });
}
