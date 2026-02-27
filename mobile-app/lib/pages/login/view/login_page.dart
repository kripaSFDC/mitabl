import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mitabl_user/pages/login/cubit/login_cubit.dart' as cubit;
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages/login/view/login_form.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class LoginPage extends StatelessWidget {
  // final RouteArguements? routeArguements;

  LoginPage({Key? key /*, this.routeArguements*/
      })
      : super(key: key);

  static Route route(/*{RouteArguements? routeArguements}*/) {
    return MaterialPageRoute<void>(
        builder:
            (_) => /*BlocProvider(

      //
        create: (context) {
          return cubit.LoginCubit(authenticationRepository: context.read<AuthenticationRepository>());
        },
        child:*/
                BlocProvider(
                  create: (context) => cubit.LoginCubit(
                      authenticationRepository:
                          context.read<AuthenticationRepository>(),
                      userRepository: context.read<UserRepository>()),
                  child: LoginPage(/*routeArguements: routeArguements,*/),
                ));
    // );
  }

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        body: BlocConsumer<cubit.LoginCubit, cubit.LoginState>(
            builder: (context, state) {
              return const LoginForm();
            },
            listener: (context, state) {}),
      ),
    );
  }
}
