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
        foodData!.add(new FoodData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.foodData != null) {
      data['data'] = this.foodData!.map((v) => v.toJson()).toList();
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
        specialDiet: specialDiet ?? this.specialDiet);
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
      this.description});

  FoodData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    restaurantId = json['restaurant_id'];
    specialDiet = json['specialDiet'];
    cookingstyle = json['cookingstyle'];
    foodName = json['food_name'];
    if (json['pictures'] != null) {
      pictures = <Pictures>[];
      json['pictures'].forEach((v) {
        pictures!.add(new Pictures.fromJson(v));
      });
    }
    price =
        json['price'] != null ? double.parse(json['price'].toString()) : 0.0;
    status = json['status'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['restaurant_id'] = this.restaurantId;
    data['specialDiet'] = this.specialDiet;
    data['cookingstyle'] = this.cookingstyle;
    data['food_name'] = this.foodName;
    if (this.pictures != null) {
      data['pictures'] = this.pictures!.map((v) => v.toJson()).toList();
    }
    data['price'] = this.price;
    data['status'] = this.status;
    data['description'] = this.description;
    return data;
  }
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
