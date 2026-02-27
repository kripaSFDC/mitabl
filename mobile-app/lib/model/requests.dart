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
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
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
        ? new Mikitchn.fromJson(json['mikitchn'])
        : null;
    customer = json['customer'] != null
        ? new Customer.fromJson(json['customer'])
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
        items!.add(new Items.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_id'] = this.orderId;
    if (this.mikitchn != null) {
      data['mikitchn'] = this.mikitchn!.toJson();
    }
    if (this.customer != null) {
      data['customer'] = this.customer!.toJson();
    }
    data['date'] = this.date;
    data['time_from'] = this.timeFrom;
    data['time_to'] = this.timeTo;
    data['created_at'] = this.createdAt;
    data['persons'] = this.persons;
    data['dine_in'] = this.dineIn;
    data['take_away'] = this.takeAway;
    data['item_total_price'] = this.itemTotalPrice;
    data['promo_code'] = this.promoCode;
    data['taxes'] = this.taxes;
    data['status'] = this.status;
    data['paid'] = this.paid;
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['address'] = this.address;
    data['rating'] = this.rating;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['avatar'] = this.avatar;
    data['rating'] = this.rating;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['food'] = this.food;
    data['quantity'] = this.quantity;
    data['price'] = this.price;
    return data;
  }
}

