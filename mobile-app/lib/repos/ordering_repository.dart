import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class OrderingRepository {
  OrderingRepository(
    this.userRepository, {
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final UserRepository userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<(OrderKitchenSummary, List<OrderMenuItem>)> fetchKitchen(int id) async {
    final response = await _httpClient
        .get(
          ApiContract.uri('v2/discovery/restaurants/$id'),
          headers: await userRepository.authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to load kitchen menu',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid kitchen response format.');
    }

    final dynamic data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Kitchen payload missing.');
    }

    final kitchen = OrderKitchenSummary.fromJson(data);
    final rawFoods = data['foods'];
    final foods = rawFoods is List
        ? rawFoods
            .whereType<Map>()
            .map((item) => OrderMenuItem.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(growable: false)
        : const <OrderMenuItem>[];

    return (kitchen, foods);
  }

  Future<OrderSubmissionResult> placeOrder({
    required int kitchenId,
    required String deliveryDate,
    required String deliveryTimeFrom,
    required String deliveryTimeTo,
    required OrderServiceType serviceType,
    required List<CartLineItem> items,
    required int? persons,
    required double taxes,
  }) async {
    final payload = <String, dynamic>{
      'kitchen_id': kitchenId,
      'delivery_date': deliveryDate,
      'delivery_time_from': deliveryTimeFrom,
      'delivery_time_to': deliveryTimeTo,
      'taxes': taxes.toStringAsFixed(2),
      'dine_in': serviceType == OrderServiceType.dineIn ? 1 : 0,
      'take_away': serviceType == OrderServiceType.takeAway ? 1 : 0,
      'item_data': encodeOrderItems(items),
    };

    if (serviceType == OrderServiceType.dineIn && persons != null) {
      payload['persons'] = persons;
    }

    final response = await _httpClient
        .post(
          ApiContract.uri('v2/account/orders'),
          headers: await userRepository.authorizedHeaders(
            includeJsonContentType: true,
          ),
          body: jsonEncode(payload),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to place order',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid order response format.');
    }

    return OrderSubmissionResult.fromJson(decoded);
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
