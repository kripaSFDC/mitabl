import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';

class MobileContactRepository {
  MobileContactRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<Map<String, dynamic>> fetch(UserModel? userModel) async {
    final token = userModel?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }

    final response = await _httpClient.get(
      ApiContract.uri('v2/mob-contact'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(ApiContract.requestTimeout);

    if (response.statusCode >= 400) {
      throw Exception('Unable to fetch contact details (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'message': response.body};
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
