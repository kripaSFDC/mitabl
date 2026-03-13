import 'package:flutter/material.dart';

/// A reusable inline widget shown when an API call fails due to connectivity.
///
/// Renders an icon, a message, and a "Retry" button. Pass [onRetry] to
/// re-trigger the failed action.
class OfflineErrorWidget extends StatelessWidget {
  const OfflineErrorWidget({
    super.key,
    required this.onRetry,
    this.message = 'No internet connection.\nPlease check your network and try again.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Offline status icon',
              image: true,
              child: Icon(Icons.wifi_off_rounded,
                  size: 64, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Retry loading content',
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A slim banner shown at the top of [AppView] when connectivity is lost.
/// Slides in/out based on [isOffline].
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isOffline ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.red.shade700,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Semantics(
                    label: 'Offline',
                    image: true,
                    child: Icon(Icons.wifi_off_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
