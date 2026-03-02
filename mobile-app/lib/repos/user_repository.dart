import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
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
  static const _secureStorage = FlutterSecureStorage();
  static const _secureCurrentUserKey = 'current_user_secure';

  http.Client get httpClient => _httpClient;

  Future<String> _accessToken() async {
    final currentUser = user ?? await getUser();
    final token = currentUser?.data?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }

    return token;
  }

  Future<UserModel?> getUser() async {
    final secureJson = await _secureStorage.read(key: _secureCurrentUserKey);
    if (secureJson != null && secureJson.isNotEmpty) {
      final userMap = jsonDecode(secureJson) as Map<String, dynamic>;
      user = UserModel.fromJson(userMap);
      return user;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('current_user')) {
      return user;
    }

    final legacyJson = prefs.getString('current_user');
    if (legacyJson == null || legacyJson.isEmpty) {
      return user;
    }

    final userMap = jsonDecode(legacyJson) as Map<String, dynamic>;
    user = UserModel.fromJson(userMap);

    // One-time migration from insecure preference storage.
    await _secureStorage.write(
      key: _secureCurrentUserKey,
      value: json.encode(userMap),
    );
    await prefs.remove('current_user');

    return user;
  }

  Future<void> setCurrentUser(String jsonString) async {
    try {
      if (json.decode(jsonString) != null) {
        final prefs = await SharedPreferences.getInstance();
        final normalized = json.encode(json.decode(jsonString));

        await _secureStorage.write(
          key: _secureCurrentUserKey,
          value: normalized,
        );
        await prefs.remove('current_user');
        updateUserInstance();
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
    await _secureStorage.delete(key: _secureCurrentUserKey);
    if (prefs.containsKey('current_user')) {
      await prefs.remove('current_user');
    }
    user = null;
  }

  Future<UserModel?> getCurrentUser() async {
    return user;
  }

  Future<http.Response> getCookProfile() async {
    try {
      return _httpClient.get(
        ApiContract.uri('v2/getprofile'),
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
      return _httpClient.get(
        ApiContract.uri('v2/getdashboarddata'),
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
      return _httpClient.get(
        ApiContract.uri('v2/getcustomerprofile'),
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
      return _httpClient.post(
        ApiContract.uri('v2/deleteimage'),
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
    return _updateProfile(data: data, filePath: filePath);
  }

  Future<http.Response> updateFoodieProfile(
      {required Map<String, String> data, required String filePath}) async {
    return _updateProfile(data: data, filePath: filePath);
  }

  Future<http.Response> _updateProfile(
      {required Map<String, String> data, required String filePath}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        ApiContract.uri('v2/editprofile'),
      );

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
      AppLogger.error('Failed to update profile', e);
      rethrow;
    }
  }

  Future<http.Response> vendorKitchenEditUpload(
      {required Map<String, dynamic> data,
      required List<String> filePaths}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        ApiContract.uri('v2/mikitchn/editkitchen'),
      );

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
