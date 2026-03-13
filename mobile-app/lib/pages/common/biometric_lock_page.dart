import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/biometric_service.dart';

/// Full-screen biometric lock shown on cold start or app resume when the
/// user has enabled biometric authentication.
///
/// On success it simply pops itself from the navigator, revealing the
/// underlying route. On repeated failure, an "Use PIN" fallback is offered
/// which also pops (local_auth already includes PIN as a fallback when
/// [AuthenticationOptions.biometricOnly] is false).
class BiometricLockPage extends StatefulWidget {
  const BiometricLockPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const BiometricLockPage());

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
      Navigator.of(context).pop();
    } else {
      setState(() {
        _authenticating = false;
        _error = 'Authentication failed. Please try again.';
      });
    }
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
                Icon(
                  Icons.fingerprint_rounded,
                  size: 80,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Unlock Mitabl',
                  style: theme.textTheme.headlineSmall,
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
                else
                  FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
