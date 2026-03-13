import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/route_generator.dart';

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
  testWidgets('Cook profile route without args shows route error',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: '/CookProfile',
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Missing route arguments for /CookProfile'),
      findsOneWidget,
    );
  });

  testWidgets('Order details route without args shows route error',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: '/OrderDetails',
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Missing route arguments for /OrderDetails'),
      findsOneWidget,
    );
  });

  testWidgets('Order details route with id-only falls back safely to Bookings',
      (tester) async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
      'base_url': 'https://api.example.com/',
      'image_base_url': 'https://cdn.example.com/',
    });

    final navigatorKey = GlobalKey<NavigatorState>();
    final observedRoutes = <String?>[];

    await tester.pumpWidget(
      RepositoryProvider<UserRepository>(
        create: (_) => UserRepository(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: RouteGenerator.generateRoute,
          navigatorObservers: [
            _RouteObserver(onPushed: (route) {
              observedRoutes.add(route.settings.name);
            }),
          ],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    navigatorKey.currentState!.pushNamed(
      '/OrderDetails',
      arguments: RouteArguments(id: '1234'),
    );

    await _pumpFor(tester, const Duration(seconds: 2));

    expect(find.text('Missing route arguments for /OrderDetails'), findsNothing);
    expect(observedRoutes, isNot(contains('/OrderDetails')));
    expect(observedRoutes, isNotEmpty);
  });
}

class _RouteObserver extends NavigatorObserver {
  _RouteObserver({required this.onPushed});

  final void Function(Route<dynamic> route) onPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPushed(route);
    super.didPush(route, previousRoute);
  }
}
