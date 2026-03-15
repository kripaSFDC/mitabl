import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

export 'package:mitabl_user/helper/app_navigator.dart' show navigatorKey;

enum AuthenticationStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthenticationRepository {
  AuthenticationRepository({
    http.Client? httpClient,
    UserRepository? userRepository,
    SessionRepository? sessionRepository,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _userRepository =
            userRepository ?? UserRepository(httpClient: httpClient),
        _sessionRepository = sessionRepository {
    _sessionSubscription = _sessionRepository?.events.listen((event) async {
      if (event != SessionEvent.unauthorized || _isHandlingUnauthorized) {
        return;
      }

      _isHandlingUnauthorized = true;
      try {
        await _userRepository.clearuserData();
        Helper.showToast('Session expired. Please login again.');
        notifyUnauthenticated();
      } finally {
        _isHandlingUnauthorized = false;
      }
    });
  }

  final _controller = StreamController<AuthenticationStatus>.broadcast();
  final UserRepository _userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final SessionRepository? _sessionRepository;
  StreamSubscription<SessionEvent>? _sessionSubscription;
  bool _isHandlingUnauthorized = false;

  Stream<AuthenticationStatus> get status async* {
    final user = await _userRepository.getUser();

    if (user != null) {
      yield AuthenticationStatus.authenticated;
    } else {
      yield AuthenticationStatus.unauthenticated;
    }

    yield* _controller.stream;
  }

  Future<http.Response> logIn({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('login');

    return _httpClient
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        )
        .timeout(ApiContract.requestTimeout);
  }

  Future<http.Response> forgot({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('password/reset');

    return _httpClient
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        )
        .timeout(ApiContract.requestTimeout);
  }

  Future<http.Response> logOutApi({required UserModel? userModel}) async {
    final url = ApiContract.uri('v2/logout');

    return _httpClient
        .post(
          url,
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);
  }

  Future<void> logOut() async {
    await _userRepository.clearuserData();
    notifyUnauthenticated();
  }

  void notifyAuthenticated() {
    _emitStatus(AuthenticationStatus.authenticated);
  }

  void notifyUnauthenticated() {
    _emitStatus(AuthenticationStatus.unauthenticated);
  }

  void _emitStatus(AuthenticationStatus status) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(status);
  }

  Future<http.Response> signUp({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('register');

    return _httpClient
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        )
        .timeout(ApiContract.requestTimeout);
  }

  Future<http.Response> otpVerify({required Map<String, dynamic> data}) async {
    final url = ApiContract.uri('verifyOtp');

    return _httpClient
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        )
        .timeout(ApiContract.requestTimeout);
  }

  Future<http.Response> vendorKitchnUpload(
      {required Map<String, dynamic> data,
      required RouteArguments? routeArguments,
      required List<String> filePaths}) async {
    try {
      final url = ApiContract.uri('v2/mikitchn/store');
      final request = http.MultipartRequest('POST', url);
      final accessToken = _routeAccessToken(routeArguments);

      request.headers.addAll(buildBearerHeaders(accessToken));

      for (final element in filePaths) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', element));
      }

      request.fields.addAll({
        'name': '${data['name']}',
        'address': '${data['address']}',
        'no_of_seats': '${data['no_of_seats']}',
        'timings': data['timings'],
        'phone': '${data['phone']}',
        'user_id': '${data['user_id']}',
        'dine_in': '${data['dine_in'] ?? 1}',
        'take_away': '${data['take_away'] ?? 1}',
        if (data.containsKey('dine_in_slots'))
          'dine_in_slots': '${data['dine_in_slots']}',
      });

      final response =
          await _httpClient.send(request).timeout(ApiContract.requestTimeout);
      final responsed = await http.Response.fromStream(response);

      return responsed;
    } catch (e) {
      AppLogger.error('Vendor kitchen upload failed', e);
      rethrow;
    }
  }

  String _routeAccessToken(RouteArguments? routeArguments) {
    final token = routeArguments?.data?.accessToken;
    if (token is! String || token.trim().isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }

    return token.trim();
  }

  void dispose() {
    _sessionSubscription?.cancel();
    _controller.close();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
