import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/route_generator.dart';

import 'auth_bloc/authentication/authentication_bloc.dart';
import 'helper/app_config.dart' as config;
import 'helper/app_logger.dart';
import 'helper/appconstants.dart';

class App extends StatelessWidget {
  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;
  final SessionRepository sessionRepository;

  const App(
      {super.key,
      required this.authenticationRepository,
      required this.userRepository,
      required this.sessionRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => authenticationRepository),
        RepositoryProvider(create: (context) => userRepository),
        RepositoryProvider(
          create: (context) => sessionRepository,
          dispose: (repository) => repository.dispose(),
        ),
        RepositoryProvider(
          create: (context) => SupportTicketRepository(
            userRepository: userRepository,
            httpClient: userRepository.httpClient,
          ),
          dispose: (repository) => repository.dispose(),
        ),
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
              CookRepository(
                userRepository,
                httpClient: userRepository.httpClient,
              ),
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
  const AppView({super.key, this.userRepository});

  final UserRepository? userRepository;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  NavigatorState? get _navigator => navigatorKey.currentState;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    super.initState();
  }

  void _handleAuthenticationState(AuthenticationState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final navigator = _navigator;
      if (navigator == null) {
        AppLogger.warn('Navigator unavailable while handling auth state.');
        return;
      }

      switch (state.status) {
        case AuthenticationStatus.authenticated:
          final role = state.user?.data?.user?.role;
          final routeName = role == AppConstants.IS_COOK.toString()
              ? '/DashboardCook'
              : '/HomePage';
          navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
          break;

        case AuthenticationStatus.unauthenticated:
          navigator.pushNamedAndRemoveUntil('/LandingPage', (route) => false);
          break;

        case AuthenticationStatus.unknown:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return BlocListener<AuthenticationBloc, AuthenticationState>(
            listener: (context, state) {
              AppLogger.debug('Authentication status: ${state.status}');
              _handleAuthenticationState(state);
            },
            child: child,
          );
        },
        initialRoute: '/Splash',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RouteGenerator.generateRoute,
        theme: ThemeData(
          fontFamily: config.FontFamily().itcAvantGardeGothicStdFontFamily,
          primaryColor: config.AppColors().colorPrimary(1),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0, foregroundColor: Colors.white),
          brightness: Brightness.light,
          dividerColor: config.AppColors().accentColor(0.1),
          focusColor: config.AppColors().secondColor(1),
          hintColor: config.AppColors().hintTextBackgroundColor(1),
          scaffoldBackgroundColor: config.AppColors().scaffoldColor(1),
          primaryColorLight: config.AppColors().colorPrimaryLight(1),
          primaryColorDark: config.AppColors().colorPrimaryDark(1),
          textTheme: TextTheme(
              headlineSmall: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 24,
                  fontWeight: config.FontFamily().medium),
              titleLarge: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  fontWeight: config.FontFamily().book),
              bodyLarge: TextStyle(
                  color: config.AppColors().colorPrimary(1),
                  fontSize: 18,
                  fontWeight: config.FontFamily().medium),
              titleMedium: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 14,
                  fontWeight: config.FontFamily().demi),
              titleSmall: TextStyle(
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: 12,
                  fontWeight: config.FontFamily().book)),
          colorScheme: ColorScheme.fromSeed(
            seedColor: config.AppColors().colorPrimary(1),
            secondary: config.AppColors().accentColor(1),
            surface: Colors.grey.shade200,
            error: Colors.red,
          ),
        ));
  }
}
