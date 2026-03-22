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
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:mitabl_user/pages/common/social_login_placeholder.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<StatefulWidget> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> with TickerProviderStateMixin {
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
    return BlocConsumer<LoginCubit, LoginState>(
      builder: (context, state) {
        return Stack(
          children: [
            // Background
            Container(
              color: MitablColors.surface,
              height: config.AppConfig(context).appHeight(100),
              width: config.AppConfig(context).appWidth(100),
            ),

            // Decorative blur circles
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MitablColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MitablColors.secondaryContainer.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom +
                    MediaQuery.of(context).viewInsets.bottom +
                    config.AppConfig(context).appHeight(3),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MitablSpacing.pagePadding + 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: config.AppConfig(context).appHeight(12),
                    ),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/img/logo.png',
                        fit: BoxFit.contain,
                        height: config.AppConfig(context).appHeight(10),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Welcome Back heading
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: MitablColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Sign in to your culinary atelier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email field
                    MitablTextField(
                      controller: mobileNoTextEditor,
                      label: 'Email',
                      hint: 'chef@mitabl.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: MitablColors.onSurfaceVariant,
                        size: 20,
                      ),
                      suffixIcon: state.email.valid
                          ? const Icon(
                              Icons.check_circle_outline,
                              color: MitablColors.accent,
                              size: 20,
                            )
                          : null,
                      errorText: state.email.invalid
                          ? 'Please enter a valid email id'
                          : null,
                      onChanged: (text) {
                        context.read<LoginCubit>().onEmailChanged(value: text);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    MitablTextField(
                      controller: passwordTextEditor,
                      label: 'Password',
                      hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                      obscureText: state.showPassword,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: MitablColors.onSurfaceVariant,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          context.read<LoginCubit>().showPassword();
                        },
                        icon: Icon(
                          !state.showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: MitablColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      errorText: state.password.invalid
                          ? 'Please enter a valid password'
                          : null,
                      onChanged: (text) {
                        context
                            .read<LoginCubit>()
                            .onPasswordChanged(value: text);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => navigatorKey.currentState!
                            .pushNamed('/ForgotPage'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: MitablColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    MitablButton(
                      label: 'Login',
                      isLoading: state.apiStatus.isSubmissionInProgress,
                      onPressed: state.status.isValidated
                          ? () {
                              context.read<LoginCubit>().doLogin();
                            }
                          : null,
                    ),

                    const SizedBox(height: 32),

                    // Or divider + social login
                    const OrDivider(),
                    const SizedBox(height: 20),
                    const SocialLoginRow(),

                    const SizedBox(height: 32),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigatorKey.currentState!
                              .pushNamed('/SignUpPage'),
                          child: const Text(
                            'Join now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (state.apiStatus.isSubmissionInProgress)
              const CommonProgressWidget(),
          ],
        );
      },
      listener: (context, state) async {
        if (state.apiStatus.isSubmissionFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.serverMessage)));
        } else if (state.apiStatus.isSubmissionSuccess) {
          // Fallback redirect: keep login UX responsive even if global auth
          // listener misses a single state transition.
          final user = await context.read<UserRepository>().getUser();
          final role = user?.data?.user?.role;
          final routeName =
              AppConstants.isCookRole(role) ? '/DashboardCook' : '/HomePage';
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            routeName,
            (route) => false,
          );
        }
      },
    );
  }
}
