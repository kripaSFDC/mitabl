import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mitabl_user/pages/login/cubit/login_cubit.dart' as cubit;
import 'package:mitabl_user/pages/login/view/login_form.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => cubit.LoginCubit(
          authRepository: context.read<AuthenticationRepository>(),
          repo: context.read<UserRepository>(),
        ),
        child: LoginPage(),
      ),
    );
  }

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: MitablColors.surface,
        body: BlocConsumer<cubit.LoginCubit, cubit.LoginState>(
          builder: (context, state) {
            return const LoginForm();
          },
          listener: (context, state) {},
        ),
      ),
    );
  }
}
