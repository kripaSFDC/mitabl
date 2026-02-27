import 'dart:convert';

class NearByRestaurantsResponse {
  int? status;
  bool? isSuccess;
  String? message;
  Data? data;

  NearByRestaurantsResponse(
      {this.status, this.isSuccess, this.message, this.data});

  NearByRestaurantsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? totalCount;
  List<NearByRestaurantsList>? nearByRestaurantsList;

  Data({this.totalCount, this.nearByRestaurantsList});

  Data.fromJson(Map<String, dynamic> json) {
    totalCount = json['total_count'];
    if (json['kitchens'] != null) {
      nearByRestaurantsList = <NearByRestaurantsList>[];
      json['kitchens'].forEach((v) {
        nearByRestaurantsList!.add(new NearByRestaurantsList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_count'] = this.totalCount;
    if (this.nearByRestaurantsList != null) {
      data['kitchens'] =
          this.nearByRestaurantsList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NearByRestaurantsList {
  int? id;
  int? userId;
  String? name;
  String? address;
  String? phone;
  int? noOfSeats;
  String? timings;
  List<Images>? images;
  List<Images>? addedimage;
  int? dineIn;
  int? takeAway;
  dynamic? description;
  String? abn;
  String? certificateNo;
  dynamic? certificateDoc;
  String? status;
  int? available;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;
  double? distance;
  dynamic? ratingCount;

  NearByRestaurantsList(
      {this.id,
      this.userId,
      this.name,
      this.address,
      this.phone,
      this.noOfSeats,
      this.timings,
      this.images,
      this.addedimage,
      this.dineIn,
      this.takeAway,
      this.description,
      this.abn,
      this.certificateNo,
      this.certificateDoc,
      this.status,
      this.available,
      this.latitude,
      this.longitude,
      this.createdAt,
      this.updatedAt,
      this.distance,
      this.ratingCount});

  NearByRestaurantsList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    noOfSeats = json['no_of_seats'];
    timings = json['timings'];
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
    dineIn = json['dine_in'];
    takeAway = json['take_away'];
    description = json['description'];
    abn = json['abn'];
    certificateNo = json['certificate_no'];
    certificateDoc = json['certificate_doc'];
    status = json['status'];
    available = json['available'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    distance = json['distance'];
    ratingCount = json['rating_count'];
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
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    if (this.addedimage != null) {
      data['addedimage'] = this.addedimage!.map((v) => v.toJson()).toList();
    }
    data['dine_in'] = this.dineIn;
    data['take_away'] = this.takeAway;
    data['description'] = this.description;
    data['abn'] = this.abn;
    data['certificate_no'] = this.certificateNo;
    data['certificate_doc'] = this.certificateDoc;
    data['status'] = this.status;
    data['available'] = this.available;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['distance'] = this.distance;
    data['rating_count'] = this.ratingCount;
    return data;
  }
}

class Images {
  int? id;
  int? refId;
  String? modelName;
  String? path;
  String? createdAt;
  String? updatedAt;

  Images(
      {this.id,
      this.refId,
      this.modelName,
      this.path,
      this.createdAt,
      this.updatedAt});

  Images.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    refId = json['ref_id'];
    modelName = json['model_name'];
    path = json['path'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['ref_id'] = this.refId;
    data['model_name'] = this.modelName;
    data['path'] = this.path;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
