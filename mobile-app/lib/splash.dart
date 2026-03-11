import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';

import 'auth_bloc/authentication/authentication_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const SplashPage());
  }

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _fallbackDelay = Duration(seconds: 3);
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(_fallbackDelay, _navigateToLandingIfStillUnknown);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _navigateToLandingIfStillUnknown() {
    if (!mounted) {
      return;
    }

    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.unknown) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/LandingPage',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Image.asset(
              'assets/img/logo.png',
              height: config.AppConfig(context).appHeight(20),
              width: config.AppConfig(context).appWidth(80),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
