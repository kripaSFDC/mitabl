import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
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

  testWidgets('profile tiles navigate to newly registered routes', (tester) async {
    final userRepository = _FakeUserRepository();
    final authenticationRepository = AuthenticationRepository(
      userRepository: userRepository,
    );

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
            routes: {
              '/MiOrders': (_) => const Scaffold(body: Text('miorders route')),
              '/Favourites': (_) => const Scaffold(body: Text('favourites route')),
              '/Payments': (_) => const Scaffold(body: Text('payments route')),
            },
            home: const ProfileFoodiePage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('miorders'));
    await tester.pumpAndSettle();
    expect(find.text('miorders route'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('favourites'));
    await tester.pumpAndSettle();
    expect(find.text('favourites route'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('payments'));
    await tester.pumpAndSettle();
    expect(find.text('payments route'), findsOneWidget);
  });

  testWidgets('miorders page keeps empty-state for successful empty payload', (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _FakeMiOrdersRepository()),
    );
    expect(find.text('No data found'), findsOneWidget);
  });



  testWidgets('miorders page triggers session unauthorized flow on 401', (tester) async {
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

  testWidgets('favourites page triggers session unauthorized flow on 401', (tester) async {
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

  testWidgets('payments page triggers session unauthorized flow on 401', (tester) async {
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

  testWidgets('miorders page shows server message and retry for 422', (tester) async {
    await _pumpWithProviders(
      tester,
      home: MiOrdersPage(repository: _UnprocessableMiOrdersRepository()),
    );
    expect(find.text('Invalid filters for orders'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('favourites page keeps empty-state for successful empty payload', (tester) async {
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

  testWidgets('favourites page shows server message and retry for 422', (tester) async {
    await _pumpWithProviders(
      tester,
      home: FavouritesPage(repository: _UnprocessableFavouritesRepository()),
    );
    expect(find.text('Favourite list request is invalid'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('payments page keeps empty-state for successful empty payload', (tester) async {
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

  testWidgets('payments page shows server message and retry for 422', (tester) async {
    await _pumpWithProviders(
      tester,
      home: PaymentsPage(repository: _UnprocessablePaymentsRepository()),
    );
    expect(find.text('Payment request is invalid'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

Future<void> _pumpWithProviders(
  WidgetTester tester, {
  required Widget home,
  SessionRepository? sessionRepository,
}) async {
  final resolvedSessionRepository = sessionRepository ?? SessionRepository();
  if (sessionRepository == null) {
    addTearDown(resolvedSessionRepository.dispose);
  }

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>.value(value: _FakeUserRepository()),
        RepositoryProvider<SessionRepository>.value(value: resolvedSessionRepository),
      ],
      child: MaterialApp(home: home),
    ),
  );

  await tester.pumpAndSettle();
}

class _FakeUserRepository extends UserRepository {
  @override
  Future<UserModel?> getUser() async => null;
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
    throw RepositoryHttpException(statusCode: 422, message: 'Invalid filters for orders');
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
    throw RepositoryHttpException(statusCode: 422, message: 'Favourite list request is invalid');
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
  Future<List<Map<String, dynamic>>> fetchSavedCards({required UserModel? userModel}) async {
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
  Future<List<Map<String, dynamic>>> fetchSavedCards({required UserModel? userModel}) async {
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
    throw RepositoryHttpException(statusCode: 422, message: 'Payment request is invalid');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavedCards({required UserModel? userModel}) async {
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
  Future<List<Map<String, dynamic>>> fetchSavedCards({required UserModel? userModel}) async {
    return const [];
  }
}
