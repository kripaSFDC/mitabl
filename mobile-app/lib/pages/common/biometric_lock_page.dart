import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/biometric_service.dart';

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
    // Automatically prompt as soon as the page is shown.
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  image: true,
                  label: 'Biometric authentication icon',
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Unlock Mitabl',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to access your account',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                if (_authenticating)
                  const CircularProgressIndicator()
                else ...[
                  Semantics(
                    button: true,
                    label: 'Try biometric authentication again',
                    child: FilledButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    button: true,
                    label: 'Use passcode and bypass biometric lock for now',
                    child: TextButton(
                      onPressed: _bypassForSession,
                      child: const Text('Use Passcode'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
