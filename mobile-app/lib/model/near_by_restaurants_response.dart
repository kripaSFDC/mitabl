
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
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
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
        nearByRestaurantsList!.add(NearByRestaurantsList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_count'] = totalCount;
    if (nearByRestaurantsList != null) {
      data['kitchens'] =
          nearByRestaurantsList!.map((v) => v.toJson()).toList();
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
  dynamic description;
  String? abn;
  String? certificateNo;
  dynamic certificateDoc;
  String? status;
  int? available;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;
  double? distance;
  dynamic ratingCount;

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
        images!.add(Images.fromJson(v));
      });
    }
    if (json['addedimage'] != null) {
      addedimage = <Images>[];
      json['addedimage'].forEach((v) {
        addedimage!.add(Images.fromJson(v));
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['name'] = name;
    data['address'] = address;
    data['phone'] = phone;
    data['no_of_seats'] = noOfSeats;
    data['timings'] = timings;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (addedimage != null) {
      data['addedimage'] = addedimage!.map((v) => v.toJson()).toList();
    }
    data['dine_in'] = dineIn;
    data['take_away'] = takeAway;
    data['description'] = description;
    data['abn'] = abn;
    data['certificate_no'] = certificateNo;
    data['certificate_doc'] = certificateDoc;
    data['status'] = status;
    data['available'] = available;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['distance'] = distance;
    data['rating_count'] = ratingCount;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ref_id'] = refId;
    data['model_name'] = modelName;
    data['path'] = path;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
