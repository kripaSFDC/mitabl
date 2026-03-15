import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/otp/cubit/otp_cubit.dart';

import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:pinput/pinput.dart';
import 'package:mitabl_user/helper/formz_compat.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => OtpCubit(
          context.read<AuthenticationRepository>(),
          context.read<UserRepository>(),
          routeArguments,
        ),
        child: const OTPPage(),
      ),
    );
    // );
  }

  @override
  State<StatefulWidget> createState() => _OTPPage();
}

class _OTPPage extends State<OTPPage> {
  // final RouteArguements? routeArguements;

  // int breakPointWidth = 500;

  _OTPPage();

  @override
  void initState() {
    // setUpFields();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<OtpCubit, OtpState>(
          listener: (context, state) {
            if (state.statusAPI!.isSubmissionFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${state.serverMessage}')));
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Container(
                  color: const Color(0xFFFFFBF7),
                  height: config.AppConfig(context).appHeight(100),
                  width: config.AppConfig(context).appWidth(100),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: config.AppConfig(context).appHeight(14),
                        left: config.AppConfig(context).appWidth(5),
                        right: config.AppConfig(context).appWidth(5),
                      ),
                      child: SizedBox(
                        width: config.AppConfig(context).appWidth(90),
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/img/logo.png',
                                    fit: BoxFit.contain,
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(15),
                                    width: config.AppConfig(
                                      context,
                                    ).appWidth(70),
                                  ),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  Text(
                                    'Verify Email',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: 30,
                                      fontWeight: config.FontFamily().demi,
                                    ),
                                  ),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(1),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(2),
                              ),
                              Text(
                                'We have sent a verification code \non your email ID.',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                  fontSize: 18,
                                  fontWeight: config.FontFamily().book,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(4),
                              ),
                              Pinput(
                                separatorBuilder: (index) =>
                                    const SizedBox(width: 10),
                                defaultPinTheme: PinTheme(
                                  width: config.AppConfig(context).appWidth(13),
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(7),
                                  textStyle: TextStyle(
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appHeight(3),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: BoxDecoration(
                                    color: config.AppColors()
                                        .textFieldBackgroundColor(1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                length: 4,
                                pinputAutovalidateMode:
                                    PinputAutovalidateMode.onSubmit,
                                showCursor: true,
                                onChanged: (value) {
                                  context.read<OtpCubit>().onOtpChanged(
                                    value: value,
                                  );
                                },
                                onCompleted: (pin) {},
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(4),
                              ),
                              const _SubmitButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                state.statusAPI!.isSubmissionInProgress
                    ? const CommonProgressWidget()
                    : const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpCubit, OtpState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: state.status!.isValidated
                  ? [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor,
                    ]
                  : [
                      const Color(0xFF9CA3AF),
                      const Color(0xFF9CA3AF),
                      // Theme.of(context).primaryColorLight,
                      // Theme.of(context).primaryColorLight,
                    ],
            ),
          ),
          child: MaterialButton(
            minWidth: config.AppConfig(context).appWidth(100),
            height: 50.0,
            onPressed: () {
              // navigatorKey.currentState!.popAndPushNamed('/CookProfile',
              //     arguments: RouteArguments(data: OTPResponse()));

              if (state.status!.isValidated) {
                context.read<OtpCubit>().onSubmitted();
              }
            },
            child: Text(
              'SUBMIT',
              style: TextStyle(
                color: const Color(0xFFFFFBF7),
                fontSize: 18,
                fontWeight: config.FontFamily().book,
              ),
            ),
          ),
        );
      },
    );
  }
}
