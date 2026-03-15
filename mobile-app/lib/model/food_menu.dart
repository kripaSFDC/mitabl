class FoodMenu {
  int? status;
  bool? isSuccess;
  String? message;
  List<FoodData>? foodData;

  FoodMenu({this.status, this.isSuccess, this.message, this.foodData});

  FoodMenu.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      foodData = <FoodData>[];
      json['data'].forEach((v) {
        foodData!.add(FoodData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (foodData != null) {
      data['data'] = foodData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FoodData {
  int? id;
  int? restaurantId;
  String? specialDiet;
  int? cookingstyle;
  String? foodName;
  List<Pictures>? pictures;
  double? price;
  int? status;
  String? description;
  String? availableDate;
  List<int>? availableDays;
  String? availableFromTime;
  String? availableToTime;

  FoodData copyWith({
    int? id,
    int? restaurantId,
    String? specialDiet,
    int? cookingstyle,
    String? foodName,
    List<Pictures>? pictures,
    double? price,
    int? status,
    String? description,
    String? availableDate,
    List<int>? availableDays,
    String? availableFromTime,
    String? availableToTime,
  }) {
    return FoodData(
        id: id ?? this.id,
        price: price ?? this.price,
        description: description ?? this.description,
        status: status ?? this.status,
        cookingstyle: cookingstyle ?? this.cookingstyle,
        foodName: foodName ?? this.foodName,
        pictures: pictures ?? this.pictures,
        restaurantId: restaurantId ?? this.restaurantId,
        specialDiet: specialDiet ?? this.specialDiet,
        availableDate: availableDate ?? this.availableDate,
        availableDays: availableDays ?? this.availableDays,
        availableFromTime: availableFromTime ?? this.availableFromTime,
        availableToTime: availableToTime ?? this.availableToTime);
  }

  FoodData(
      {this.id,
      this.restaurantId,
      this.specialDiet,
      this.cookingstyle,
      this.foodName,
      this.pictures,
      this.price,
      this.status,
      this.description,
      this.availableDate,
      this.availableDays,
      this.availableFromTime,
      this.availableToTime});

  FoodData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    restaurantId = json['restaurant_id'];
    specialDiet = json['specialDiet'];
    cookingstyle = json['cookingstyle'];
    foodName = json['food_name'];
    if (json['pictures'] != null) {
      pictures = <Pictures>[];
      json['pictures'].forEach((v) {
        pictures!.add(Pictures.fromJson(v));
      });
    }
    price =
        json['price'] != null ? double.parse(json['price'].toString()) : 0.0;
    status = json['status'];
    description = json['description'];
    availableDate = json['available_date']?.toString();
    availableDays = _parseAvailableDays(json['available_days']);
    availableFromTime = json['available_from_time']?.toString();
    availableToTime = json['available_to_time']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['restaurant_id'] = restaurantId;
    data['specialDiet'] = specialDiet;
    data['cookingstyle'] = cookingstyle;
    data['food_name'] = foodName;
    if (pictures != null) {
      data['pictures'] = pictures!.map((v) => v.toJson()).toList();
    }
    data['price'] = price;
    data['status'] = status;
    data['description'] = description;
    data['available_date'] = availableDate;
    data['available_days'] = availableDays;
    data['available_from_time'] = availableFromTime;
    data['available_to_time'] = availableToTime;
    return data;
  }
}

List<int>? _parseAvailableDays(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is List) {
    return value
        .map((day) => int.tryParse(day.toString()))
        .whereType<int>()
        .toList(growable: false);
  }

  return null;
}

class Pictures {
  int? id;
  int? refId;
  String? modelName;
  String? path;
  String? createdAt;
  String? updatedAt;

  Pictures(
      {this.id,
      this.refId,
      this.modelName,
      this.path,
      this.createdAt,
      this.updatedAt});

  Pictures.fromJson(Map<String, dynamic> json) {
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
