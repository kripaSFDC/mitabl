import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/pages/login/cubit/login_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/auth_aware_http_client.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class _MockUserRepository extends Mock implements UserRepository {}

// ─── Builder helper ──────────────────────────────────────────────────────────

LoginCubit _buildCubit({
  required MockClient mockClient,
  required UserRepository userRepo,
  Future<bool> Function()? onlineChecker,
}) {
  final sessionRepository = SessionRepository(httpClient: mockClient);
  final authClient = AuthAwareHttpClient(
    inner: mockClient,
    sessionRepository: sessionRepository,
    onlineChecker: onlineChecker ?? () async => true,
  );
  sessionRepository.attachUserRepository(userRepo);

  final authRepo = AuthenticationRepository(
    httpClient: authClient,
    userRepository: userRepo,
    sessionRepository: sessionRepository,
  );

  return LoginCubit(authRepository: authRepo, repo: userRepo);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
    registerFallbackValue(Uri());
  });

  group('LoginCubit', () {
    blocTest<LoginCubit, LoginState>(
      'emits submissionInProgress then submissionSuccess on 200',
      build: () {
        final mockUserRepo = _MockUserRepository();
        // Stub setCurrentUser so it doesn't call SharedPreferences plugin.
        when(() => mockUserRepo.setCurrentUser(any()))
            .thenAnswer((_) async {});

        return _buildCubit(
          mockClient: MockClient((_) async => http.Response(
                jsonEncode({
                  'response_code': 200,
                  'isSuccess': true,
                  'data': {
                    'access_token': 'token-abc',
                    'token_type': 'bearer',
                    'user': {'id': 1, 'role': 'Foodie'},
                  },
                }),
                200,
              )),
          userRepo: mockUserRepo,
        );
      },
      act: (cubit) async {
        cubit.onEmailChanged(value: 'test@example.com');
        cubit.onPasswordChanged(value: 'Password1!');
        await Future.microtask(cubit.doLogin);
      },
      expect: () => [
        isA<LoginState>()
            .having((s) => s.email.value, 'email', 'test@example.com'),
        isA<LoginState>(),
        isA<LoginState>().having(
            (s) => s.apiStatus, 'status', FormzStatus.submissionInProgress),
        isA<LoginState>().having(
            (s) => s.apiStatus, 'status', FormzStatus.submissionSuccess),
      ],
      wait: const Duration(milliseconds: 500),
    );

    blocTest<LoginCubit, LoginState>(
      'emits submissionFailure with server message on non-200',
      build: () => _buildCubit(
        mockClient: MockClient((_) async => http.Response(
              jsonEncode({'message': 'Invalid credentials'}),
              401,
            )),
        userRepo: _MockUserRepository(),
      ),
      act: (cubit) async {
        cubit.onEmailChanged(value: 'bad@example.com');
        cubit.onPasswordChanged(value: 'WrongPass1');
        await Future.microtask(cubit.doLogin);
      },
      expect: () => [
        isA<LoginState>(),
        isA<LoginState>(),
        isA<LoginState>().having(
            (s) => s.apiStatus, 'status', FormzStatus.submissionInProgress),
        isA<LoginState>()
            .having(
                (s) => s.apiStatus, 'status', FormzStatus.submissionFailure)
            .having((s) => s.serverMessage, 'message',
                contains('Invalid credentials')),
        isA<LoginState>(),
      ],
      wait: const Duration(milliseconds: 500),
    );


    test('normalizes login payload before sending it to backend', () async {
      final capturedBodies = <Map<String, dynamic>>[];
      final mockUserRepo = _MockUserRepository();
      when(() => mockUserRepo.setCurrentUser(any())).thenAnswer((_) async {});

      final cubit = _buildCubit(
        mockClient: MockClient((request) async {
          capturedBodies.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(
            jsonEncode({
              'response_code': 200,
              'isSuccess': true,
              'data': {
                'access_token': 'token-abc',
                'token_type': 'bearer',
                'user': {'id': 1, 'role': 'Foodie'},
              },
            }),
            200,
          );
        }),
        userRepo: mockUserRepo,
      );

      cubit.onEmailChanged(value: '  TEST@Example.com  ');
      cubit.onPasswordChanged(value: '  Password1!  ');
      await Future.microtask(cubit.doLogin);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(capturedBodies, hasLength(1));
      expect(capturedBodies.first['email'], 'test@example.com');
      expect(capturedBodies.first['username'], 'test@example.com');
      expect(capturedBodies.first['password'], 'Password1!');

      await cubit.close();
    });
    blocTest<LoginCubit, LoginState>(
      'emits submissionFailure with offline message when device is offline',
      build: () => _buildCubit(
        // Returning false from onlineChecker causes OfflineException.
        onlineChecker: () async => false,
        mockClient:
            MockClient((_) async => http.Response('should not reach', 200)),
        userRepo: _MockUserRepository(),
      ),
      act: (cubit) async {
        cubit.onEmailChanged(value: 'test@example.com');
        cubit.onPasswordChanged(value: 'Password1!');
        await Future.microtask(cubit.doLogin);
      },
      expect: () => [
        isA<LoginState>(),
        isA<LoginState>(),
        isA<LoginState>().having(
            (s) => s.apiStatus, 'status', FormzStatus.submissionInProgress),
        isA<LoginState>()
            .having(
                (s) => s.apiStatus, 'status', FormzStatus.submissionFailure)
            .having((s) => s.serverMessage, 'message', contains('No internet')),
      ],
      wait: const Duration(milliseconds: 500),
    );
  });
}
