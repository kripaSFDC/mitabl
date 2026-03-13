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
  static Route<dynamic> _routeError([String message = 'Route Error']) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(body: SafeArea(child: Text(message))),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    final routeArguments = args is RouteArguments ? args : null;
    switch (settings.name) {
      case '/Splash':
        return MaterialPageRoute<void>(builder: (_) => const SplashPage());

      case '/LandingPage':
        return const LandingPage().route();

      case '/LoginPage':
        return LoginPage.route();

      case '/SignUpPage':
        return SignupPage.route();

      case '/ForgotPage':
        return ForgotPage.route();

      case '/OTPPage':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /OTPPage');
        }
        return OTPPage.route(routeArguments: routeArguments);

      case '/HomePage':
        return HomePage.route();

      case '/CookProfile':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /CookProfile');
        }
        return CookProfilePage.route(routeArguments: routeArguments);

      case '/SettingsCook':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /SettingsCook');
        }
        return SettingsCookPage.route(routeArguments: routeArguments);

      case '/ProfileCook':
        return EditProfileCookPage.route();

      case '/EditProfileFoodie':
        return EditProfileFoodiePage.route();

      case '/ProfileFoodie':
        return ProfileFoodiePage.route();

      case '/DashboardCook':
        return DashBoardCookPage.route();

      case '/EditKitchenProfile':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /EditKitchenProfile');
        }
        return EditKitchenProfilePage.route(routeArguments: routeArguments);

      case '/CustomerReviewPage':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /CustomerReviewPage');
        }
        return CustomerReviewPage.route(routeArguments: routeArguments);

      case '/AddMenuPage':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /AddMenuPage');
        }
        return AddMenuPage.route(routeArguments: routeArguments);

      case '/Bookings':
        return Bookings.route();

      case '/UpcomingBookings':
        return UpcomingBookings.route();

      case '/MenuDetails':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /MenuDetails');
        }
        return MenuDetails.route(routeArguments: routeArguments);

      case '/UserDetails':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /UserDetails');
        }
        return UserDetails.route(routeArguments: routeArguments);

      case '/OrderDetails':
        if (routeArguments == null) {
          return _routeError('Missing route arguments for /OrderDetails');
        }
        if (routeArguments.bookings == null) {
          return Bookings.route();
        }
        return OrderDetails.route(routeArguments: routeArguments);

      default:
        return _routeError();
    }
  }
}
