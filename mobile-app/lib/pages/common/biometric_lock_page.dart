import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

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

  void _bypassForSession() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Brand
                const Text(
                  'Mitabl',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    color: MitablColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Fingerprint with tonal ring layers
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: MitablColors.primary.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: MitablColors.primary.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MitablColors.onSurface
                                .withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 44,
                        color: MitablColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const Text(
                  'Locked for your security',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Face ID or Fingerprint to unlock',
                  style: TextStyle(
                    fontSize: 15,
                    color: MitablColors.onSurfaceVariant
                        .withValues(alpha: 0.8),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: MitablColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 36),

                if (_authenticating)
                  const CircularProgressIndicator(
                    color: MitablColors.primary,
                  )
                else ...[
                  MitablButton(
                    label: 'Unlock',
                    icon: const Icon(Icons.fingerprint_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _authenticate,
                  ),
                  const SizedBox(height: 12),
                  MitablButton(
                    label: 'USE PASSWORD',
                    variant: MitablButtonVariant.secondary,
                    onPressed: _bypassForSession,
                  ),
                ],

                const Spacer(flex: 4),

                // Encryption footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14,
                        color: MitablColors.onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      'YOUR DATA IS PROTECTED BY MITABL ENCRYPTION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: MitablColors.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
