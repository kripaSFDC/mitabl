import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/user_model.dart';

final navigatorKeyHome = GlobalKey<NavigatorState>();

class UserRepository {
  UserModel? user;

  Future<UserModel?> getUser() async {
    var prefs = await SharedPreferences.getInstance();
    //await prefs.clear();
    if (/*user == null &&*/ prefs.containsKey('current_user')) {
      //  _user =User.fromJson( json.decode(await prefs.get('current_user'));
      var userMap =
          jsonDecode(prefs.getString('current_user')!) as Map<String, dynamic>;
      user = UserModel.fromJson(userMap);

      //print("userfound ${user!.toJson()}");
    } else {
      // print("user null");
      return user;
    }
    return user;
  }

  Future<void> setCurrentUser(String jsonString) async {
    try {
      if (json.decode(jsonString) != null) {
        var prefs = await SharedPreferences.getInstance();
        // var user = User.fromJson(json.decode(jsonString)['result']);
        // await prefs.setString("apiKey", user.apiKey!);

        await prefs
            .setString('current_user', json.encode(json.decode(jsonString)))
            .then((value) {
          //print('user saved ');
          updateUserInstance();
        });
      }
    } catch (e) {
      print(e.toString());
      throw Exception(e);
    }
  }

  void updateUserInstance() {
    user = null;
    getCurrentUser();
  }

  void clearuserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('current_user')) {
      prefs.remove('current_user');
      // prefs.remove(AppConstants.VERSION_INFO);
    }
    /* if (prefs.containsKey('disclosure')) {
      prefs.remove('disclosure');
    }*/
    // prefs.clear();
  }

  Future<UserModel?> getCurrentUser() async {
    return user;
  }

  Future<dynamic?> getCookProfile() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getprofile';

      print(url);
      print(user!.data!.accessToken);
      final client = http.Client();

      final response = await client.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${user!.data!.accessToken}"},
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

  Future<dynamic?> getDashboardData() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getdashboarddata';

      print(url);
      print(user!.data!.accessToken);
      final client = http.Client();

      final response = await client.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${user!.data!.accessToken}"},
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


  Future<dynamic?> getFoodieProfile() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getcustomerprofile';

      print(url);
      print(user!.data!.accessToken);
      final client = http.Client();

      final response = await client.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${user!.data!.accessToken}"},
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


  Future<dynamic?> deleteImage({String? type, String? id}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/deleteimage';

      print(url);
      print(user!.data!.accessToken);
      final client = http.Client();

      var map = {};
      map['id'] = id;
      map['type'] = type;

      final response = await client.post(Uri.parse(url),
          headers: {"Authorization": "Bearer ${user!.data!.accessToken}"},
          body: map);

      print('response ${response.body}');
      if (response.statusCode == 200) {
        return response;
      }
      return response;
    } catch (e) {
      print('exception $e');
    }
  }

  //  v1/editprofile
  Future<dynamic?> updateCookProfile(
      {required Map<String, String> data, required String filePath}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/editprofile';

      print(url);
      print(data);

      //for multipartrequest
      var request = http.MultipartRequest('POST', Uri.parse(url));

      //for token
      request.headers
          .addAll({"Authorization": "Bearer ${user!.data!.accessToken}"});

      //for image and videos and files

      if (filePath.toString() != '') {
        request.files
            .add(await http.MultipartFile.fromPath("avatar", filePath));
      }

      request.fields.addAll(data);
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

  //  v1/editprofile
  Future<dynamic?> updateFoodieProfile(
      {required Map<String, String> data, required String filePath}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/editprofile';

      print(url);
      print(data);

      //for multipartrequest
      var request = http.MultipartRequest('POST', Uri.parse(url));

      //for token
      request.headers
          .addAll({"Authorization": "Bearer ${user!.data!.accessToken}"});

      //for image and videos and files

      if (filePath.toString() != '') {
        request.files
            .add(await http.MultipartFile.fromPath("avatar", filePath));
      }

      request.fields.addAll(data);
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

  Future<dynamic?> vendorKitchenEditUpload(
      {required Map<String, dynamic> data,
      required List<String> filePaths}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/mikitchn/editkitchen';

      print(url);
      print(data['name']);

      //for multipartrequest
      var request = http.MultipartRequest('POST', Uri.parse(url));

      //for token
      request.headers
          .addAll({"Authorization": "Bearer ${user!.data!.accessToken}"});

      //for image and videos and files

      if (filePaths.isNotEmpty) {
        filePaths.forEach((element) async {
          request.files
              .add(await http.MultipartFile.fromPath("images[]", "${element}"));
        });
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
}
