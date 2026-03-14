import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';

class FavouritesRepository {
  FavouritesRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _httpClient
        .get(
          ApiContract.uri(
            'v1/foodie/favourites',
            queryParameters: {'page': page, 'limit': limit},
          ),
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch favourites');
    }

    final dynamic decoded = jsonDecode(response.body);
    final records = _extractList(decoded, const ['data', 'favourites', 'results']);
    return records
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<http.Response> toggleFavourite({
    required UserModel? userModel,
    required String targetId,
  }) {
    return _httpClient
        .post(
          ApiContract.uri('v1/foodie/favourites/toggle'),
          headers: authorizedHeadersForUser(userModel),
          body: {'target_id': targetId},
        )
        .timeout(ApiContract.requestTimeout);
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
