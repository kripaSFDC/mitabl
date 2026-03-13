class GetCookProfileModel {
  int? status;
  bool? isSuccess;
  String? message;
  Data? data;

  GetCookProfileModel({this.status, this.isSuccess, this.message, this.data});

  GetCookProfileModel.fromJson(Map<String, dynamic> json) {
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
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  int? emailVerified;
  int? roleId;
  String? avatar;
  String? description;
  dynamic phone;
  String? address;
  String? role;
  Kitchen? kitchen;

  Data(
      {this.id,
      this.firstName,
      this.lastName,
      this.email,
      this.emailVerified,
      this.roleId,
      this.avatar,
      this.description,
      this.phone,
      this.address,
      this.role,
      this.kitchen});

  Data.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    emailVerified = _asInt(json['email_verified']);
    roleId = _asInt(json['role_id']);
    avatar = json['avatar'];
    description = json['description'];
    phone = json['phone'];
    address = json['address'];
    role = json['role'];
    kitchen =
        json['kitchen'] != null ? Kitchen.fromJson(json['kitchen']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['email_verified'] = emailVerified;
    data['role_id'] = roleId;
    data['avatar'] = avatar;
    data['description'] = description;
    data['phone'] = phone;
    data['address'] = address;
    data['role'] = role;
    if (kitchen != null) {
      data['kitchen'] = kitchen!.toJson();
    }
    return data;
  }
}

class Kitchen {
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
  String? abn;
  String? certificateNo;
  dynamic certificateDoc;
  String? status;
  int? available;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;
  List<ReviewsData>? reviewsData;
  double? ratingCount;
  List<ImagesCook>? images;

  Kitchen(
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
      this.abn,
      this.certificateNo,
      this.certificateDoc,
      this.status,
      this.available,
      this.latitude,
      this.longitude,
      this.createdAt,
      this.updatedAt,
      this.reviewsData,
      this.ratingCount,
      this.images});

  Kitchen.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    userId = _asInt(json['user_id']);
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    noOfSeats = _asInt(json['no_of_seats']);
    timings = json['timings'];
    dineIn = _asInt(json['dine_in']);
    takeAway = _asInt(json['take_away']);
    description = json['description'];
    abn = json['abn'];
    certificateNo = json['certificate_no'];
    certificateDoc = json['certificate_doc'];
    status = json['status'];
    available = _asInt(json['available']);
    latitude = _asDouble(json['latitude']);
    longitude = _asDouble(json['longitude']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['reviewsData'] != null) {
      reviewsData = <ReviewsData>[];
      json['reviewsData'].forEach((v) {
        reviewsData!.add(ReviewsData.fromJson(v));
      });
    }
    ratingCount = _asDouble(json['rating_count']);
    if (json['images'] != null) {
      images = <ImagesCook>[];
      json['images'].forEach((v) {
        images!.add(ImagesCook.fromJson(v));
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
    data['abn'] = abn;
    data['certificate_no'] = certificateNo;
    data['certificate_doc'] = certificateDoc;
    data['status'] = status;
    data['available'] = available;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (reviewsData != null) {
      data['reviewsData'] = reviewsData!.map((v) => v.toJson()).toList();
    }
    data['rating_count'] = ratingCount;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ReviewsData {
  int? id;
  double? rating;
  String? review;
  String? reviewTag;
  User? user;

  ReviewsData({this.id, this.rating, this.review, this.reviewTag, this.user});

  ReviewsData.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    rating = _asDouble(json['rating']) ?? 0.0;
    review = json['review'];
    reviewTag = json['review_tag'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['rating'] = rating;
    data['review'] = review;
    data['review_tag'] = reviewTag;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? avatar;

  User({this.id, this.name, this.avatar});

  User.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    name = json['name'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['avatar'] = avatar;
    return data;
  }
}

class ImagesCook {
  int? id;
  int? refId;
  String? modelName;
  String? path;
  String? createdAt;
  String? updatedAt;

  ImagesCook(
      {this.id,
      this.refId,
      this.modelName,
      this.path,
      this.createdAt,
      this.updatedAt});

  ImagesCook.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    refId = _asInt(json['ref_id']);
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

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is bool) return value ? 1 : 0;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is bool) return value ? 1.0 : 0.0;
  if (value is String) return double.tryParse(value);
  return null;
}
