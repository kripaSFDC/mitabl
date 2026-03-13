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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showBiometricLockIfNeeded();
    }
  }

  Future<void> _showBiometricLockIfNeeded() async {
    if (_isBiometricLockShowing) return;
    
    final enabled = await BiometricService.instance.isEnabled();
    if (!enabled) return;
    
    final navigator = _navigator;
    if (navigator == null || !mounted) return;

    _isBiometricLockShowing = true;
    await navigator.push(BiometricLockPage.route());
    _isBiometricLockShowing = false;
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
        fontFamily: config.FontFamily().itcAvantGardeGothicStdFontFamily,
        primaryColor: config.AppColors().colorPrimary(1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 0, foregroundColor: Colors.white),
        brightness: Brightness.light,
        dividerColor: config.AppColors().accentColor(0.1),
        focusColor: config.AppColors().secondColor(1),
        hintColor: config.AppColors().hintTextBackgroundColor(1),
        scaffoldBackgroundColor:
            config.AppColors().scaffoldColor(1, brightness: Brightness.light),
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
      ),
    );
  }
}
