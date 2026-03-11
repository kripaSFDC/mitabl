class Requests {
  int? status;
  bool? isSuccess;
  String? message;
  List<Data>? data;

  Requests({this.status, this.isSuccess, this.message, this.data});

  Requests.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? orderId;
  Mikitchn? mikitchn;
  Customer? customer;
  String? date;
  String? timeFrom;
  String? timeTo;
  String? createdAt;
  int? persons;
  int? dineIn;
  int? takeAway;
  double? itemTotalPrice;
  int? promoCode;
  int? taxes;
  int? status;
  int? paid;
  List<Items>? items;

  Data(
      {this.orderId,
        this.mikitchn,
        this.customer,
        this.date,
        this.timeFrom,
        this.timeTo,
        this.createdAt,
        this.persons,
        this.dineIn,
        this.takeAway,
        this.itemTotalPrice,
        this.promoCode,
        this.taxes,
        this.status,
        this.paid,
        this.items});

  Data.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    mikitchn = json['mikitchn'] != null
        ? Mikitchn.fromJson(json['mikitchn'])
        : null;
    customer = json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : null;
    date = json['date'];
    timeFrom = json['time_from'];
    timeTo = json['time_to'];
    createdAt = json['created_at'];
    persons = json['persons'];
    dineIn = json['dine_in'];
    takeAway = json['take_away'];
    itemTotalPrice = json['item_total_price'];
    promoCode = json['promo_code'];
    taxes = json['taxes'];
    status = json['status'];
    paid = json['paid'];
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    if (mikitchn != null) {
      data['mikitchn'] = mikitchn!.toJson();
    }
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    data['date'] = date;
    data['time_from'] = timeFrom;
    data['time_to'] = timeTo;
    data['created_at'] = createdAt;
    data['persons'] = persons;
    data['dine_in'] = dineIn;
    data['take_away'] = takeAway;
    data['item_total_price'] = itemTotalPrice;
    data['promo_code'] = promoCode;
    data['taxes'] = taxes;
    data['status'] = status;
    data['paid'] = paid;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Mikitchn {
  int? id;
  String? name;
  String? address;
  double? rating;

  Mikitchn({this.id, this.name, this.address, this.rating});

  Mikitchn.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['address'] = address;
    data['rating'] = rating;
    return data;
  }
}

class Customer {
  int? id;
  String? name;
  int? phone;
  String? avatar;
  double? rating;

  Customer({this.id, this.name, this.phone, this.avatar, this.rating});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    avatar = json['avatar'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['avatar'] = avatar;
    data['rating'] = rating;
    return data;
  }
}

class Items {
  String? food;
  int? quantity;
  double? price;

  Items({this.food, this.quantity, this.price});

  Items.fromJson(Map<String, dynamic> json) {
    food = json['food'];
    quantity = json['quantity'];
    price = json['price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['food'] = food;
    data['quantity'] = quantity;
    data['price'] = price;
    return data;
  }
}

