import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/pages/login/cubit/login_cubit.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/route_generator.dart';

import 'auth_bloc/authentication/authentication_bloc.dart';
import 'helper/app_config.dart' as config;
import 'helper/appconstants.dart';

class App extends StatelessWidget {
  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;

  const App(
      {Key? key,
      required this.authenticationRepository,
      required this.userRepository})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => authenticationRepository),
        RepositoryProvider(create: (context) => userRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthenticationBloc(
              authenticationRepository: authenticationRepository,
              userRepository: userRepository,
            ),
          ),
          BlocProvider(
            create: (_) => LoginCubit(
              authenticationRepository: authenticationRepository,
              userRepository: userRepository,
            ),
          ),
          BlocProvider(
            create: (_) => DashboardCookCubit(
              userRepository: userRepository,
              authenticationRepository: authenticationRepository,
            ),
          ),
          BlocProvider(
            create: (_) => ProfileCookCubit(
              userRepository: userRepository,
            ),
          ),
          BlocProvider(
            create: (_) => ProfileFoodieCubit(
                userRepository: userRepository,
                authenticationRepository: authenticationRepository),
          ),
          BlocProvider(
            create: (_) => AddMenuCubit(
              CookRepository(userRepository),
            ),
          ),
        ],
        child: AppView(
          userRepository: userRepository,
        ),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  AppView({this.userRepository});

  final UserRepository? userRepository;

  @override
  _AppViewState createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  // final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigator => navigatorKey.currentState;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return BlocListener<AuthenticationBloc, AuthenticationState>(
            listener: (context, state) async {
              print('checkStatus ${state.status}');
              switch (state.status) {
                case AuthenticationStatus.authenticated:
                  state.user!.data!.user!.role ==
                          AppConstants.IS_COOK.toString()
                      ? _navigator!.pushNamedAndRemoveUntil(
                          '/DashboardCook', (route) => false)
                      : _navigator!.pushNamedAndRemoveUntil(
                          '/HomePage', (route) => false);
                  break;

                case AuthenticationStatus.unauthenticated:
                  print('app:-unauthenticated');

                  _navigator!.pushNamedAndRemoveUntil(
                      '/LandingPage', (route) => false);

                  break;
                default:
                  break;
              }
            },
            child: child,
          );
        },
        initialRoute: '/Splash',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RouteGenerator.generateRoute,
        theme: ThemeData(
          // fontFamily: 'Poppins',
          fontFamily: config.FontFamily().itcAvantGardeGothicStdFontFamily,
          primaryColor: config.AppColors().colorPrimary(1),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0, foregroundColor: Colors.white),
          brightness: Brightness.light,
          accentColor: config.AppColors().accentColor(1),
          dividerColor: config.AppColors().accentColor(0.1),
          focusColor: config.AppColors().secondColor(1),
          hintColor: config.AppColors().hintTextBackgroundColor(1),
          scaffoldBackgroundColor: config.AppColors().scaffoldColor(1),
          primaryColorLight: config.AppColors().colorPrimaryLight(1),
          primaryColorDark: config.AppColors().colorPrimaryDark(1),
          errorColor: Colors.red,
          backgroundColor: Colors.grey.shade200,
          textTheme: TextTheme(
              headline5: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 24,
                  fontWeight: config.FontFamily().medium),
              headline6: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  fontWeight: config.FontFamily().book),
              bodyText1: TextStyle(
                  color: config.AppColors().colorPrimary(1),
                  fontSize: 18,
                  fontWeight: config.FontFamily().medium),
              subtitle1: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 14,
                  fontWeight: config.FontFamily().demi),
              subtitle2: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 12,
                  fontWeight: config.FontFamily().book)),
        ));
  }
}
