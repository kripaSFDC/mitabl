import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Full-screen biometric lock shown on cold start or app resume when the
/// user has enabled biometric authentication.
///
/// Returns `true` when authentication succeeds and `false` when user chooses
/// to bypass for the current foreground session.
class BiometricLockPage extends StatefulWidget {
  const BiometricLockPage({super.key});

  static Route<bool> route() =>
      MaterialPageRoute<bool>(builder: (_) => const BiometricLockPage());

  @override
  State<BiometricLockPage> createState() => _BiometricLockPageState();
}

class _BiometricLockPageState extends State<BiometricLockPage> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    unawaited(BiometricService.instance.stopAuthentication());
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final success = await BiometricService.instance.authenticate(
      reason: 'Unlock Mitabl to continue',
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _authenticating = false;
        _error = 'Authentication failed. Please try again.';
      });
    }
  }

  Future<void> _bypassForSession() async {
    unawaited(BiometricService.instance.stopAuthentication());
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: Stack(
        children: [
          // Subtle background motifs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: MitablColors.secondaryContainer.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5).withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // TopAppBar: centered lock icon
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64,
                child: Center(
                  child: Icon(
                    Icons.lock_outlined,
                    color: MitablColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        const SizedBox(height: 96), // below app bar

                        // Identity section
                        Column(
                          children: [
                            const Text(
                              'mitabl',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Nunito',
                                color: MitablColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 4,
                              width: 32,
                              decoration: BoxDecoration(
                                color: MitablColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: constraints.maxHeight >= 700 ? 72 : 40,
                        ),

                        // Biometric Interaction Zone
                        Column(
                          children: [
                            // Fingerprint scanner UI with tonal ring layers
                            GestureDetector(
                              onTap: _authenticating ? null : _authenticate,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Container(
                                    width: 192,
                                    height: 192,
                                    decoration: BoxDecoration(
                                      color: MitablColors.primary
                                          .withValues(alpha: 0.10),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Main fingerprint circle
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      color:
                                          MitablColors.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: MitablColors.onSurface
                                              .withValues(alpha: 0.08),
                                          blurRadius: 32,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _authenticating
                                        ? const Center(
                                            child: SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: CircularProgressIndicator(
                                                color: MitablColors.primary,
                                                strokeWidth: 3,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.fingerprint_rounded,
                                            size: 60,
                                            color: Color(0xFFEA580C),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Security messaging
                            const Text(
                              'Locked for your security',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                                color: MitablColors.onSurface,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(
                              width: 240,
                              child: Text(
                                'Use Face ID or Fingerprint to unlock',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: MitablColors.error,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),

                        SizedBox(
                          height: constraints.maxHeight >= 700 ? 72 : 40,
                        ),

                        // Fallback action section
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Use Password button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _bypassForSession,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        MitablColors.secondaryContainer,
                                    foregroundColor:
                                        MitablColors.onSecondaryContainer,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: MitablRadius.pillBorder,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.password_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'USE PASSWORD',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Encryption footer
                              const Text(
                                'YOUR DATA IS PROTECTED BY MITABL ENCRYPTION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
