class UserModel {
  int? responseCode;
  bool? isSuccess;
  String? message;
  Data? data;

  UserModel({this.responseCode, this.isSuccess, this.message, this.data});

  UserModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'] != null ? json['response_code'] : 0;
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['response_code'] = this.responseCode;
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? accessToken;
  String? tokenType;
  User? user;

  Data({this.accessToken, this.tokenType, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'] != null ? json['token_type'] : '';
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['access_token'] = this.accessToken;
    data['token_type'] = this.tokenType;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? role;

  User({this.id, this.name, this.role});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['role'] = this.role;
    return data;
  }
}
