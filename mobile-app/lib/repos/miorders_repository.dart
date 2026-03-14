import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';

class MiOrdersRepository {
  MiOrdersRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri(
            'v2/account/orders',
            queryParameters: {'page': page, 'limit': limit},
          ),
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw RepositoryHttpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'Unable to fetch orders history',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final records = _extractList(decoded, const ['items', 'data', 'orders', 'results']);
    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
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
