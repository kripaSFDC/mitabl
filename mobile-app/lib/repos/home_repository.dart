import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';

class HomeRepository {
  HomeRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final http.Client _httpClient;
  final bool _ownsHttpClient;

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

    return _httpClient
        .get(
          url,
          headers: authorizedHeadersForUser(userModel),
        )
        .timeout(ApiContract.requestTimeout);
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
      required UserModel? userModel,
      int page = 1,
      int limit = 20}) {
    return _discoveryGet(
      endpoint: 'v2/discovery/top-rated',
      filters: data,
      userModel: userModel,
      defaultParams: {'page': page, 'limit': limit},
    );
  }

  Future<http.Response> nearByRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel,
      int page = 1,
      int limit = 20}) {
    return _discoveryGet(
      endpoint: 'v2/discovery/nearest',
      filters: data,
      userModel: userModel,
      defaultParams: {'page': page, 'limit': limit},
    );
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
