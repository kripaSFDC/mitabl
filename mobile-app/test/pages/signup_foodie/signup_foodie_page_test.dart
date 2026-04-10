import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/helper/app_navigator.dart' as app_nav;
import 'package:mitabl_user/pages/signup/cubit/sign_up_cubit.dart';
import 'package:mitabl_user/pages/signup_foodie/view/signup_foodie_page.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
      'base_url': 'https://api.example.com/',
    });
  });

  testWidgets(
    'foodie signup collects phone number and submits a valid payload',
    (tester) async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/register')) {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'message': 'Registered Successfully.',
              'data': {
                'id': 42,
                'name': 'Chef De Cuisine',
                'email': 'foodie@example.com',
                'role': 'Foodie',
              },
            }),
            200,
          );
        }

        return http.Response('{}', 404);
      });

      final authRepository = AuthenticationRepository(
        httpClient: mockClient,
        userRepository: UserRepository(httpClient: mockClient),
      );

      await tester.pumpWidget(
        RepositoryProvider<AuthenticationRepository>.value(
          value: authRepository,
          child: MaterialApp(
            navigatorKey: app_nav.navigatorKey,
            home: BlocProvider(
              create: (context) =>
                  SignUpCubit(context.read<AuthenticationRepository>()),
              child: const SignupFoodiePage(),
            ),
            onGenerateRoute: (settings) {
              if (settings.name == '/OTPPage') {
                return MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('otp page')),
                );
              }

              return null;
            },
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Chef De Cuisine'),
        'Alex Homechef',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'hello@mifoodi.com'),
        'foodie@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '+61'),
        '+61',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '400 000 000'),
        '400000000',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
        ),
        'Password1!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, "Enter your kitchen's location"),
        '1 Example Street',
      );

      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(capturedBody, isNotNull);
      expect(capturedBody!['role_id'], 3);
      expect(capturedBody!['email'], 'foodie@example.com');
      expect(capturedBody!['phone'], '+61400000000');
      expect(capturedBody!['password'], 'Password1!');
      expect(capturedBody!['password_confirmation'], 'Password1!');
      expect(find.text('otp page'), findsOneWidget);
    },
  );
}
