import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/helper/update_check_service.dart';
import 'package:mitabl_user/pages/common/update_gate_widget.dart';

void main() {
  group('UpdateGateWidget', () {
    testWidgets('shows non-dismissible dialog for required update',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => UpdateGateWidget.showIfNeeded(
                  context,
                  const UpdateResult(
                    type: UpdateType.required,
                    latestVersion: '2.0.0',
                    iosUrl: 'https://example.com',
                    androidUrl: 'https://example.com',
                  ),
                ),
                child: const Text('Trigger'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      // "Later" should not be present for required updates.
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('shows dismissible dialog for optional update', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => UpdateGateWidget.showIfNeeded(
                  context,
                  const UpdateResult(
                    type: UpdateType.optional,
                    latestVersion: '1.5.0',
                    iosUrl: 'https://example.com',
                    androidUrl: 'https://example.com',
                  ),
                ),
                child: const Text('Trigger'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      // Tapping "Later" should dismiss the dialog.
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('Update Available'), findsNothing);
    });

    testWidgets('shows nothing for UpdateType.none', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    UpdateGateWidget.showIfNeeded(context, const UpdateResult.none()),
                child: const Text('Trigger'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();
      // No dialog should appear.
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
