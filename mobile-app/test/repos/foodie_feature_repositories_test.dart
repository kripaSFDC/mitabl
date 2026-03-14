import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/payments_repository.dart';

UserModel _buildUser() {
  return UserModel.fromJson({
    'status': 200,
    'isSuccess': true,
    'data': {
      'access_token': 'abc-token',
      'token_type': 'Bearer',
      'user': {'id': 1}
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('MiOrdersRepository', () {
    test('fetchOrdersHistory hits expected endpoint and returns empty list', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final repository = MiOrdersRepository(httpClient: client);
      final records = await repository.fetchOrdersHistory(userModel: _buildUser());

      expect(records, isEmpty);
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v1/foodie/orders/history?page=1&limit=20',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });
  });

  group('FavouritesRepository', () {
    test('fetchFavourites hits expected endpoint and returns empty list', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final repository = FavouritesRepository(httpClient: client);
      final records = await repository.fetchFavourites(userModel: _buildUser());

      expect(records, isEmpty);
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v1/foodie/favourites?page=1&limit=20',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });

    test('toggleFavourite posts target id to expected endpoint', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });

      final repository = FavouritesRepository(httpClient: client);
      await repository.toggleFavourite(
        userModel: _buildUser(),
        targetId: 'kitchen-42',
      );

      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v1/foodie/favourites/toggle',
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
      expect(capturedRequest.bodyFields['target_id'], 'kitchen-42');
    });
  });

  group('PaymentsRepository', () {
    test('fetchPaymentsHistory hits expected endpoint and returns empty list', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final repository = PaymentsRepository(httpClient: client);
      final records = await repository.fetchPaymentsHistory(userModel: _buildUser());

      expect(records, isEmpty);
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v1/foodie/payments/history?page=1&limit=20',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });

    test('fetchSavedCards hits expected endpoint and returns empty list', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final repository = PaymentsRepository(httpClient: client);
      final records = await repository.fetchSavedCards(userModel: _buildUser());

      expect(records, isEmpty);
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v1/foodie/payments/cards',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });
  });
}
