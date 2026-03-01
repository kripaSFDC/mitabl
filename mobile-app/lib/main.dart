import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/app.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('configuration');

  final sharedHttpClient = http.Client();
  final userRepository = UserRepository(httpClient: sharedHttpClient);

  runApp(App(
      authenticationRepository: AuthenticationRepository(
        httpClient: sharedHttpClient,
        userRepository: userRepository,
      ),
      userRepository: userRepository));
}
