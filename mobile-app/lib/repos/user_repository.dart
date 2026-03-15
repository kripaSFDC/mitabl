import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/repos/auth_headers.dart' as auth_headers;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';

class UserRepository {
  UserRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  UserModel? _user;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  static const _secureStorage = FlutterSecureStorage();
  static const _secureCurrentUserKey = 'current_user_secure';

  http.Client get httpClient => _httpClient;
  UserModel? get currentUser => _user;

  Future<String> requireAccessToken() async {
    final currentUser = _user ?? await getUser();
    return auth_headers.requireAccessToken(currentUser);
  }

  Future<Map<String, String>> authorizedHeaders({
    bool includeJsonContentType = false,
    Map<String, String> additionalHeaders = const {},
  }) async {
    return auth_headers.buildBearerHeaders(
      await requireAccessToken(),
      includeJsonContentType: includeJsonContentType,
      additionalHeaders: additionalHeaders,
    );
  }

  Future<UserModel?> getUser() async {
    if (_user != null) {
      return _user;
    }

    final secureJson = await _secureStorage.read(key: _secureCurrentUserKey);
    if (secureJson != null && secureJson.isNotEmpty) {
      final userMap = jsonDecode(secureJson) as Map<String, dynamic>;
      _user = UserModel.fromJson(userMap);
      return _user;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('current_user')) {
      return _user;
    }

    final legacyJson = prefs.getString('current_user');
    if (legacyJson == null || legacyJson.isEmpty) {
      return _user;
    }

    final userMap = jsonDecode(legacyJson) as Map<String, dynamic>;
    _user = UserModel.fromJson(userMap);

    // One-time migration from insecure preference storage.
    await _secureStorage.write(
      key: _secureCurrentUserKey,
      value: json.encode(userMap),
    );
    await prefs.remove('current_user');

    return _user;
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
        await updateUserInstance();
      }
    } catch (e) {
      AppLogger.error('Failed to set current user', e);
      throw Exception(e);
    }
  }

  Future<void> updateUserInstance() async {
    _user = null;
    _user = await getUser();
  }

  Future<void> clearuserData() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _secureCurrentUserKey);
    if (prefs.containsKey('current_user')) {
      await prefs.remove('current_user');
    }
    _user = null;
  }

  Future<UserModel?> getCurrentUser() async {
    return _user ?? await getUser();
  }

  Future<http.Response> getCookProfile() async {
    try {
      return _httpClient
          .get(
            ApiContract.uri('v2/account/profile'),
            headers: await authorizedHeaders(),
          )
          .timeout(ApiContract.requestTimeout);
    } catch (e) {
      AppLogger.error('Failed to get cook profile', e);
      rethrow;
    }
  }

  Future<http.Response> getDashboardData() async {
    try {
      return _httpClient
          .get(
            ApiContract.uri('v2/account/dashboard'),
            headers: await authorizedHeaders(),
          )
          .timeout(ApiContract.requestTimeout);
    } catch (e) {
      AppLogger.error('Failed to get dashboard data', e);
      rethrow;
    }
  }

  Future<http.Response> getFoodieProfile() async {
    try {
      return _httpClient
          .get(
            ApiContract.uri('v2/account/profile'),
            headers: await authorizedHeaders(),
          )
          .timeout(ApiContract.requestTimeout);
    } catch (e) {
      AppLogger.error('Failed to get foodie profile', e);
      rethrow;
    }
  }

  Future<http.Response> updateNotificationPreference({
    required bool enabled,
    String? deviceToken,
  }) async {
    try {
      final payload = <String, dynamic>{'notifications_enabled': enabled};
      if (deviceToken != null && deviceToken.isNotEmpty) {
        payload['device_key'] = deviceToken;
      }

      return _httpClient
          .post(
            ApiContract.uri('v2/account/notification-preferences'),
            headers: await authorizedHeaders(includeJsonContentType: true),
            body: json.encode(payload),
          )
          .timeout(ApiContract.requestTimeout);
    } catch (e) {
      AppLogger.error('Failed to update notification preferences', e);
      rethrow;
    }
  }

  Future<http.Response> switchRole({required int roleId}) async {
    try {
      final response = await _httpClient
          .post(
            ApiContract.uri('v2/account/switch-role'),
            headers: await authorizedHeaders(includeJsonContentType: true),
            body: json.encode({'role_id': roleId}),
          )
          .timeout(ApiContract.requestTimeout);

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          final roleName = data['role']?.toString() ??
              (data['user'] is Map<String, dynamic>
                  ? (data['user']['data']?['role'] ?? data['user']['role'])
                      ?.toString()
                  : null);
          final resolvedRoleId = data['role_id'] ??
              (data['user'] is Map<String, dynamic>
                  ? (data['user']['data']?['role_id'] ??
                      data['user']['role_id'])
                  : null);

          try {
            await syncCurrentUserRole(
              roleName: roleName,
              roleId: resolvedRoleId,
            );
          } catch (e) {
            AppLogger.error(
                'Role switched but failed to sync local user role', e);
            _user?.data?.user?.role = roleName;
            if (resolvedRoleId is int) {
              _user?.data?.user?.roleId = resolvedRoleId;
            } else if (resolvedRoleId is String) {
              _user?.data?.user?.roleId = int.tryParse(resolvedRoleId);
            }
          }
        }
      }

      return response;
    } catch (e) {
      AppLogger.error('Failed to switch role', e);
      rethrow;
    }
  }

  Future<void> syncCurrentUserRole({String? roleName, dynamic roleId}) async {
    final prefs = await SharedPreferences.getInstance();
    final secureJson = await _secureStorage.read(key: _secureCurrentUserKey);
    final storedJson = secureJson ?? prefs.getString('current_user');
    if (storedJson == null || storedJson.isEmpty) {
      return;
    }

    final root = jsonDecode(storedJson) as Map<String, dynamic>;
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      return;
    }

    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      return;
    }

    if (roleName != null && roleName.trim().isNotEmpty) {
      user['role'] = roleName;
    }

    int? parsedRoleId;
    if (roleId is int) {
      parsedRoleId = roleId;
    } else if (roleId is String) {
      parsedRoleId = int.tryParse(roleId);
    }
    if (parsedRoleId != null) {
      user['role_id'] = parsedRoleId;
    }

    final normalized = json.encode(root);
    await _secureStorage.write(key: _secureCurrentUserKey, value: normalized);
    await prefs.remove('current_user');
    await updateUserInstance();
  }

  Future<http.Response> deleteAccount() async {
    try {
      final headers = await authorizedHeaders();
      final uri = ApiContract.uri('v2/account/delete');
      final deleteResponse = await _httpClient
          .delete(
            uri,
            headers: headers,
          )
          .timeout(ApiContract.requestTimeout);

      if (deleteResponse.statusCode == 404 ||
          deleteResponse.statusCode == 405 ||
          deleteResponse.statusCode == 501) {
        return _httpClient
            .post(
              uri,
              headers: headers,
            )
            .timeout(ApiContract.requestTimeout);
      }

      return deleteResponse;
    } catch (e) {
      AppLogger.error('Failed to delete account', e);
      rethrow;
    }
  }

  Future<http.Response> deleteImage({String? type, String? id}) async {
    try {
      return _httpClient.post(
        ApiContract.uri('v2/deleteimage'),
        headers: await authorizedHeaders(),
        body: {'id': id, 'type': type},
      ).timeout(ApiContract.requestTimeout);
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

      request.headers.addAll(await authorizedHeaders());

      if (filePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath('avatar', filePath));
      }

      request.fields.addAll(data);
      final response =
          await _httpClient.send(request).timeout(ApiContract.requestTimeout);
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

      request.headers.addAll(await authorizedHeaders());

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
        'abn': '${data['abn'] ?? ''}',
        'certificate_no': '${data['certificate_no'] ?? ''}',
        if (data.containsKey('dine_in_slots'))
          'dine_in_slots': '${data['dine_in_slots']}',
      });
      final response =
          await _httpClient.send(request).timeout(ApiContract.requestTimeout);

      return http.Response.fromStream(response);
    } catch (e) {
      AppLogger.error('Failed to update vendor kitchen', e);
      rethrow;
    }
  }

  Future<http.Response> fetchMyDineInSlots() async {
    try {
      return _httpClient
          .get(
            ApiContract.uri('v2/mikitchn/dine-in-slots'),
            headers: await authorizedHeaders(),
          )
          .timeout(ApiContract.requestTimeout);
    } catch (e) {
      AppLogger.error('Failed to load dine-in slots', e);
      rethrow;
    }
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
