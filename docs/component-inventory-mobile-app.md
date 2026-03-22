# mitabl Mobile App — Component Inventory

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** mobile-app

---

## Navigation Components

| Component | Location | Description |
|-----------|----------|------------|
| DashBoardCookPage | pages_cook/dashboard_cook/ | Bottom navigation hub (5 tabs: Home, Requests, Menu, Bookings, Profile) |
| RouteGenerator | route_generator.dart | Named route definitions (25 routes) with argument validation |

---

## Authentication Components

| Component | Location | Description |
|-----------|----------|------------|
| SplashPage | splash.dart | Logo + update check + auth state routing |
| LandingPage | pages/landing_page/ | Login/signup entry with T&C links |
| LoginPage + LoginForm | pages/login/ | Email/password form with visibility toggle |
| SignupPage + SignupForm | pages/signup/ | Registration form with role selection (Foodie/Cook) |
| OTPPage | pages/otp/ | 4-digit Pinput widget for OTP verification |
| ForgotPage | pages/forgot/ | Email input for password reset |
| BiometricLockPage | pages/common/view/ | Full-screen biometric lock on app resume |

---

## Discovery / Foodie Components

| Component | Location | Description |
|-----------|----------|------------|
| HomePage | pages/home/ | Main discovery feed with location, filters, 3 restaurant lists |
| RecommendedRestWidget | pages/home/element/ | Horizontal carousel of recommended restaurants |
| TopRatedWidget | pages/home/element/ | Horizontal scrollable top-rated list |
| NearByRestaurants | pages/home/element/ | Vertical infinite-scroll nearby list |
| NearByWidget | pages/home/element/ | Individual nearby restaurant card |
| FilterDialog | pages/home/element/ | Cooking style, dine-in/take-away, distance slider filters |
| ProfileFoodiePage | pages/profile_foodie/ | Profile with menu items (role switch, orders, favorites, etc.) |
| EditProfileFoodiePage | pages/edit_profile_foodie/ | Avatar + personal info editing form |

---

## Cook Components

| Component | Location | Description |
|-----------|----------|------------|
| HomeCookPage | pages_cook/home_page/ | Dashboard stats + quick action cards |
| ProfileCookPage | pages_cook/profile_cook/ | TabBarView: Personal + MiKitchn tabs |
| EditProfileCookPage | pages_cook/edit_profile_cook/ | Cook personal info editing |
| EditKitchenProfilePage | pages_cook/edit_kitchen_profile/ | Kitchen details, images, timings editor |
| MenuPage | pages_cook/menu/ | Food item list with status toggles |
| AddMenuPage | pages_cook/add_menu_item/ | Food add/edit form with cooking style + special diet dialogs |
| MenuDetails | pages_cook/menu_detail/ | Read-only food detail with image carousel |
| BookingsPage | pages_cook/bookings/ | Paginated bookings with filter (status, sort) |
| UpcomingBookings | pages_cook/upcoming_bookings/ | Filtered upcoming orders |
| RequestsPage | pages_cook/requests/ | Incoming order requests with accept/reject |
| CustomerReviewPage | pages_cook/customer_reviews/ | Kitchen reviews display |
| SettingsCookPage | pages_cook/settings_page/ | Settings: role switch, delete account, notifications, biometric |
| UserDetails | pages_cook/user_details_page/ | Customer detail card |
| CookProfilePage | pages/profile_signup_cook/ | Cook onboarding: kitchen images, address, timings |

---

## Shared / Reusable Components

| Component | Location | Description |
|-----------|----------|------------|
| CommonAppBar | pages/common/view/ | Reusable app bar with back button + optional filter icon |
| CommonProgressWidget | pages/common/view/ | Full-screen Cupertino loading overlay |
| NoDataWidget | pages/common/view/ | SVG illustration + "No data found" text |
| StarRating | pages/common/view/ | Read-only star rating (full/half/empty stars) |
| CustomShapeCook | helper/ | Custom painter for curved background shape |
| SemanticButton | helper/ | Accessibility-aware tap target wrapper |
| SemanticImage | helper/ | Accessibility-aware image with decorative option |
| OfflineErrorWidget | pages/common/view/ | Wi-fi icon + message + retry button |
| ConnectivityBanner | pages/common/view/ | Animated slide-in red banner for offline state |
| UpdateGateWidget | pages/common/view/ | Required/optional app update modal |
| FaqWebviewPage | pages/common/view/ | WebView for FAQ (restricted to mitabl.com) |

---

## Dialog Components

| Component | Location | Description |
|-----------|----------|------------|
| FilterDialog | pages/home/element/ | Discovery filters |
| CookingStyleDialog | pages_cook/add_menu_item/elements/ | Radio-button cooking style selector |
| SpecialDietDialog | pages_cook/add_menu_item/elements/ | Checkbox special diet selector |
| BookingFilterDialog | pages_cook/bookings/elements/ | Status + sort filter for bookings |
| AcceptRejectDialog | pages_cook/requests/elements/ | Order accept/reject confirmation |
| TimingDialog | pages/profile_signup_cook/ | Per-day timing editor with time pickers |

---

## Cubit/BLoC Components (State Management)

| Cubit | Location | Managed State |
|-------|----------|--------------|
| AuthenticationBloc | auth_bloc/authentication/ | Global auth state (authenticated/unauthenticated) |
| LoginCubit | pages/login/cubit/ | Login form + API status |
| SignUpCubit | pages/signup/cubit/ | Registration form + API status |
| OtpCubit | pages/otp/cubit/ | OTP form + verification status |
| ForgotCubit | pages/forgot/cubit/ | Password reset form + API status |
| HomeCubit | pages/home/cubit/ | Discovery feeds, location, filters, pagination, caching |
| ProfileFoodieCubit | pages/profile_foodie/cubit/ | Foodie profile data + logout |
| DashboardCookCubit | pages_cook/dashboard_cook/cubit/ | Dashboard stats |
| ProfileCookCubit | pages_cook/profile_cook/cubit/ | Cook profile data |
| EditProfileCookCubit | pages_cook/edit_profile_cook/cubit/ | Profile edit form |
| EditKitchenProfileCubit | pages_cook/edit_kitchen_profile/cubit/ | Kitchen edit form |
| MenuCubit | pages_cook/menu/cubit/ | Menu list + food status toggle |
| AddMenuCubit | pages_cook/add_menu_item/cubit/ | Add/edit food form |
| BookingsCubit | pages_cook/bookings/cubit/ | Bookings list + order status updates |
| RequestsCubit | pages_cook/requests/cubit/ | Order requests + accept/reject |
| SettingsCookCubit | pages_cook/settings_page/cubit/ | Settings + role switch + account deletion |
| CookProfileCubit | pages/profile_signup_cook/ | Cook onboarding form |
| SpecialDietCubit | pages_cook/add_menu_item/cubit/ | Special diet checkbox state |
