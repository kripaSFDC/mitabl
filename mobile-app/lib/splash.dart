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
      body: Stack(
        children: [
          // ── Subtle organic background blurs ──
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDBD0).withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.1,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFFCCE7C3).withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Floating decorative icons ──
          Positioned(
            top: 80,
            left: MediaQuery.of(context).size.width * 0.1,
            child: Transform.rotate(
              angle: 0.21, // ~12 degrees
              child: Icon(
                Icons.spa,
                size: 60,
                color: const Color(0xFF4D6548).withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            right: MediaQuery.of(context).size.width * 0.15,
            child: Transform.rotate(
              angle: -0.785, // ~-45 degrees
              child: Icon(
                Icons.local_dining,
                size: 80,
                color: const Color(0xFF9C3E20).withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            right: -32,
            child: Icon(
              Icons.grain,
              size: 70,
              color: const Color(0xFF6A594E).withValues(alpha: 0.15),
            ),
          ),

          // ── Central content ──
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Icon container – white rounded-xl card with ghost border
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Ghost border overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF9C3E20)
                                      .withValues(alpha: 0.05),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // Circle with icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C3E20)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              size: 48,
                              color: Color(0xFF9C3E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brand name – text-5xl = 48px
                    const Text(
                      'Mitabl',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                        color: Color(0xFF9C3E20),
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline – text-lg = 18px
                    const SizedBox(
                      width: 240,
                      child: Text(
                        'Taste the heart of your neighborhood.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'DM Sans',
                          color: Color(0xFF56423C),
                          height: 1.6,
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Loading dots – positioned near bottom
                    _PulsingDots(controller: _dotController),
                    const SizedBox(height: 40),

                    // Footer divider bar
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDC0B8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer text
                    Text(
                      'CULINARY CONNECTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.2,
                        color: const Color(0xFF56423C).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
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
