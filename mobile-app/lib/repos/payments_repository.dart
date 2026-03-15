import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';

class PaymentsRepository {
  PaymentsRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri(
            'v2/account/payments/history',
            queryParameters: {'page': page, 'limit': limit},
          ),
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to fetch payment history',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final records = _extractList(decoded, const ['items', 'data', 'history', 'results']);
    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchSavedCards({
    required UserModel? userModel,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri('v2/payments/cards'),
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to fetch cards',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final records = _extractList(decoded, const ['items', 'data', 'cards', 'results']);
    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> addCard({
    required UserModel? userModel,
    required String paymentMethodId,
  }) async {
    final response = await _httpClient
        .post(
          ApiContract.uri('v2/payments/cards'),
          headers: {
            ...authorizedHeadersForUser(userModel),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'payment_method_id': paymentMethodId}),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to add card',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const {};
    }

    final dynamic data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }

    return decoded;
  }

  Future<String?> createCardCheckoutSession({
    required UserModel? userModel,
  }) async {
    final response = await _httpClient
        .post(
          ApiContract.uri('v2/payments/checkout-session'),
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to create checkout session',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final dynamic topLevelUrl = decoded['url'];
    if (topLevelUrl is String && topLevelUrl.isNotEmpty) {
      return topLevelUrl;
    }

    final dynamic data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nestedUrl = data['url'];
      if (nestedUrl is String && nestedUrl.isNotEmpty) {
        return nestedUrl;
      }
    }

    return null;
  }

  List<dynamic> _extractList(dynamic decoded, List<String> keys) {
    if (decoded is List) return decoded;
    if (decoded is! Map<String, dynamic>) return const [];

    for (final key in keys) {
      final value = decoded[key];
      if (value is List) {
        return value;
      }
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const [];
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
