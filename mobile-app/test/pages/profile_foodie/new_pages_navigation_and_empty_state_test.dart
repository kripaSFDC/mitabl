import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/pages/favourites/view/favourites_page.dart';
import 'package:mitabl_user/pages/miorders/view/miorders_page.dart';
import 'package:mitabl_user/pages/payments/view/payments_page.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/pages/profile_foodie/view/profile_foodie_page.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/model/user_model.dart';
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

  testWidgets('miorders page renders empty state with no records', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<UserRepository>.value(
        value: _FakeUserRepository(),
        child: MaterialApp(
          home: MiOrdersPage(repository: _FakeMiOrdersRepository()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No data found'), findsOneWidget);
  });

  testWidgets('favourites page renders empty state with no records', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<UserRepository>.value(
        value: _FakeUserRepository(),
        child: MaterialApp(
          home: FavouritesPage(repository: _FakeFavouritesRepository()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No data found'), findsOneWidget);
  });

  testWidgets('payments page renders empty state with no records', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<UserRepository>.value(
        value: _FakeUserRepository(),
        child: MaterialApp(
          home: PaymentsPage(repository: _FakePaymentsRepository()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No data found'), findsOneWidget);
  });
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
