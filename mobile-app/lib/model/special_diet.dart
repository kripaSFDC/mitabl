class SpecialDiet {
  int? status;
  bool? isSuccess;
  String? message;
  List<SpecialDietData>? data;

  SpecialDiet({this.status, this.isSuccess, this.message, this.data});

  SpecialDiet.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SpecialDietData>[];
      json['data'].forEach((v) {
        data!.add(new SpecialDietData.fromJson(v));
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

class SpecialDietData {
  int? id;
  String? name;
  bool? isSelected=false;

  SpecialDietData({this.id, this.name, this.isSelected});

  SpecialDietData copyWith({
    int? id,
    String? name,
    bool? isSelected,
  }) {
    return SpecialDietData(
        id: id ?? this.id,
        name: name ?? this.name,
        isSelected: isSelected ?? this.isSelected);
  }

  SpecialDietData.fromJson(Map<String, dynamic> json) {
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
