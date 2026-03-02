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

  Future<http.Response> _discoveryGet({
    required String endpoint,
    required Map<String, dynamic> filters,
    required UserModel? userModel,
    Map<String, dynamic> defaultParams = const {},
  }) {
    final queryParameters = <String, dynamic>{
      ...defaultParams,
      ...filters,
    };

    final url = ApiContract.uri(endpoint, queryParameters: queryParameters);

    return _httpClient.get(
      url,
      headers: {
        'Authorization': 'Bearer ${_bearerToken(userModel)}',
        'Accept': 'application/json',
      },
    );
  }

  Future<http.Response> recommendedRestaurants(
      {required Map<String, dynamic> data, required UserModel? userModel}) {
    return _discoveryGet(
      endpoint: 'v2/discovery/recommended',
      filters: data,
      userModel: userModel,
    );
  }

  Future<http.Response> topRatedRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) {
    return _discoveryGet(
      endpoint: 'v2/discovery/top-rated',
      filters: data,
      userModel: userModel,
      defaultParams: {'page': 1, 'limit': 20},
    );
  }

  Future<http.Response> nearByRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) {
    return _discoveryGet(
      endpoint: 'v2/discovery/nearest',
      filters: data,
      userModel: userModel,
      defaultParams: {'page': 1, 'limit': 20},
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
