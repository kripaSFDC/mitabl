import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';

void main() {
  group('OfflineErrorWidget', () {
    testWidgets('renders icon, message, and retry button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineErrorWidget(
              onRetry: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No internet connection.\nPlease check your network and try again.'),
          findsOneWidget);
    });

    testWidgets('calls onRetry when Retry button is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineErrorWidget(
              onRetry: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });

    testWidgets('shows custom message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineErrorWidget(
              onRetry: () {},
              message: 'Custom error message',
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
    });
  });

  group('ConnectivityBanner', () {
    testWidgets('shows content when isOffline is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(isOffline: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('is visually hidden when isOffline is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(isOffline: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Widget is in tree but has 0 opacity
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });
  });
}
