import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/helper/connectivity_service.dart';
import 'package:mitabl_user/helper/deep_link_service.dart';
import 'package:mitabl_user/helper/notification_service.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/pages/common/biometric_lock_page.dart';
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

  const App({
    super.key,
    required this.authenticationRepository,
    required this.userRepository,
    required this.sessionRepository,
  });

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

class _AppViewState extends State<AppView> with WidgetsBindingObserver {
  NavigatorState? get _navigator => navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    WidgetsBinding.instance.addObserver(this);
    ConnectivityService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBiometricLockIfNeeded();
    });
    // Phase 4: wire up push notifications and deep links after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init(
        navigatorKey,
        userRepository: widget.userRepository,
      );
      DeepLinkService.instance.init(navigatorKey);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isBiometricLockShowing = false;
  bool _biometricBypassedForSession = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _biometricBypassedForSession = false;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _showBiometricLockIfNeeded();
    }
  }

  Future<void> _showBiometricLockIfNeeded() async {
    if (_isBiometricLockShowing || _biometricBypassedForSession) return;

    final enabled = await BiometricService.instance.isEnabled();
    if (!enabled) return;

    final navigator = _navigator;
    if (navigator == null || !mounted) return;

    _isBiometricLockShowing = true;
    final unlocked = await navigator.push<bool>(BiometricLockPage.route());
    _isBiometricLockShowing = false;
    if (unlocked == false) {
      _biometricBypassedForSession = true;
    }
  }


  void _handleAuthenticationState(AuthenticationState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = _navigator;
      if (navigator == null) {
        AppLogger.warn('Navigator unavailable while handling auth state.');
        return;
      }

      switch (state.status) {
        case AuthenticationStatus.authenticated:
          NotificationService.instance.syncTokenWithBackendIfPossible();
          final role = state.user?.data?.user?.role;
          final routeName = AppConstants.isCookRole(role)
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
          // Stack a connectivity banner on top of all routes without touching
          // any individual page.
          child: StreamBuilder<bool>(
            stream: ConnectivityService.instance.onConnectivityChanged,
            builder: (context, snapshot) {
              final isOffline = snapshot.data == false;
              return Stack(
                children: [
                  child!,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ConnectivityBanner(isOffline: isOffline),
                  ),
                ],
              );
            },
          ),
        );
      },
      initialRoute: '/Splash',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        fontFamily: 'itc_avant_garde_gothic_std',
        primaryColor: config.AppColors().colorPrimary(1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 0, foregroundColor: Colors.white),
        brightness: Brightness.light,
        dividerColor: config.AppColors().colorDivider(1),
        focusColor: config.AppColors().secondColor(1),
        hintColor: config.AppColors().hintTextBackgroundColor(1),
        scaffoldBackgroundColor:
            config.AppColors().scaffoldColor(1, brightness: Brightness.light),
        primaryColorLight: config.AppColors().colorPrimaryLight(1),
        primaryColorDark: config.AppColors().colorPrimaryDark(1),
        appBarTheme: AppBarTheme(
          backgroundColor: config.AppColors().scaffoldColor(1),
          foregroundColor: config.AppColors().colorPrimaryDark(1),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: config.AppColors().colorPrimary(1),
          unselectedItemColor: config.AppColors().hintTextBackgroundColor(0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: config.AppColors().colorPrimary(1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: config.AppColors().colorPrimary(1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: config.AppColors().textFieldBackgroundColor(1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: config.AppColors().colorPrimary(0.2),
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: TextStyle(
            color: config.AppColors().hintTextBackgroundColor(0.6),
            fontWeight: FontWeight.w300,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFD9C2B6),
          selectedColor: config.AppColors().colorPrimary(1),
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: BorderSide.none,
        ),
        textTheme: TextTheme(
            displayLarge: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 32,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800),
            displayMedium: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 28,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800),
            headlineLarge: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 24,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800),
            headlineSmall: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 20,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800),
            titleLarge: TextStyle(
                color: config.AppColors().hintTextBackgroundColor(1),
                fontSize: 16,
                fontWeight: FontWeight.w300),
            bodyLarge: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 16,
                fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(
                color: config.AppColors().hintTextBackgroundColor(1),
                fontSize: 14,
                fontWeight: FontWeight.w400),
            titleMedium: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 14,
                fontWeight: FontWeight.w600),
            titleSmall: TextStyle(
                color: config.AppColors().colorPrimaryDark(1),
                fontSize: 12,
                fontWeight: FontWeight.w300),
            labelLarge: TextStyle(
                color: config.AppColors().colorPrimary(1),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: config.AppColors().colorPrimary(1),
          onPrimary: Colors.white,
          secondary: config.AppColors().accentColor(1),
          onSecondary: Colors.white,
          surface: config.AppColors().textFieldBackgroundColor(1),
          onSurface: config.AppColors().colorPrimaryDark(1),
          error: Colors.red,
          onError: Colors.white,
        ),
      ),
    );
  }
}
