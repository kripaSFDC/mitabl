import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/app.dart';
import 'package:mitabl_user/firebase_options.dart';
import 'package:mitabl_user/helper/app_bloc_observer.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/notification_service.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/auth_aware_http_client.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('configuration');
  // GothicA1 is used through google_fonts across many screens but is not
  // bundled in assets. Allow runtime fetching to avoid hard crashes.
  GoogleFonts.config.allowRuntimeFetching = true;
  Bloc.observer = AppBlocObserver();

  // Firebase: requires google-services.json (Android) and
  // GoogleService-Info.plist (iOS) — run `flutterfire configure` first.
  // If Firebase options are not configured, keep the app functional and
  // continue without push notifications.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    firebaseReady = true;
  } catch (error) {
    AppLogger.warn(
      'Firebase initialization skipped. Push notifications disabled: $error',
    );
  }

  if (!firebaseReady) {
    AppLogger.warn(
      'App started without Firebase configuration files. '
      'Run flutterfire configure for production push notifications.',
    );
  }

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
