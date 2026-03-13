import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mitabl_user/main.dart' as app;

Future<void> _pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  final steps = duration.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and renders without crashing', (tester) async {
    // NOTE: This test requires a device/emulator with Firebase config files
    // (google-services.json / GoogleService-Info.plist) in place.
    // It is a smoke test only — it does not log in.
    app.main();
    await _pumpFor(tester, const Duration(seconds: 8));

    final frameworkError = tester.takeException();
    expect(frameworkError, isNull, reason: 'Unexpected framework exception during app startup');

    // The splash screen should be visible or auth navigation should have
    // triggered. We just assert that the app runs without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
