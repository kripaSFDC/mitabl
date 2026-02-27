import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart' as http;

class BookingRepository {
  final UserRepository? userRepository;

  BookingRepository(this.userRepository);

  Future<dynamic?> getBookings(
      {int? page, int? limit, bool? isUpcoming, String? sortBy, String? status = ''}) async {
    try {
      final url = isUpcoming!
          ? '${GlobalConfiguration().getValue<String>('api_base_url')}v1/kitchenupcomingorders?page=${1}&limit=${10}${sortBy!.isNotEmpty ? '&sortby=${sortBy}' : ''}'
          : '${GlobalConfiguration().getValue<String>('api_base_url')}v1/allorders?page=${1}&limit=${10}${sortBy!.isNotEmpty ? '&sortby=${sortBy}' : ''}${status!.isNotEmpty ? '&status=${status}' : ''}';

      print(url);

      final client = http.Client();

      final response = await client.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${userRepository!.user!.data!.accessToken}"
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
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/updateorderstatus';

      print(url);
      print(data);

      final client = http.Client();

      final response = await client.post(Uri.parse(url),
          headers: {
            "Authorization": "Bearer ${userRepository!.user!.data!.accessToken}"
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
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/kitchenorderrequest?page=${page}&limit=${limit}';

      print(url);

      final client = http.Client();

      final response = await client.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${userRepository!.user!.data!.accessToken}"
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
