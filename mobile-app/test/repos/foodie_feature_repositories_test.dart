import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/ordering_repository.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/user_repository.dart';

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

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository(this.user, {required http.Client httpClient})
      : super(httpClient: httpClient);

  final UserModel user;

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<String> requireAccessToken() async => 'abc-token';

  @override
  Future<Map<String, String>> authorizedHeaders({
    bool includeJsonContentType = false,
    Map<String, String> additionalHeaders = const {},
  }) async {
    final headers = <String, String>{
      'authorization': 'Bearer abc-token',
      ...additionalHeaders,
    };
    if (includeJsonContentType) {
      headers['content-type'] = 'application/json';
    }
    return headers;
  }
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
        'https://api.example.com/api/v2/account/orders?page=1&limit=20',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });

    test('fetchOrdersHistory parses nested orders list payload shape', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': {
              'orders': [
                {'id': 'ord-1', 'status': 'completed'}
              ]
            }
          }),
          200,
        );
      });

      final repository = MiOrdersRepository(httpClient: client);
      final records = await repository.fetchOrdersHistory(userModel: _buildUser());

      expect(records, hasLength(1));
      expect(records.first['id'], 'ord-1');
    });


    test('fetchOrdersHistory throws typed exception for 403', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Forbidden from orders'}), 403);
      });
      final repository = MiOrdersRepository(httpClient: client);

      expect(
        repository.fetchOrdersHistory(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.message, 'message', 'Forbidden from orders'),
        ),
      );
    });

    test('fetchOrdersHistory throws typed exception for 422', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Invalid pagination'}), 422);
      });
      final repository = MiOrdersRepository(httpClient: client);

      expect(
        repository.fetchOrdersHistory(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Invalid pagination'),
        ),
      );
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
        'https://api.example.com/api/v2/account/favorites?page=1&limit=20',
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
        'https://api.example.com/api/v2/account/favorites/toggle',
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
      expect(capturedRequest.bodyFields['restaurant_id'], 'kitchen-42');
    });





    test('toggleFavourite throws typed exception for 403', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Not allowed to change favourite'}), 403);
      });
      final repository = FavouritesRepository(httpClient: client);

      expect(
        repository.toggleFavourite(userModel: _buildUser(), targetId: 'kitchen-42'),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.message, 'message', 'Not allowed to change favourite'),
        ),
      );
    });

    test('toggleFavourite throws typed exception for 422', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Invalid favourite target'}), 422);
      });
      final repository = FavouritesRepository(httpClient: client);

      expect(
        repository.toggleFavourite(userModel: _buildUser(), targetId: 'kitchen-42'),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Invalid favourite target'),
        ),
      );
    });

    test('fetchFavourites throws typed exception for 403', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Forbidden from favourites'}), 403);
      });
      final repository = FavouritesRepository(httpClient: client);

      expect(
        repository.fetchFavourites(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.message, 'message', 'Forbidden from favourites'),
        ),
      );
    });

    test('fetchFavourites throws typed exception for 422', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Invalid favourites request'}), 422);
      });
      final repository = FavouritesRepository(httpClient: client);

      expect(
        repository.fetchFavourites(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Invalid favourites request'),
        ),
      );
    });

    test('fetchFavourites throws typed exception for non-200 response', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Temporary failure'}), 500);
      });
      final repository = FavouritesRepository(httpClient: client);

      expect(
        repository.fetchFavourites(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 500)
              .having((error) => error.message, 'message', 'Temporary failure'),
        ),
      );
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
        'https://api.example.com/api/v2/account/payments/history?page=1&limit=20',
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
        'https://api.example.com/api/v2/payments/cards',
      );
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
    });



    test('fetchPaymentsHistory throws typed exception for 403', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Forbidden from payments'}), 403);
      });
      final repository = PaymentsRepository(httpClient: client);

      expect(
        repository.fetchPaymentsHistory(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.message, 'message', 'Forbidden from payments'),
        ),
      );
    });

    test('fetchPaymentsHistory throws typed exception for 422', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Unsupported payment filter'}), 422);
      });
      final repository = PaymentsRepository(httpClient: client);

      expect(
        repository.fetchPaymentsHistory(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Unsupported payment filter'),
        ),
      );
    });



    test('fetchSavedCards throws typed exception for 403', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Forbidden from cards'}), 403);
      });
      final repository = PaymentsRepository(httpClient: client);

      expect(
        repository.fetchSavedCards(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.message, 'message', 'Forbidden from cards'),
        ),
      );
    });

    test('fetchSavedCards throws typed exception for 422', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Invalid cards request'}), 422);
      });
      final repository = PaymentsRepository(httpClient: client);

      expect(
        repository.fetchSavedCards(userModel: _buildUser()),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Invalid cards request'),
        ),
      );
    });

    test('fetchSavedCards parses cards list payload shape', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'cards': [
              {'brand': 'visa', 'last4': '4242'}
            ]
          }),
          200,
        );
      });

      final repository = PaymentsRepository(httpClient: client);
      final cards = await repository.fetchSavedCards(userModel: _buildUser());

      expect(cards, hasLength(1));
      expect(cards.first['last4'], '4242');
    });
  });

  group('OrderingRepository', () {
    test('fetchKitchen parses kitchen details and nested foods', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 7,
              'name': 'Test Kitchen',
              'address': '123 Street',
              'dine_in': 1,
              'take_away': 1,
              'images': ['hero.jpg'],
              'foods': [
                {
                  'id': 11,
                  'restaurant_id': 7,
                  'food_name': 'Kabsa',
                  'price': '24.50',
                  'dine_in': 1,
                  'take_away': 0,
                  'pictures': ['dish.jpg'],
                }
              ]
            }
          }),
          200,
        );
      });

      final repository = OrderingRepository(
        _FakeUserRepository(_buildUser(), httpClient: client),
        httpClient: client,
      );

      final (kitchen, foods) = await repository.fetchKitchen(7);

      expect(kitchen.id, 7);
      expect(kitchen.name, 'Test Kitchen');
      expect(kitchen.dineInAvailable, isTrue);
      expect(foods, hasLength(1));
      expect(foods.first.name, 'Kabsa');
      expect(foods.first.takeAwayAvailable, isFalse);
    });

    test('placeOrder posts expected payload without client-calculated totals', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'message': 'Food Ordered Created.',
            'data': {'order_id': 55, 'total_price': '18.00'}
          }),
          200,
        );
      });

      final repository = OrderingRepository(
        _FakeUserRepository(_buildUser(), httpClient: client),
        httpClient: client,
      );

      final result = await repository.placeOrder(
        kitchenId: 9,
        deliveryDate: '2026-03-20',
        deliveryTimeFrom: '12:00',
        deliveryTimeTo: '13:00',
        serviceType: OrderServiceType.takeAway,
        taxes: 1.80,
        items: [
          CartLineItem(
            item: OrderMenuItem(
              id: 4,
              restaurantId: 9,
              name: 'Mandi',
              price: 18,
              dineInAvailable: true,
              takeAwayAvailable: true,
            ),
            quantity: 2,
          ),
        ],
        persons: null,
      );

      expect(result.orderId, 55);
      expect(result.totalPrice, '18.00');
      expect(
        capturedRequest.url.toString(),
        'https://api.example.com/api/v2/account/orders',
      );

      final payload = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(payload.containsKey('item_total_price'), isFalse);
      expect(payload.containsKey('total_price'), isFalse);
      expect(payload['taxes'], '1.80');
      expect(payload['take_away'], 1);
      expect(payload['dine_in'], 0);
      expect(
        jsonDecode(payload['item_data'] as String),
        [
          {'id': 4, 'quantity': 2}
        ],
      );
    });

    test('placeOrder throws typed exception for backend validation failure', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'isError': 'Selected kitchen is currently unavailable.'}), 422);
      });

      final repository = OrderingRepository(
        _FakeUserRepository(_buildUser(), httpClient: client),
        httpClient: client,
      );

      expect(
        repository.placeOrder(
          kitchenId: 9,
          deliveryDate: '2026-03-20',
          deliveryTimeFrom: '12:00',
          deliveryTimeTo: '13:00',
          serviceType: OrderServiceType.takeAway,
          taxes: 0,
          items: [
            CartLineItem(
              item: OrderMenuItem(
                id: 4,
                restaurantId: 9,
                name: 'Mandi',
                price: 18,
                dineInAvailable: true,
                takeAwayAvailable: true,
              ),
              quantity: 1,
            ),
          ],
          persons: null,
        ),
        throwsA(
          isA<RepositoryHttpException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.message,
                'message',
                'Selected kitchen is currently unavailable.',
              ),
        ),
      );
    });
  });
}
