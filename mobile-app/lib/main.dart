import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/app.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('configuration');

  runApp(App(
      authenticationRepository: AuthenticationRepository(),
      userRepository: UserRepository()));
}
