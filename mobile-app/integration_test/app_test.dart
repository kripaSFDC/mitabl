import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mitabl_user/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and renders without crashing', (tester) async {
    // NOTE: This test requires a device/emulator with Firebase config files
    // (google-services.json / GoogleService-Info.plist) in place.
    // It is a smoke test only — it does not log in.
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The splash screen should be visible or auth navigation should have
    // triggered. We just assert that the app runs without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
