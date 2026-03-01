import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart' as http;

class BookingRepository {
  final UserRepository? userRepository;

  BookingRepository(this.userRepository);

  String _accessToken() {
    final token = userRepository?.user?.data?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token unavailable. Please login again.');
    }
    return token;
  }

  Future<dynamic?> getBookings(
      {int? page, int? limit, bool isUpcoming = false, String? sortBy, String? status = ''}) async {
    try {
      final resolvedPage = page ?? 1;
      final resolvedLimit = limit ?? 10;
      final safeSortBy = sortBy ?? '';
      final safeStatus = status ?? '';

      final endpoint = isUpcoming ? 'v1/kitchenupcomingorders' : 'v1/allorders';
      final url = ApiContract.uri(
        endpoint,
        queryParameters: {
          'page': resolvedPage,
          'limit': resolvedLimit,
          'sortby': safeSortBy,
          if (!isUpcoming) 'status': safeStatus,
        },
      );

      print(url);

      final client = http.Client();

      final response = await client.post(
        url,
        headers: {
          "Authorization": "Bearer ${_accessToken()}",
          "Accept": "application/json",
        },
      );

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }

  Future<dynamic?> updateOrderStatus(
      {bool? isUpcoming, Map<String, dynamic>? data}) async {
    try {
      final url = ApiContract.uri('v1/updateorderstatus');

      print(url);
      print(data);

      final client = http.Client();

      final response = await client.post(url,
          headers: {
            "Authorization": "Bearer ${_accessToken()}",
            "Accept": "application/json",
          },
          body: data);

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }

  Future<dynamic?> getRequests({int? page, int? limit}) async {
    try {
      final resolvedPage = page ?? 1;
      final resolvedLimit = limit ?? 10;

      final url = ApiContract.uri(
        'v1/kitchenorderrequest',
        queryParameters: {'page': resolvedPage, 'limit': resolvedLimit},
      );

      print(url);

      final client = http.Client();

      final response = await client.get(
        url,
        headers: {
          "Authorization": "Bearer ${_accessToken()}",
          "Accept": "application/json",
        },
      );

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }
}
