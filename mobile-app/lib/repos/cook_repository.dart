import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class CookRepository {
  CookRepository(this.userRepository, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final UserRepository? userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<String> _accessToken() async {
    final repo = userRepository;
    if (repo == null) {
      throw Exception('User repository unavailable.');
    }
    final currentUser = repo.currentUser ?? await repo.getUser();
    final token = currentUser?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }
    return token;
  }

  Future<http.Response> getFoodMenu() async {
    final response = await _httpClient.get(
      ApiContract.uri('v2/mymenu'),
      headers: {
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      },
    ).timeout(ApiContract.requestTimeout);
    return response;
  }

  Future<http.Response> getSpecialDiets() async {
    final response = await _httpClient.get(
      ApiContract.uri('v2/getspecialdiets'),
      headers: {
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      },
    ).timeout(ApiContract.requestTimeout);
    return response;
  }

  Future<http.Response> getCookingStyle() async {
    final response = await _httpClient.get(
      ApiContract.uri('v2/getcookingstyles'),
      headers: {
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      },
    ).timeout(ApiContract.requestTimeout);
    return response;
  }

  Future<http.Response> saveMenuItem(
      {required Map<String, dynamic> data,
      required List<String> filePaths,
      bool? isEdit,
      List<String>? deleteImagsId = const []}) async {
    final urlSet = (isEdit ?? false) ? 'editfood' : 'add';
    final request = http.MultipartRequest(
      'POST',
      ApiContract.uri('v2/food/$urlSet'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer ${await _accessToken()}',
      'Accept': 'application/json',
    });

    if (filePaths.isNotEmpty) {
      for (final element in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('pictures[]', element));
      }
    }

    request.fields.addAll({
      'food_name': '${data['food_name']}',
      'price': '${data['price']}',
      'cookingstyle': '${data['cookingstyle']}',
      'delete_images': '${data['delete_images'] ?? ''}',
      'description': '${data['description']}',
    });

    final specialDietIds = (data['specialDietIds'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList();

    for (var i = 0; i < specialDietIds.length; i++) {
      request.fields['specialDiet[$i]'] = specialDietIds[i];
    }

    if (isEdit ?? false) {
      request.fields.addAll({'food_id': '${data['food_id']}'});
    } else {
      request.fields.addAll({'restaurant_id': '${data['restaurant_id']}'});
    }

    final response = await request.send().timeout(ApiContract.requestTimeout);
    final resolved = await http.Response.fromStream(response);
    if (resolved.statusCode >= 500) {
      AppLogger.error('saveMenuItem server error', resolved.statusCode);
    }
    return resolved;
  }

  Future<http.Response> changFoodStatus({String? foodId}) async {
    final response = await _httpClient.post(
      ApiContract.uri('v2/food/status/$foodId'),
      headers: {
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      },
    ).timeout(ApiContract.requestTimeout);
    return response;
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
