import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/user_repository.dart';

enum AuthenticationStatus {
  unknown,
  authenticated,
  unauthenticated,
}

final navigatorKey = GlobalKey<NavigatorState>();

class AuthenticationRepository {
  AuthenticationRepository({http.Client? httpClient, UserRepository? userRepository})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _userRepository = userRepository ?? UserRepository(httpClient: httpClient);

  final controller = StreamController<AuthenticationStatus>();
  final UserRepository _userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  String _accessToken(UserModel? userModel) {
    final token = userModel?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }
    return token;
  }

  Stream<AuthenticationStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 3));

    final user = await _userRepository.getUser();

    if (user != null) {
      yield AuthenticationStatus.authenticated;
    } else {
      yield AuthenticationStatus.unauthenticated;
    }

    yield* controller.stream;
  }

  Future<http.Response> logIn({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('login');

    return _httpClient.post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> forgot({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('password/reset');

    return _httpClient.post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> logOutApi({required UserModel? userModel}) async {
    final url = ApiContract.uri('v1/logout');

    return _httpClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_accessToken(userModel)}'
      },
    );
  }

  void logOut() {
    _userRepository.clearuserData();
    controller.add(AuthenticationStatus.unauthenticated);
  }

  Future<http.Response> signUp({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('register');

    return _httpClient.post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> otpVerify({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('verifyOtp');

    return _httpClient.post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
  }

  Future<http.Response> vendorKitchnUpload(
      {required Map<String, dynamic> data,
      required RouteArguments? routeArguments,
      required List<String> filePaths}) async {
    try {
      final url = ApiContract.uri('v1/mikitchn/store');

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer ${routeArguments!.data!.accessToken}',
        'Accept': 'application/json',
      });

      for (final element in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', element));
      }

      request.fields.addAll({
        'name': '${data['name']}',
        'address': '${data['address']}',
        'no_of_seats': '${data['no_of_seats']}',
        'timings': data['timings'],
        'phone': '${data['phone']}',
        'user_id': '${data['user_id']}'
      });

      final response = await request.send();
      final responsed = await http.Response.fromStream(response);

      return responsed;
    } catch (e) {
      AppLogger.error('Vendor kitchen upload failed', e);
      rethrow;
    }
  }

  void dispose() {
    controller.close();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
