import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart' as http;

class BookingRepository {
  BookingRepository(this.userRepository, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final UserRepository? userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<String> _accessToken() async {
    final userModel = await userRepository?.getUser();
    final token = userModel?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }
    return token;
  }

  Future<http.Response> getBookings(
      {int? page, int? limit, bool isUpcoming = false, String? sortBy, String? status = ''}) async {
    final resolvedPage = page ?? 1;
    final resolvedLimit = limit ?? 10;
    final safeSortBy = sortBy ?? '';
    final safeStatus = status ?? '';

    final endpoint = isUpcoming ? 'v2/kitchenupcomingorders' : 'v2/allorders';
    final url = ApiContract.uri(
      endpoint,
      queryParameters: {
        'page': resolvedPage,
        'limit': resolvedLimit,
        'sortby': safeSortBy,
        if (!isUpcoming) 'status': safeStatus,
      },
    );

    final response = await _httpClient.post(
      url,
      headers: {
        "Authorization": "Bearer ${await _accessToken()}",
        "Accept": "application/json",
      },
    );

    return response;
  }

  Future<http.Response> updateOrderStatus(
      {bool? isUpcoming, Map<String, dynamic>? data}) async {
    final url = ApiContract.uri('v2/updateorderstatus');

    final response = await _httpClient.post(url,
        headers: {
          "Authorization": "Bearer ${await _accessToken()}",
          "Accept": "application/json",
        },
        body: data);

    return response;
  }

  Future<http.Response> getRequests({int? page, int? limit}) async {
    final resolvedPage = page ?? 1;
    final resolvedLimit = limit ?? 10;

    final url = ApiContract.uri(
      'v2/kitchenorderrequest',
      queryParameters: {'page': resolvedPage, 'limit': resolvedLimit},
    );

    final response = await _httpClient.get(
      url,
      headers: {
        "Authorization": "Bearer ${await _accessToken()}",
        "Accept": "application/json",
      },
    );

    return response;
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
