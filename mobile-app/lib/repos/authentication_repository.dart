import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
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
  final controller = StreamController<AuthenticationStatus>();
  final UserRepository _userRepository = UserRepository();

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

  Future<dynamic?> logIn({
    required Map<String, dynamic> data,
  }) async {
    // try {

    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}login';

    print(url);

    final client = http.Client();

    final response = await client.post(Uri.parse(url),
        // headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data));
    print(response.body);
    if (response.statusCode == 200) {
      return response;
    }
    return response;
    // } catch (e) {
    //   print('exception $e');
    // }
  }

  Future<dynamic?> forgot({
    required Map<String, dynamic> data,
  }) async {
    // try {
    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}password/reset';

    print(url);

    final client = http.Client();

    final response = await client.post(Uri.parse(url),
        // headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data));

    if (response.statusCode == 200) {
      return response;
    }
    return response;
  }

  Future<dynamic?> logOutApi({required UserModel? userModel}) async {
    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}v1/logout';

    print(url);

    final client = http.Client();

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer ${userModel!.data!.accessToken}'
      },
    );

    if (response.statusCode == 200) {
      return response;
    }
    return response;
  }

  void logOut() {
    _userRepository.clearuserData();
    //print('app:-unauthenticated_logOut');
    controller.add(AuthenticationStatus.unauthenticated);
  }

  Future<dynamic?> signUp({
    required Map<String, dynamic> data,
  }) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}register';

      print(url);
      print(data);

      final client = http.Client();

      final response = await client.post(Uri.parse(url),
          // headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          headers: {
            'Content-Type': 'application/json',
            // 'Content-Type': 'multipart/form-data',
            // 'accept': 'application/json',
            // 'X-CSRF-TOKEN':''
          },
          body: json.encode(data));

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }

  Future<dynamic?> otpVerify({
    required Map<String, dynamic> data,
  }) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}verifyOtp';

      print(url);
      print(data);

      final client = http.Client();

      final response = await client.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(data));

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }

  Future<dynamic?> vendorKitchnUpload(
      {required Map<String, dynamic> data,
      required RouteArguments? routeArguments,
      required List<String> filePaths}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/mikitchn/store';

      print(url);
      print(data['name']);

      //for multipartrequest
      var request = http.MultipartRequest('POST', Uri.parse(url));

      //for token
      request.headers.addAll(
          {"Authorization": "Bearer ${routeArguments!.data!.accessToken}"});

      //for image and videos and files

      filePaths.forEach((element) async {
        request.files
            .add(await http.MultipartFile.fromPath("images[]", "${element}"));
      });

      request.fields.addAll({
        'name': '${data['name']}',
        'address': '${data['address']}',
        'no_of_seats': '${data['no_of_seats']}',
        'timings': data['timings'],
        // '{\n    \'mon\':{\n        \'isOn\':1,\n        \'timing\': {\n            \'start_time\': \'07:00\',\n            \'end_time\': \'08:00\',\n        }\n    },\n    \'tue\':1,\n    \'wed\':1\n}',
        'phone': '${data['phone']}',
        'user_id': '${data['user_id']}'
      });
      // request.fields['timings'] = '{}';
      print('request ${request.url}  ${request.fields}');
      //for completeing the request
      var response = await request.send();

      //for getting and decoding the response into json format
      var responsed = await http.Response.fromStream(response);
      final responseData = json.decode(responsed.body);

      print('response ${jsonDecode(responsed.body)}');
      if (response.statusCode == 200) {
        print("SUCCESS");
        return responsed;
      }
      return responsed;
    } catch (e) {
      print('exception $e');
    }
  }

  void dispose() => controller.close();
}
