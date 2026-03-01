import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';

class HomeRepository {
  HomeRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

  String _bearerToken(UserModel? userModel) {
    final token = userModel?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }
    return token;
  }

  Future<http.Response> recommendedRestaurants(
      {required Map<String, dynamic> data, required UserModel? userModel}) async {
    final url = ApiContract.uri('v1/recommendedrestaurant');

    return _httpClient.post(
      url,
      headers: {
        'Authorization': 'Bearer ${_bearerToken(userModel)}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> topRatedRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) async {
    final url = ApiContract.uri(
      'v1/topRatedRestaurant',
      queryParameters: {'page': 1, 'limit': 20},
    );

    return _httpClient.post(
      url,
      headers: {
        'Authorization': 'Bearer ${_bearerToken(userModel)}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> nearByRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) async {
    final url = ApiContract.uri(
      'v1/nearestRestaurant',
      queryParameters: {'page': 1, 'limit': 20},
    );

    return _httpClient.post(
      url,
      headers: {
        'Authorization': 'Bearer ${_bearerToken(userModel)}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
