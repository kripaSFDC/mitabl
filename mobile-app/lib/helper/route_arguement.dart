import 'package:mitabl_user/model/bookings.dart';
import 'package:mitabl_user/model/food_menu.dart';

import '../model/get_profile_model.dart';

class RouteArguments {
  int? from;
  String? id;
  int? role;
  dynamic? data;
  Kitchen? kitchen;
  FoodData? foodData;
  bool? isEdit;
  Customer? customer;
  Bookings? bookings;
  bool? isUpcoming;

  RouteArguments(
      {this.bookings,
      this.isUpcoming,
      this.customer,
      this.foodData,
      this.isEdit,
      this.from,
      this.id,
      this.role,
      this.data,
      this.kitchen});
}
