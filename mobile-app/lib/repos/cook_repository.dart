import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:global_configuration/global_configuration.dart';
import 'dart:async';
import 'dart:convert';

class CookRepository {
  final UserRepository? userRepository;

  CookRepository(this.userRepository);

  Future<dynamic?> getFoodMenu() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/mymenu';

      print(url);
      print(userRepository!.user!.data!.accessToken);
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

  Future<dynamic?> getSpecialDiets() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getspecialdiets';

      print(url);
      print(userRepository!.user!.data!.accessToken);
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

  Future<dynamic?> getCookingStyle() async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/getcookingstyles';

      print(url);
      print(userRepository!.user!.data!.accessToken);
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

  Future<dynamic?> saveMenuItem(
      {required Map<String, dynamic> data,
      required List<String> filePaths,
      bool? isEdit,
      List<String>? deleteImagsId = const []}) async {
    try {
      var urlSet = isEdit! ? 'editfood' : "add";
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/food/$urlSet';

      print(url);
      print(data['name']);

      //for multipartrequest
      var request = http.MultipartRequest('POST', Uri.parse(url));

      //for token
      request.headers.addAll({
        "Authorization": "Bearer ${userRepository!.user!.data!.accessToken}"
      });

      //for image and videos and files

      if (filePaths.isNotEmpty) {
        filePaths.forEach((element) async {
          request.files.add(
              await http.MultipartFile.fromPath("pictures[]", "${element}"));
        });
      }

      request.fields.addAll({
        'food_name': '${data['food_name']}',
        'price': '${data['price']}',
        'cookingstyle': '${data['cookingstyle']}',
        'specialDiet[]': data['specialDiet[]'],
        'delete_images': data['delete_images'],
        'description': '${data['description']}',
      });

      if (isEdit) {
        request.fields.addAll({'food_id': '${data['food_id']}'});
        // print('deleteImagsId ${deleteImagsId}');
        // if (deleteImagsId!.isNotEmpty) {
        //   deleteImagsId.forEach((element) async {
        //     map['delete_images[]'] = element.toString();
        //   });
        //
        //   request.fields.addAll(map);
        // }
      } else {
        request.fields.addAll({'restaurant_id': '${data['restaurant_id']}'});
      }
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

  Future<dynamic?> changFoodStatus({String? foodId}) async {
    try {
      final url =
          '${GlobalConfiguration().getValue<String>('api_base_url')}v1/food/status/$foodId';

      print(url);
      print(userRepository!.user!.data!.accessToken);
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
