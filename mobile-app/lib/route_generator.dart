import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/edit_profile_foodie/view/edit_profile_foodie_page.dart';
import 'package:mitabl_user/pages/forgot/view/forgot_page.dart';
import 'package:mitabl_user/pages/home/view/home_page.dart';
import 'package:mitabl_user/pages/landing_page/landing_page.dart';
import 'package:mitabl_user/pages/login/view/login_page.dart';
import 'package:mitabl_user/pages/otp/view/otp_page.dart';
import 'package:mitabl_user/pages/profile_foodie/view/profile_foodie_page.dart';
import 'package:mitabl_user/pages/profile_signup_cook/cook_profile/cook_profile_page.dart';
import 'package:mitabl_user/pages/signup/view/signup_page.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/view/add_menu_page.dart';
import 'package:mitabl_user/pages_cook/bookings/view/bookings_page.dart';
import 'package:mitabl_user/pages_cook/customer_reviews/view/customer_review_page.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/view/dashboard_cook_page.dart';
import 'package:mitabl_user/pages_cook/edit_kitchen_profile/view/edit_kitchen_profile.dart';
import 'package:mitabl_user/pages_cook/edit_profile_cook/view/edit_profile_cook_page.dart';
import 'package:mitabl_user/pages_cook/menu_detail/view/menu_detail.dart';
import 'package:mitabl_user/pages_cook/requests/elements/order_details_view.dart';
import 'package:mitabl_user/pages_cook/settings_page/view/settings_page_cook.dart';
import 'package:mitabl_user/pages_cook/upcoming_bookings/view/upcoming_bookings.dart';
import 'package:mitabl_user/pages_cook/user_details_page/user_details.dart';
import 'package:mitabl_user/splash.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    // print('usrRepo' + args.toString());
    print(settings.name.toString());
    switch (settings.name) {
      case '/Splash':
        return MaterialPageRoute<void>(builder: (_) => SplashPage());

      case '/LandingPage':
        return const LandingPage().route();

      case '/LoginPage':
        return LoginPage.route();

      case '/SignUpPage':
        return SignupPage.route();

      case '/ForgotPage':
        return ForgotPage.route();

      case '/OTPPage':
        return OTPPage.route(routeArguments: args as RouteArguments);

      case '/HomePage':
        return HomePage.route();

      case '/CookProfile':
        return CookProfilePage.route(routeArguments: args as RouteArguments);

      case '/SettingsCook':
        return SettingsCookPage.route(routeArguments: args as RouteArguments);

      case '/ProfileCook':
        return EditProfileCookPage.route();

      case '/EditProfileFoodie':
        return EditProfileFoodiePage.route();

      case '/ProfileFoodie':
        return ProfileFoodiePage.route();

      case '/DashboardCook':
        return DashBoardCookPage.route();

      case '/EditKitchenProfile':
        return EditKitchenProfilePage.route(
            routeArguments: args as RouteArguments);

      case '/CustomerReviewPage':
        return CustomerReviewPage.route(routeArguments: args as RouteArguments);

      case '/AddMenuPage':
        return AddMenuPage.route(routeArguments: args as RouteArguments);

      case '/Bookings':
        return Bookings.route();

      case '/UpcomingBookings':
        return UpcomingBookings.route();

      case '/MenuDetails':
        return MenuDetails.route(routeArguments: args as RouteArguments);

      case '/UserDetails':
        return UserDetails.route(routeArguments: args as RouteArguments);

      case '/OrderDetails':
        return OrderDetails.route(routeArguments: args as RouteArguments);

      default:
        // If there is no such named route in the switch statement, e.g. /third
        return MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: SafeArea(child: Text('Route Error'))));
    }
  }
}
