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

  Future<(OrderKitchenSummary, List<OrderMenuItem>)> fetchKitchen(
      int id) async {
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
            .map((item) =>
                OrderMenuItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <OrderMenuItem>[];

    return (kitchen, foods);
  }

  Future<List<OrderMenuItem>> fetchMenu({
    required int kitchenId,
    required String deliveryDate,
    required OrderServiceType serviceType,
    String? deliveryTimeFrom,
    String? deliveryTimeTo,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri(
            'v2/discovery/restaurants/$kitchenId/menu',
            queryParameters: <String, dynamic>{
              'delivery_date': deliveryDate,
              if (deliveryTimeFrom != null)
                'delivery_time_from': deliveryTimeFrom,
              if (deliveryTimeTo != null) 'delivery_time_to': deliveryTimeTo,
              'dine_in': serviceType == OrderServiceType.dineIn ? 1 : 0,
              'take_away': serviceType == OrderServiceType.takeAway ? 1 : 0,
            },
          ),
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
    final dynamic data =
        decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const FormatException('Invalid menu response format.');
    }

    return data
        .whereType<Map>()
        .map((item) => OrderMenuItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<OrderSubmissionResult> placeOrder({
    required int kitchenId,
    required String deliveryDate,
    required String deliveryTimeFrom,
    required String deliveryTimeTo,
    required OrderServiceType serviceType,
    required List<CartLineItem> items,
    required int? persons,
    required int? dineInSlotId,
    required double taxes,
    OrderPaymentSelection? paymentSelection,
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
      if (paymentSelection != null &&
          paymentSelection.mode == CheckoutPaymentMode.savedCard)
        'card_id': paymentSelection.reference.trim(),
      if (paymentSelection != null &&
          paymentSelection.mode == CheckoutPaymentMode.oneTimePaymentMethod)
        'payment_method_id': paymentSelection.reference.trim(),
    };

    if (serviceType == OrderServiceType.dineIn && persons != null) {
      payload['persons'] = persons;
      if (dineInSlotId != null) {
        payload['dine_in_slot_id'] = dineInSlotId;
      }
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
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

  Future<List<DineInSlotOption>> fetchDineInSlots({
    required int kitchenId,
    required String date,
    int? persons,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri(
            'v2/discovery/restaurants/$kitchenId/dine-in-slots',
            queryParameters: <String, dynamic>{
              'date': date,
              if (persons != null) 'persons': persons,
            },
          ),
          headers: await userRepository.authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to load dine-in slots',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data =
        decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const FormatException('Invalid dine-in slot response format.');
    }

    return data
        .whereType<Map>()
        .map((slot) =>
            DineInSlotOption.fromJson(Map<String, dynamic>.from(slot)))
        .toList(growable: false);
  }

  Future<OrderSubmissionResult> attachPaymentMethodToOrder({
    required int orderId,
    required OrderPaymentSelection selection,
  }) async {
    final payload = <String, dynamic>{
      'order_id': orderId,
      if (selection.mode == CheckoutPaymentMode.savedCard)
        'card_id': selection.reference.trim(),
      if (selection.mode == CheckoutPaymentMode.oneTimePaymentMethod)
        'payment_method_id': selection.reference.trim(),
    };

    final response = await _httpClient
        .post(
          ApiContract.uri('v2/payments/intent'),
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
        fallbackMessage: 'Unable to save payment method for this order',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid payment intent response format.');
    }

    final Map<String, dynamic> merged = <String, dynamic>{
      'message': decoded['message']?.toString() ?? 'Payment method attached.',
      'data': {
        'order_id': orderId,
        'payment_id': decoded['data']?['payment_id'],
        'payment_intent_id': decoded['data']?['payment_intent_id'],
        'payment_method_id': decoded['data']?['payment_method_id'],
        'total_price': '0.00',
      },
    };

    return OrderSubmissionResult.fromJson(merged);
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
