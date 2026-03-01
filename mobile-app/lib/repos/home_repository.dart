import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';

class HomeRepository {
  HomeRepository({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<http.Response> recommendedRestaurants(
      {required Map<String, dynamic> data, required UserModel? userModel}) async {
    final url = ApiContract.uri('v1/recommendedrestaurant');

    return _httpClient.post(
      url,
      headers: {
        'Authorization': 'Bearer ${userModel!.data!.accessToken}',
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
        'Authorization': 'Bearer ${userModel!.data!.accessToken}',
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
        'Authorization': 'Bearer ${userModel!.data!.accessToken}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
