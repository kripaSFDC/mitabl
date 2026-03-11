import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/app.dart';
import 'package:mitabl_user/helper/app_bloc_observer.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/auth_aware_http_client.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('configuration');
  GoogleFonts.config.allowRuntimeFetching = false;
  Bloc.observer = AppBlocObserver();

  final sessionRepository = SessionRepository();
  final sharedHttpClient = AuthAwareHttpClient(
    inner: http.Client(),
    sessionRepository: sessionRepository,
  );
  final userRepository = UserRepository(httpClient: sharedHttpClient);
  sessionRepository.attachUserRepository(userRepository);

  runApp(App(
      authenticationRepository: AuthenticationRepository(
        httpClient: sharedHttpClient,
        userRepository: userRepository,
        sessionRepository: sessionRepository,
      ),
      userRepository: userRepository,
      sessionRepository: sessionRepository));
}
