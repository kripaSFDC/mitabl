import 'package:mitabl_user/model/near_by_restaurants_response.dart';

class RecommendedRestResponse {
  int? status;
  bool? isSuccess;
  String? message;
  List<RecommendedResturant>? recommendedResturantList;

  RecommendedRestResponse(
      {this.status,
      this.isSuccess,
      this.message,
      this.recommendedResturantList});

  RecommendedRestResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    final normalizedList = _extractRecommendedList(json['data']);
    if (normalizedList.isNotEmpty) {
      recommendedResturantList = normalizedList
          .whereType<Map<String, dynamic>>()
          .map(RecommendedResturant.fromJson)
          .toList();
    }
  }

  List<dynamic> _extractRecommendedList(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      const candidateKeys = [
        'kitchens',
        'recommended_resturant_list',
        'recommended_restaurant_list',
        'recommendedResturantList',
        'recommendedRestaurantList',
        'data',
      ];

      for (final key in candidateKeys) {
        final candidate = rawData[key];
        if (candidate is List) {
          return candidate;
        }
      }
    }

    return const [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (recommendedResturantList != null) {
      data['data'] = recommendedResturantList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RecommendedResturant {
  int? id;
  int? userId;
  String? name;
  String? address;
  String? phone;
  int? noOfSeats;
  String? timings;
  int? dineIn;
  int? takeAway;
  String? description;
  String? status;
  int? available;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;
  double? ratingCount;
  int? ordersCount;
  List<Images>? images;
  List<Images>? addedimage;

  RecommendedResturant(
      {this.id,
      this.userId,
      this.name,
      this.address,
      this.phone,
      this.noOfSeats,
      this.timings,
      this.dineIn,
      this.takeAway,
      this.description,
      this.status,
      this.available,
      this.latitude,
      this.longitude,
      this.createdAt,
      this.updatedAt,
      this.ratingCount,
      this.ordersCount,
      this.images,
      this.addedimage});

  RecommendedResturant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    noOfSeats = json['no_of_seats'];
    timings = json['timings'];
    dineIn = json['dine_in'];
    takeAway = json['take_away'];
    description = json['description'];
    status = json['status'];
    available = json['available'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    ratingCount = json['rating_count'];
    ordersCount = json['orders_count'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(Images.fromJson(v));
      });
    }
    if (json['addedimage'] != null) {
      addedimage = <Images>[];
      json['addedimage'].forEach((v) {
        addedimage!.add(Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['name'] = name;
    data['address'] = address;
    data['phone'] = phone;
    data['no_of_seats'] = noOfSeats;
    data['timings'] = timings;
    data['dine_in'] = dineIn;
    data['take_away'] = takeAway;
    data['description'] = description;
    data['status'] = status;
    data['available'] = available;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['rating_count'] = ratingCount;
    data['orders_count'] = ordersCount;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (addedimage != null) {
      data['addedimage'] = addedimage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
