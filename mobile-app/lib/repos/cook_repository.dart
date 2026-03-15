import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'dart:convert';

class CookRepository {
  CookRepository(this.userRepository, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final UserRepository? userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<Map<String, String>> _authorizedHeaders() async {
    final repo = userRepository;
    if (repo == null) {
      throw Exception('User repository unavailable.');
    }

    return repo.authorizedHeaders();
  }

  Future<http.Response> getFoodMenu() async {
    final response = await _httpClient
        .get(
          ApiContract.uri('v2/mymenu'),
          headers: await _authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);
    return response;
  }

  Future<http.Response> getSpecialDiets() async {
    final response = await _httpClient
        .get(
          ApiContract.uri('v2/getspecialdiets'),
          headers: await _authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);
    return response;
  }

  Future<http.Response> getCookingStyle() async {
    final response = await _httpClient
        .get(
          ApiContract.uri('v2/getcookingstyles'),
          headers: await _authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);
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

    request.headers.addAll(await _authorizedHeaders());

    if (filePaths.isNotEmpty) {
      for (final element in filePaths) {
        request.files
            .add(await http.MultipartFile.fromPath('pictures[]', element));
      }
    }

    request.fields.addAll({
      'food_name': '${data['food_name']}',
      'price': '${data['price']}',
      'cookingstyle': '${data['cookingstyle']}',
      'delete_images': '${data['delete_images'] ?? ''}',
      'description': '${data['description']}',
      'available_date': '${data['available_date'] ?? ''}',
      'available_from_time': '${data['available_from_time'] ?? ''}',
      'available_to_time': '${data['available_to_time'] ?? ''}',
      'available_days_json':
          jsonEncode(data['available_days'] as List<dynamic>? ?? const []),
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

    final response =
        await _httpClient.send(request).timeout(ApiContract.requestTimeout);
    final resolved = await http.Response.fromStream(response);
    if (resolved.statusCode >= 500) {
      AppLogger.error('saveMenuItem server error', resolved.statusCode);
    }
    return resolved;
  }

  Future<http.Response> changFoodStatus({String? foodId}) async {
    final response = await _httpClient
        .post(
          ApiContract.uri('v2/food/status/$foodId'),
          headers: await _authorizedHeaders(),
        )
        .timeout(ApiContract.requestTimeout);
    return response;
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
