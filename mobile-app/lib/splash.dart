import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/update_check_service.dart';
import 'package:mitabl_user/pages/common/update_gate_widget.dart';
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

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _fallbackDelay = Duration(seconds: 3);
  Timer? _fallbackTimer;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _runStartupChecks();
    _fallbackTimer = Timer(_fallbackDelay, _navigateToLandingIfStillUnknown);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _dotController.dispose();
    super.dispose();
  }

  /// Runs the update check during the natural splash delay.
  /// Never blocks navigation — the fallback timer handles the worst case.
  Future<void> _runStartupChecks() async {
    if (!mounted) return;
    final result = await UpdateCheckService.instance.check();
    if (!mounted) return;
    await UpdateGateWidget.showIfNeeded(context, result);
  }

  void _navigateToLandingIfStillUnknown() {
    if (!mounted) return;

    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.unknown) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/LandingPage',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F4),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Logo icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C3E20).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 40,
                  color: Color(0xFF9C3E20),
                ),
              ),
              const SizedBox(height: 24),

              // Brand name
              const Text(
                'Mitabl',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: Color(0xFF9C3E20),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Taste the heart of your\nneighborhood.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF56423C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // Loading dots
              _PulsingDots(controller: _dotController),

              const Spacer(flex: 4),

              // Footer
              Text(
                'CULINARY CONNECTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: const Color(0xFF56423C).withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.25;
            final value = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (1.0 - (value - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C3E20),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
