import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../model/user_model.dart';
import '../../repos/user_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    required UserRepository userRepository,
  })  : assert(authenticationRepository != null),
        assert(userRepository != null),
        _authenticationRepository = authenticationRepository,
        _userRepository = userRepository,
        super(const AuthenticationState.unknown()) {
    on<AuthenticationStatusChanged>(mapAuthenticationStatusChangedToState);
    _authenticationStatusSubscription =
        _authenticationRepository.status.listen((status) {
      print('status_check ');
      add(AuthenticationStatusChanged(status));
    });
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;
  StreamSubscription<AuthenticationStatus>? _authenticationStatusSubscription;

  /* @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is AuthenticationStatusChanged) {
      print('AuthenticationStatusChanged');

      // yield await _mapAuthenticationStatusChangedToState(event);
    } else if (event is AuthenticationLogoutRequested) {
      _authenticationRepository.logOut();
    } else if (event is GetVersionInfo) {
      yield* mapGetVersionInfo(event);
    }
  }*/

  Stream<AuthenticationState> mapGetVersionInfo(GetVersionInfo event) async* {
    // var response =await _authenticationRepository.getVersionInfo();
    // if(!response!.error!){
    //
    // }
  }

  @override
  Future<void> close() {
    _authenticationStatusSubscription?.cancel();
    _authenticationRepository.dispose();
    return super.close();
  }

  void statusChanged() {
    print("vvdgv");
  }

  mapAuthenticationStatusChangedToState(AuthenticationStatusChanged event,
      Emitter<AuthenticationState> emit) async {
    print('uwiueeiuw ${event.status}');

    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        print('unauthCase');
        return emit(const AuthenticationState.unauthenticated());

      case AuthenticationStatus.authenticated:
        // return emit(AuthenticationState.authenticated(UserModel()));
        final user = await _tryGetUser();

        return user != null
            ? emit(AuthenticationState.authenticated(user))
            : emit(const AuthenticationState.unauthenticated());

      default:
        return emit(const AuthenticationState.unknown());
    }
  }

  Future<UserModel?> _tryGetUser() async {
    try {
      final user = await _userRepository.getUser();
      return user;
    } on Exception {
      return null;
    }
  }
}
