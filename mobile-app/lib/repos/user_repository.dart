import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';

final navigatorKeyHome = GlobalKey<NavigatorState>();

class UserRepository {
  UserRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  UserModel? user;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<String> _accessToken() async {
    final currentUser = user ?? await getUser();
    final token = currentUser?.data?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }

    return token;
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('current_user')) {
      final userMap =
          jsonDecode(prefs.getString('current_user')!) as Map<String, dynamic>;
      user = UserModel.fromJson(userMap);
    } else {
      return user;
    }
    return user;
  }

  Future<void> setCurrentUser(String jsonString) async {
    try {
      if (json.decode(jsonString) != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs
            .setString('current_user', json.encode(json.decode(jsonString)))
            .then((value) {
          updateUserInstance();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to set current user', e);
      throw Exception(e);
    }
  }

  void updateUserInstance() {
    user = null;
    getUser();
  }

  void clearuserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('current_user')) {
      prefs.remove('current_user');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    return user;
  }

  Future<http.Response> getCookProfile() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getprofile';

      return _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${await _accessToken()}',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      AppLogger.error('Failed to get cook profile', e);
      rethrow;
    }
  }

  Future<http.Response> getDashboardData() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getdashboarddata';

      return _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${await _accessToken()}',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      AppLogger.error('Failed to get dashboard data', e);
      rethrow;
    }
  }

  Future<http.Response> getFoodieProfile() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getcustomerprofile';

      return _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${await _accessToken()}',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      AppLogger.error('Failed to get foodie profile', e);
      rethrow;
    }
  }

  Future<http.Response> deleteImage({String? type, String? id}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/deleteimage';

      return _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${await _accessToken()}',
          'Accept': 'application/json',
        },
        body: {'id': id, 'type': type},
      );
    } catch (e) {
      AppLogger.error('Failed to delete image', e);
      rethrow;
    }
  }

  Future<http.Response> updateCookProfile(
      {required Map<String, String> data, required String filePath}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/editprofile';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      });

      if (filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      }

      request.fields.addAll(data);
      final response = await request.send();

      return http.Response.fromStream(response);
    } catch (e) {
      AppLogger.error('Failed to update cook profile', e);
      rethrow;
    }
  }

  Future<http.Response> updateFoodieProfile(
      {required Map<String, String> data, required String filePath}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/editprofile';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      });

      if (filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      }

      request.fields.addAll(data);
      final response = await request.send();

      return http.Response.fromStream(response);
    } catch (e) {
      AppLogger.error('Failed to update foodie profile', e);
      rethrow;
    }
  }

  Future<http.Response> vendorKitchenEditUpload(
      {required Map<String, dynamic> data,
      required List<String> filePaths}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/mikitchn/editkitchen';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer ${await _accessToken()}',
        'Accept': 'application/json',
      });

      if (filePaths.isNotEmpty) {
        for (final element in filePaths) {
          request.files
              .add(await http.MultipartFile.fromPath('images[]', element));
        }
      }

      request.fields.addAll({
        'name': '${data['name']}',
        'address': '${data['address']}',
        'no_of_seats': '${data['no_of_seats']}',
        'timings': data['timings'],
        'phone': '${data['phone']}',
        'take_away': '${data['take_away']}',
        'dine_in': '${data['dine_in']}',
        'description': '${data['description']}',
      });
      final response = await request.send();

      return http.Response.fromStream(response);
    } catch (e) {
      AppLogger.error('Failed to update vendor kitchen', e);
      rethrow;
    }
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
