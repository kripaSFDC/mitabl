import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/pages/favourites/view/favourites_page.dart';
import 'package:mitabl_user/pages/miorders/view/miorders_page.dart';
import 'package:mitabl_user/pages/payments/view/payments_page.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/pages/profile_foodie/view/profile_foodie_page.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(const <String, String>{});
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
      'base_url': 'https://api.example.com/',
      'image_base_url': 'https://cdn.example.com/',
    });
  });

  testWidgets('profile tiles navigate to newly registered routes',
      (tester) async {
    final userRepository = _FakeUserRepository();
    final authenticationRepository = AuthenticationRepository(
      userRepository: userRepository,
    );
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<UserRepository>.value(value: userRepository),
          RepositoryProvider<AuthenticationRepository>.value(
            value: authenticationRepository,
          ),
        ],
        child: BlocProvider(
          create: (context) => ProfileFoodieCubit(
            userRepository: userRepository,
            authenticationRepository: authenticationRepository,
          ),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            routes: {
              '/MiOrders': (_) => const Scaffold(body: Text('miorders route')),
              '/Favourites': (_) =>
                  const Scaffold(body: Text('favourites route')),
              '/Payments': (_) => const Scaffold(body: Text('payments route')),
            },
            home: const ProfileFoodiePage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('miorders'), findsOneWidget);
    expect(find.text('favourites'), findsOneWidget);
    expect(find.text('payments'), findsOneWidget);

    navigatorKey.currentState!.pushNamed('/MiOrders');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('miorders route'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    navigatorKey.currentState!.pushNamed('/Favourites');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('favourites route'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    navigatorKey.currentState!.pushNamed('/Payments');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('payments route'), findsOneWidget);
  });

  testWidgets('miorders page keeps empty-state for successful empty payload',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _FakeMiOrdersRepository()),
    );
    expect(find.text('No data found'), findsOneWidget);
  });

  testWidgets('miorders page triggers session unauthorized flow on 401',
      (tester) async {
    final sessionRepository = SessionRepository();
    final eventFuture = sessionRepository.events.first;

    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _UnauthorizedMiOrdersRepository()),
      sessionRepository: sessionRepository,
    );

    await expectLater(eventFuture, completion(SessionEvent.unauthorized));
    expect(find.textContaining('No internet connection'), findsNothing);
  });

  testWidgets('favourites page triggers session unauthorized flow on 401',
      (tester) async {
    final sessionRepository = SessionRepository();
    final eventFuture = sessionRepository.events.first;

    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _UnauthorizedFavouritesRepository()),
      sessionRepository: sessionRepository,
    );

    await expectLater(eventFuture, completion(SessionEvent.unauthorized));
    expect(find.textContaining('No internet connection'), findsNothing);
  });

  testWidgets('payments page triggers session unauthorized flow on 401',
      (tester) async {
    final sessionRepository = SessionRepository();
    final eventFuture = sessionRepository.events.first;

    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _UnauthorizedPaymentsRepository()),
      sessionRepository: sessionRepository,
    );

    await expectLater(eventFuture, completion(SessionEvent.unauthorized));
    expect(find.textContaining('No internet connection'), findsNothing);
  });

  testWidgets('miorders page shows switch CTA for 403', (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _ForbiddenMiOrdersRepository()),
    );
    expect(find.text('Switch to mifoodi to access this page'), findsOneWidget);
    expect(find.text('Switch to mifoodi'), findsOneWidget);
  });

  testWidgets('miorders page shows server message and retry for 422',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _UnprocessableMiOrdersRepository()),
    );
    expect(find.text('Invalid filters for orders'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('favourites page keeps empty-state for successful empty payload',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _FakeFavouritesRepository()),
    );
    expect(find.text('No data found'), findsOneWidget);
  });

  testWidgets('favourites page shows switch CTA for 403', (tester) async {
    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _ForbiddenFavouritesRepository()),
    );
    expect(find.text('Switch to mifoodi to access this page'), findsOneWidget);
    expect(find.text('Switch to mifoodi'), findsOneWidget);
  });

  testWidgets('favourites page shows server message and retry for 422',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _UnprocessableFavouritesRepository()),
    );
    expect(find.text('Favourite list request is invalid'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('payments page keeps empty-state for successful empty payload',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _FakePaymentsRepository()),
    );
    expect(find.text('No data found'), findsOneWidget);
  });

  testWidgets('payments page shows switch CTA for 403', (tester) async {
    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _ForbiddenPaymentsRepository()),
    );
    expect(find.text('Switch to mifoodi to access this page'), findsOneWidget);
    expect(find.text('Switch to mifoodi'), findsOneWidget);
  });

  testWidgets('payments page shows server message and retry for 422',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _UnprocessablePaymentsRepository()),
    );
    expect(find.text('Payment request is invalid'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
      'miorders page silently recovers foodie access after recoverable 403',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _RecoverableMiOrdersRepository()),
      userRepository: _FakeUserRepository(
        switchResponse:
            http.Response('{"data":{"role":"Foodie","role_id":3}}', 200),
      ),
    );

    expect(find.text('No data found'), findsOneWidget);
    expect(find.text('Switch to mifoodi to access this page'), findsNothing);
  });

  testWidgets(
      'favourites page silently recovers foodie access after recoverable 403',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _RecoverableFavouritesRepository()),
      userRepository: _FakeUserRepository(
        switchResponse:
            http.Response('{"data":{"role":"Foodie","role_id":3}}', 200),
      ),
    );

    expect(find.text('No data found'), findsOneWidget);
    expect(find.text('Switch to mifoodi to access this page'), findsNothing);
  });

  testWidgets(
      'payments page silently recovers foodie access after recoverable 403',
      (tester) async {
    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _RecoverablePaymentsRepository()),
      userRepository: _FakeUserRepository(
        switchResponse:
            http.Response('{"data":{"role":"Foodie","role_id":3}}', 200),
      ),
    );

    expect(find.text('No data found'), findsOneWidget);
    expect(find.text('Switch to mifoodi to access this page'), findsNothing);
  });
}

