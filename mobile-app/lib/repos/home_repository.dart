import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class HomeRepository {

  Future<dynamic?> recommendedRestaurants({required Map<String, dynamic> data,required UserModel? userModel}) async {
    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}v1/recommendedrestaurant';

    var headers = {
      'Authorization': 'Bearer ${userModel!.data!.accessToken}',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(data);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var responsed = await http.Response.fromStream(response);
    // if (response.statusCode == 200) {
    //   print(json.decode(responsed.body));
    // }
    return responsed;
  }

  Future<dynamic?> topRatedRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) async {
    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}v1/topRatedRestaurant?page=1&limit=20';

    var headers = {
      'Authorization': 'Bearer ${userModel!.data!.accessToken}',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(data);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var responsed = await http.Response.fromStream(response);
    if (response.statusCode == 200) {
      print(json.decode(responsed.body));
    }
    return responsed;
  }

  Future<dynamic?> nearByRestaurants(
      {required Map<String, dynamic> data,
      required UserModel? userModel}) async {
    final url =
        '${GlobalConfiguration().getValue<String>('api_base_url')}v1/nearestRestaurant?page=1&limit=20';

    var headers = {
      'Authorization': 'Bearer ${userModel!.data!.accessToken}',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(data);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var responsed = await http.Response.fromStream(response);
    if (response.statusCode == 200) {
      print('SunnyRes ${json.decode(responsed.body)}');
    }
    return responsed;
  }
}
