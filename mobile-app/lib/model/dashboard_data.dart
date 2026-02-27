class DashboardData {
  int? status;
  bool? isSuccess;
  String? message;
  Data? data;

  DashboardData({this.status, this.isSuccess, this.message, this.data});

  DashboardData.fromJson(Map<String, dynamic> json) {
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
  int? totalEarning;
  int? nBookings;
  int? nUpcomingBookings;

  Data({this.totalEarning, this.nBookings, this.nUpcomingBookings});

  Data.fromJson(Map<String, dynamic> json) {
    totalEarning = json['total_earning'];
    nBookings = json['n_bookings'];
    nUpcomingBookings = json['n_upcoming_bookings'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_earning'] = this.totalEarning;
    data['n_bookings'] = this.nBookings;
    data['n_upcoming_bookings'] = this.nUpcomingBookings;
    return data;
  }
}

