import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/pages/common/biometric_lock_page.dart';

void main() {
  Future<void> openLockPage(
      WidgetTester tester, void Function(bool?) onDone) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    BiometricLockPage.route(),
                  );
                  onDone(result);
                },
                child: const Text('Open Lock'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Lock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('use password bypass pops false', (tester) async {
    bool? result;
    final view = tester.view;
    final originalSize = view.physicalSize;
    final originalDpr = view.devicePixelRatio;

    view.physicalSize = const Size(1080, 1920);
    view.devicePixelRatio = 1.0;

    addTearDown(() {
      view.physicalSize = originalSize;
      view.devicePixelRatio = originalDpr;
    });

    await openLockPage(tester, (value) => result = value);

    final usePasswordButton =
        find.widgetWithText(ElevatedButton, 'USE PASSWORD');
    expect(usePasswordButton, findsOneWidget);

    await tester.ensureVisible(usePasswordButton);
    await tester.tap(usePasswordButton);
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('compact viewport keeps use password action reachable',
      (tester) async {
    bool? result;
    final view = tester.view;
    final originalSize = view.physicalSize;
    final originalDpr = view.devicePixelRatio;

    // Mimic compact screens where overflow previously occurred.
    view.physicalSize = const Size(360, 640);
    view.devicePixelRatio = 1.0;

    addTearDown(() {
      view.physicalSize = originalSize;
      view.devicePixelRatio = originalDpr;
    });

    await openLockPage(tester, (value) => result = value);

    expect(tester.takeException(), isNull);

    final usePasswordButton =
        find.widgetWithText(ElevatedButton, 'USE PASSWORD');
    await tester.ensureVisible(usePasswordButton);
    await tester.tap(usePasswordButton);
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