Future<void> _pumpWithProviders(
  WidgetTester tester, {
  required Widget home,
  SessionRepository? sessionRepository,
  UserRepository? userRepository,
}) async {
  final resolvedSessionRepository = sessionRepository ?? SessionRepository();
  final resolvedUserRepository = userRepository ?? _FakeUserRepository();
  if (sessionRepository == null) {
    addTearDown(resolvedSessionRepository.dispose);
  }

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>.value(value: resolvedUserRepository),
        RepositoryProvider<SessionRepository>.value(
            value: resolvedSessionRepository),
      ],
      child: MaterialApp(home: home),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository({
    this.switchResponse,
  });

  final http.Response? switchResponse;

  @override
  Future<UserModel?> getUser() async => null;

  @override
  Future<http.Response> switchRole({required int roleId}) async {
    return switchResponse ?? http.Response('{"isError":"Unavailable"}', 422);
  }
}

class _FakeMiOrdersRepository extends MiOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    return const [];
  }
}

class _ForbiddenMiOrdersRepository extends MiOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
  }
}

class _UnprocessableMiOrdersRepository extends MiOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(
        statusCode: 422, message: 'Invalid filters for orders');
  }
}

class _FakeFavouritesRepository extends FavouritesRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    return const [];
  }
}

class _ForbiddenFavouritesRepository extends FavouritesRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
  }
}

class _UnprocessableFavouritesRepository extends FavouritesRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(
        statusCode: 422, message: 'Favourite list request is invalid');
  }
}

class _FakePaymentsRepository extends PaymentsRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards(
      {required UserModel? userModel}) async {
    return const [];
  }
}

class _ForbiddenPaymentsRepository extends PaymentsRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards(
      {required UserModel? userModel}) async {
    return const [];
  }
}

class _UnprocessablePaymentsRepository extends PaymentsRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(
        statusCode: 422, message: 'Payment request is invalid');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards(
      {required UserModel? userModel}) async {
    return const [];
  }
}

class _RecoverableMiOrdersRepository extends MiOrdersRepository {
  bool _failedOnce = false;

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
    }

    return const [];
  }
}

class _RecoverableFavouritesRepository extends FavouritesRepository {
  bool _failedOnce = false;

  @override
  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
    }

    return const [];
  }
}

class _RecoverablePaymentsRepository extends PaymentsRepository {
  bool _failedOnce = false;

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw RepositoryHttpException(statusCode: 403, message: 'Forbidden');
    }

    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards(
      {required UserModel? userModel}) async {
    return const [];
  }
}

class _UnauthorizedMiOrdersRepository extends MiOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrdersHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 401, message: 'Unauthorized');
  }
}

class _UnauthorizedFavouritesRepository extends FavouritesRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchFavourites({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 401, message: 'Unauthorized');
  }
}

class _UnauthorizedPaymentsRepository extends PaymentsRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchPaymentsHistory({
    required UserModel? userModel,
    int page = 1,
    int limit = 20,
  }) async {
    throw RepositoryHttpException(statusCode: 401, message: 'Unauthorized');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards(
      {required UserModel? userModel}) async {
    return const [];
  }
}
