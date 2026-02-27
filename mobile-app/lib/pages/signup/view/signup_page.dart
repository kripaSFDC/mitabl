import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/pages/login/cubit/login_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/route_arguement.dart';
import '../cubit/sign_up_cubit.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    Key? key,
  }) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) =>
                  SignUpCubit(context.read<AuthenticationRepository>()),
              child: SignupPage(),
            ));
    // );
  }

  @override
  State<StatefulWidget> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> with TickerProviderStateMixin {
  // final RouteArguements? routeArguements;

  // int breakPointWidth = 500;

  _SignupPage();

  @override
  void initState() {
    // setUpFields();
    super.initState();
  }

  TextEditingController? mobileNoTextEditor = TextEditingController();
  TextEditingController? passwordTextEditor = TextEditingController();

  @override
  Widget build(BuildContext context) {
    timeDilation = 0.4;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<SignUpCubit, SignUpState>(builder: (context, state) {
          return Stack(
            children: [
              Container(
                alignment: Alignment.center,
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
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            Column(
                              children: [
                                Image.asset(
                                  'assets/img/logo.png',
                                  fit: BoxFit.contain,
                                  height:
                                      config.AppConfig(context).appHeight(15),
                                  width: config.AppConfig(context).appWidth(70),
                                ),
                                SizedBox(
                                  height:
                                      config.AppConfig(context).appHeight(2),
                                ),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: 30,
                                      fontWeight: config.FontFamily().demi),
                                ),
                                SizedBox(
                                  height:
                                      config.AppConfig(context).appHeight(1),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(4),
                            ),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(
                                            left: config.AppConfig(context)
                                                .appWidth(1.0)),
                                        child: Text(
                                          'Sign up as',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                              fontSize: 18,
                                              fontWeight:
                                                  config.FontFamily().book),
                                        ),
                                      ),
                                      SizedBox(
                                        height: config.AppConfig(context)
                                            .appHeight(1),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: InkWell(
                                              onTap: () {
                                                context
                                                    .read<SignUpCubit>()
                                                    .onRoleChanged(
                                                        role:
                                                            AppConstants.FOODI);
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: config.AppColors()
                                                      .textFieldBackgroundColor(
                                                          1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      config.AppConfig(context)
                                                          .appWidth(2)),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Image.asset(
                                                              'assets/img/foodi.png',
                                                              height: config
                                                                      .AppConfig(
                                                                          context)
                                                                  .appHeight(3),
                                                              width: config
                                                                      .AppConfig(
                                                                          context)
                                                                  .appHeight(3),
                                                              fit: BoxFit
                                                                  .fitHeight,
                                                            ),
                                                            Text(
                                                              'mifoodi',
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColorDark,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      config.FontFamily()
                                                                          .book),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: config.AppConfig(
                                                                context)
                                                            .appWidth(3),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child:
                                                            state.selectedRole ==
                                                                    AppConstants
                                                                        .FOODI
                                                                ? Container(
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Theme.of(context)
                                                                            .primaryColor),
                                                                    child: Icon(
                                                                      Icons
                                                                          .done,
                                                                      color: Colors
                                                                          .white,
                                                                      size: config.AppConfig(
                                                                              context)
                                                                          .appWidth(
                                                                              5),
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .circle,
                                                                    color: Colors
                                                                        .white,
                                                                    size: config.AppConfig(
                                                                            context)
                                                                        .appWidth(
                                                                            5),
                                                                  ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: config.AppConfig(context)
                                                .appWidth(2),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: InkWell(
                                              onTap: () {
                                                context
                                                    .read<SignUpCubit>()
                                                    .onRoleChanged(
                                                        role:
                                                            AppConstants.COOK);
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: config.AppColors()
                                                      .textFieldBackgroundColor(
                                                          1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      config.AppConfig(context)
                                                          .appWidth(2)),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Image.asset(
                                                              'assets/img/cook.png',
                                                              height: config
                                                                      .AppConfig(
                                                                          context)
                                                                  .appHeight(3),
                                                              width: config
                                                                      .AppConfig(
                                                                          context)
                                                                  .appHeight(3),
                                                              fit: BoxFit
                                                                  .fitHeight,
                                                            ),
                                                            Text(
                                                              'micook',
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColorDark,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      config.FontFamily()
                                                                          .book),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: config.AppConfig(
                                                                context)
                                                            .appWidth(3),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child:
                                                            state.selectedRole ==
                                                                    AppConstants
                                                                        .COOK
                                                                ? Container(
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Theme.of(context)
                                                                            .primaryColor),
                                                                    child: Icon(
                                                                      Icons
                                                                          .done,
                                                                      color: Colors
                                                                          .white,
                                                                      size: config.AppConfig(
                                                                              context)
                                                                          .appWidth(
                                                                              5),
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .circle,
                                                                    color: Colors
                                                                        .white,
                                                                    size: config.AppConfig(
                                                                            context)
                                                                        .appWidth(
                                                                            5),
                                                                  ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  _FirstName(
                                    loginForm: this,
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  _LastName(
                                    loginForm: this,
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  _Email(
                                    loginForm: this,
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  _PhoneNo(
                                    loginForm: this,
                                  ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: TextFormField(
                                      // controller: widget.loginForm!.mobileNoTextEditor,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.name,
                                      maxLength: 55,
                                      onChanged: (text) {
                                        context
                                            .read<SignUpCubit>()
                                            .onAddressChanged(value: text);
                                      },
                                      decoration: InputDecoration(
                                        counterText: '',
                                        errorText: state.address!.invalid
                                            ? 'Please enter a valid address'
                                            : null,

                                        hintStyle: TextStyle(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 16,
                                            fontWeight:
                                                config.FontFamily().book),
                                        // labelText: 'Mobile Number',
                                        hintText: 'Address',

                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal:
                                                config.AppConfig(context)
                                                    .appWidth(5),
                                            vertical: config.AppConfig(context)
                                                .appWidth(3)),
                                        fillColor: config.AppColors()
                                            .textFieldBackgroundColor(1),
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),

                                  Container(
                                    child: TextFormField(
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      obscureText: state.showPassword,
                                      textInputAction: TextInputAction.next,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      onChanged: (text) {
                                        context
                                            .read<SignUpCubit>()
                                            .onPasswordChanged(value: text);
                                        context
                                            .read<SignUpCubit>()
                                            .onConfirmPasswordChanged(context
                                                .read<SignUpCubit>()
                                                .state
                                                .confirmPassword
                                                .value['confirmPassword']);
                                      },
                                      maxLength: 50,
                                      decoration: InputDecoration(
                                        errorText: state.password.invalid
                                            ? 'Please enter a valid password'
                                            : null,
                                        counterText: '',
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            context
                                                .read<SignUpCubit>()
                                                .showPassword();
                                          },
                                          color: Colors.white,
                                          icon: Icon(
                                            !state.showPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                        ),
                                        hintStyle: TextStyle(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 16,
                                            fontWeight:
                                                config.FontFamily().book),
                                        hintText: 'Password',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal:
                                                config.AppConfig(context)
                                                    .appWidth(5),
                                            vertical: config.AppConfig(context)
                                                .appWidth(3)),
                                        fillColor: config.AppColors()
                                            .textFieldBackgroundColor(1),
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),

                                  Container(
                                    child: TextFormField(
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      obscureText: state.showConfirmPassword,
                                      textInputAction: TextInputAction.next,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      onChanged: (text) {
                                        context
                                            .read<SignUpCubit>()
                                            .onConfirmPasswordChanged(text);
                                      },
                                      maxLength: 50,
                                      decoration: InputDecoration(
                                        errorText: state.confirmPassword.invalid
                                            ? 'Please enter a valid password'
                                            : null,
                                        counterText: '',
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            context
                                                .read<SignUpCubit>()
                                                .showConfirmPassword();
                                          },
                                          color: Colors.white,
                                          icon: Icon(
                                            !state.showConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                        ),
                                        hintStyle: TextStyle(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 16,
                                            fontWeight:
                                                config.FontFamily().book),
                                        hintText: 'Confirm Password',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal:
                                                config.AppConfig(context)
                                                    .appWidth(5),
                                            vertical: config.AppConfig(context)
                                                .appWidth(3)),
                                        fillColor: config.AppColors()
                                            .textFieldBackgroundColor(1),
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(2),
                                  ),
                                  // Text(
                                  //   ' Forgot password?',
                                  //   style: GoogleFonts.gothicA1(
                                  //       fontSize: config.AppConfig(context)
                                  //           .appHeight(2),
                                  //       color: Theme.of(context).primaryColor),
                                  // ),
                                  SizedBox(
                                    height:
                                        config.AppConfig(context).appHeight(3),
                                  ),
                                  _LoginButton(
                                    loginForm: this,
                                  ),
                                  SizedBox(
                                    height: config.AppConfig(context)
                                        .appHeight(4.5),
                                  ),
                                ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              state.statusApi!.isSubmissionInProgress
                  ? CommonProgressWidget()
                  : SizedBox(),
            ],
          );
        }, listener: (context, state) async {
          if (state.statusApi!.isSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${state.serverMessage}')));
          }
        }),
      ),
    );
  }
}

class _Email extends StatefulWidget {
  final _SignupPage? loginForm;

  const _Email({Key? key, this.loginForm}) : super(key: key);

  @override
  State<_Email> createState() => _EmailState();
}

class _EmailState extends State<_Email> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      print('constraibtWidth ${constraint.maxWidth}');
      return BlocBuilder<SignUpCubit, SignUpState>(builder: (context, state) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: widget.loginForm!.mobileNoTextEditor,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            maxLength: 55,
            onChanged: (text) {
              context.read<SignUpCubit>().onEmailChanged(value: text);
            },
            decoration: InputDecoration(
              counterText: '',
              errorText:
                  state.email!.invalid ? 'Please enter a valid email id' : null,

              suffixIcon: state.email!.valid
                  ? Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).primaryColor,
                    )
                  : SizedBox(),
              hintStyle: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  fontWeight: config.FontFamily().book),
              // labelText: 'Mobile Number',
              hintText: 'Email Address',
              contentPadding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(5),
                  vertical: config.AppConfig(context).appWidth(3)),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white,
                ),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
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

class _FirstName extends StatefulWidget {
  final _SignupPage? loginForm;

  const _FirstName({Key? key, this.loginForm}) : super(key: key);

  @override
  State<_FirstName> createState() => _FirstNameState();
}

class _FirstNameState extends State<_FirstName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          // controller: widget.loginForm!.mobileNoTextEditor,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 20,
          onChanged: (text) {
            context.read<SignUpCubit>().onFirstNameChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: state.nameFirst!.invalid
                ? 'Please enter a valid first name'
                : null,

            // suffixIcon: state.email!.valid
            //     ? Icon(
            //   Icons.check_circle_outline,
            //   color: Theme.of(context).primaryColor,
            // )
            //     : SizedBox(),
            hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: config.FontFamily().book),
            // labelText: 'Mobile Number',
            hintText: 'First Name',
            contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(3)),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LastName extends StatefulWidget {
  final _SignupPage? loginForm;

  const _LastName({Key? key, this.loginForm}) : super(key: key);

  @override
  State<_LastName> createState() => _LastNameState();
}

class _LastNameState extends State<_LastName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          // controller: widget.loginForm!.mobileNoTextEditor,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 20,
          onChanged: (text) {
            context.read<SignUpCubit>().onLastNameChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: state.nameLast!.invalid
                ? 'Please enter a valid last name'
                : null,

            // suffixIcon: state.email!.valid
            //     ? Icon(
            //   Icons.check_circle_outline,
            //   color: Theme.of(context).primaryColor,
            // )
            //     : SizedBox(),
            hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: config.FontFamily().book),
            // labelText: 'Mobile Number',
            hintText: 'Last Name',
            contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(3)),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _PhoneNo extends StatefulWidget {
  final _SignupPage? loginForm;

  const _PhoneNo({Key? key, this.loginForm}) : super(key: key);

  @override
  State<_PhoneNo> createState() => _PhoneNoState();
}

class _PhoneNoState extends State<_PhoneNo> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          // controller: widget.loginForm!.mobileNoTextEditor,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          maxLength: 14,
          onChanged: (text) {
            context.read<SignUpCubit>().onPhoneChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText:
                state.phone.invalid ? 'Please enter a valid phone no' : null,
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                  left: config.AppConfig(context).appWidth(4.0),
                  right: config.AppConfig(context).appWidth(3.0)),
              child: Text(
                '+61',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: config.FontFamily().book,
                    color: Theme.of(context).hintColor),
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: config.FontFamily().book),
            // labelText: 'Mobile Number',
            hintText: 'Phone',
            contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(3)),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LoginButton extends StatelessWidget {
  final _SignupPage? loginForm;

  const _LoginButton({Key? key, this.loginForm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listener: (context, state) {},
      builder: (context, state) {
        return state.status!.isSubmissionInProgress
            ? const CircularProgressIndicator()
            : Container(
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
                              Theme.of(context).primaryColorLight,
                              Theme.of(context).primaryColorLight,
                            ],
                    )),
                child: MaterialButton(
                    child: Text(
                      'NEXT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: config.FontFamily().book),
                    ),
                    minWidth: config.AppConfig(context).appWidth(100),
                    height: 50.0,
                    onPressed: () {
                      // navigatorKey.currentState!.popAndPushNamed('/OTPPage',
                      //     arguments: RouteArguments(
                      //         id: '1',
                      //         role: 1));
                      if (state.status!.isValidated) {
                        context.read<SignUpCubit>().onSignUp();
                      }
                    }),
              );
      },
    );
  }
}
