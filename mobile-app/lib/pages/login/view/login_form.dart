import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/pages/login/cubit/login_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class LoginForm extends StatefulWidget {
  // final RouteArguements? routeArguements;

  const LoginForm({
    super.key,
    /*this.routeArguements*/
  });

  @override
  State<StatefulWidget> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> with TickerProviderStateMixin {
  // final RouteArguements? routeArguements;

  // int breakPointWidth = 500;

  _LoginForm();

  @override
  void initState() {
    super.initState();
  }

  TextEditingController? mobileNoTextEditor = TextEditingController();
  TextEditingController? passwordTextEditor = TextEditingController();

  @override
  void dispose() {
    mobileNoTextEditor?.dispose();
    passwordTextEditor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return BlocConsumer<LoginCubit, LoginState>(builder: (context, state) {
      return Stack(
        children: [
          Container(
            color: Colors.white,
            height: config.AppConfig(context).appHeight(100),
            width: config.AppConfig(context).appWidth(100),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    top: config.AppConfig(context).appHeight(2),
                    left: config.AppConfig(context).appWidth(5),
                    right: config.AppConfig(context).appWidth(5)),
                child: Container(
                  alignment: Alignment.center,
                  width: config.AppConfig(context).appWidth(90),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () {
                              navigatorKey.currentState!.pop();
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Theme.of(context).primaryColorDark,
                              size: config.AppConfig(context).appWidth(5),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(10),
                        ),
                        Column(
                          children: [
                            Image.asset(
                              'assets/img/logo.png',
                              fit: BoxFit.contain,
                              height: config.AppConfig(context).appHeight(15),
                              width: config.AppConfig(context).appWidth(70),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2.5),
                            ),
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                  fontSize: 30,
                                  fontWeight: config.FontFamily().demi),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(1),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(8),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MobilePhone(
                                loginForm: this,
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(2),
                              ),
                              _Password(
                                loginForm: this,
                              ),
                              SizedBox(
                                height:
                                    config.AppConfig(context).appHeight(0.5),
                              ),
                              InkWell(
                                onTap: () => navigatorKey.currentState!
                                    .pushNamed('/ForgotPage'),
                                child: Container(
                                  padding: EdgeInsets.only(
                                      left: config.AppConfig(context)
                                          .appWidth(4.0)),
                                  child: Text(
                                    ' Forgot password?',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: config.FontFamily().medium),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(3),
                              ),
                              _LoginButton(
                                loginForm: this,
                              ),
                              SizedBox(
                                height:
                                    config.AppConfig(context).appHeight(4.5),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          state.apiStatus.isSubmissionInProgress
              ? const CommonProgressWidget()
              : const SizedBox(),
        ],
      );
    }, listener: (context, state) async {
      if (state.apiStatus.isSubmissionFailure) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.serverMessage)));
      } else if (state.apiStatus.isSubmissionSuccess) {
        // Fallback redirect: keep login UX responsive even if global auth
        // listener misses a single state transition.
        final user = await context.read<UserRepository>().getUser();
        final role = user?.data?.user?.role;
        final routeName = AppConstants.isCookRole(role)
            ? '/DashboardCook'
            : '/HomePage';
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(routeName, (route) => false);
      }
    });
  }
}

class _MobilePhone extends StatefulWidget {
  final _LoginForm? loginForm;

  const _MobilePhone({this.loginForm});

  @override
  State<_MobilePhone> createState() => _MobilePhoneState();
}

class _MobilePhoneState extends State<_MobilePhone> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return BlocBuilder<LoginCubit, LoginState>(builder: (context, state) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: widget.loginForm!.mobileNoTextEditor,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            maxLength: 55,
            onChanged: (text) {
              context.read<LoginCubit>().onEmailChanged(value: text);
            },
            decoration: InputDecoration(
              counterText: '',
              errorText:
                  state.email.invalid ? 'Please enter a valid email id' : null,
              suffixIcon: state.email.valid
                  ? Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).primaryColor,
                    )
                  : const SizedBox(),
              hintStyle: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  fontWeight: config.FontFamily().book),
              // labelText: 'Mobile Number',
              hintText: 'Username',
              contentPadding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(5),
                  vertical: config.AppConfig(context).appWidth(3)),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      });
    });
  }
}

class _Password extends StatefulWidget {
  final _LoginForm? loginForm;

  const _Password({this.loginForm});

  @override
  State<_Password> createState() => _PasswordState();
}

class _PasswordState extends State<_Password> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return BlocBuilder<LoginCubit, LoginState>(builder: (context, state) {
        return TextFormField(
            controller: widget.loginForm!.passwordTextEditor,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            obscureText: state.showPassword,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.visiblePassword,
            onChanged: (text) {
              context.read<LoginCubit>().onPasswordChanged(value: text);
            },
            maxLength: 50,
            decoration: InputDecoration(
              errorText: state.password.invalid
                  ? 'Please enter a valid password'
                  : null,
              counterText: '',
              suffixIcon: IconButton(
                onPressed: () {
                  context.read<LoginCubit>().showPassword();
                },
                color: Colors.white,
                icon: Icon(
                  !state.showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
              hintStyle: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  fontWeight: config.FontFamily().book),
              hintText: 'Password',
              contentPadding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(5),
                  vertical: config.AppConfig(context).appWidth(3)),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              border: InputBorder.none,
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
            ),
          );
      });
    });
  }
}

class _LoginButton extends StatelessWidget {
  final _LoginForm? loginForm;

  const _LoginButton({this.loginForm});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: state.status.isValidated
                    ? [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor,
                      ]
                    : [
                        Theme.of(context).primaryColorLight,
                        Theme.of(context).primaryColorLight,
                      ],
              )),
          child: MaterialButton(
              height: config.AppConfig(context).appHeight(6),
              minWidth: config.AppConfig(context).appWidth(100),
              onPressed: () {
                if (state.status.isValidated) {
                  context.read<LoginCubit>().doLogin();
                }
              },
              child: Text(
                'LOGIN',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: config.FontFamily().book),
              )),
        );
      },
    );
  }
}
