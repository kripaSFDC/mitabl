class CookingStyle {
  int? status;
  bool? isSuccess;
  String? message;
  List<CookingStyleData>? data;

  CookingStyle({this.status, this.isSuccess, this.message, this.data});

  CookingStyle.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      data = <CookingStyleData>[];
      json['data'].forEach((v) {
        data!.add(new CookingStyleData.fromJson(v));
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

class CookingStyleData {
  int? id;
  String? name;
  bool? isSelected=false;

  CookingStyleData copyWith({int? id, String? name, bool? isSelected}) {
    return CookingStyleData(
        name: name ?? this.name,
        id: id ?? this.id,
        isSelected: isSelected ?? this.isSelected);
  }

    CookingStyleData({this.id, this.name, this.isSelected});

  CookingStyleData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}
