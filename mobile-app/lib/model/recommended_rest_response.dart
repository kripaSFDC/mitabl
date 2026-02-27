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
    if (json['data'] != null) {
      recommendedResturantList = <RecommendedResturant>[];
      json['data'].forEach((v) {
        recommendedResturantList!.add(new RecommendedResturant.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.recommendedResturantList != null) {
      data['data'] =
          this.recommendedResturantList!.map((v) => v.toJson()).toList();
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
        images!.add(new Images.fromJson(v));
      });
    }
    if (json['addedimage'] != null) {
      addedimage = <Images>[];
      json['addedimage'].forEach((v) {
        addedimage!.add(new Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['name'] = this.name;
    data['address'] = this.address;
    data['phone'] = this.phone;
    data['no_of_seats'] = this.noOfSeats;
    data['timings'] = this.timings;
    data['dine_in'] = this.dineIn;
    data['take_away'] = this.takeAway;
    data['description'] = this.description;
    data['status'] = this.status;
    data['available'] = this.available;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['rating_count'] = this.ratingCount;
    data['orders_count'] = this.ordersCount;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    if (this.addedimage != null) {
      data['addedimage'] = this.addedimage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
