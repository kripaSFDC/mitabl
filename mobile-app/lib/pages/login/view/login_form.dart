import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/pages/login/cubit/login_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

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
            // ── Background decorative blurs ──
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.1,
              right: -MediaQuery.of(context).size.width * 0.05,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: MitablColors.secondaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.05,
              left: -MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  // ── Header: centered "Mitabl" logo ──
                  ClipRect(
                    child: BackdropFilter(
                      filter: MitablGlass.blur,
                      child: Container(
                        color: MitablGlass.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        alignment: Alignment.center,
                        child: const Text(
                          'mitabl',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: MitablColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Scrollable form body ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Content Header ──
                              const Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sign in to your culinary atelier',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // ── Email / Phone Field ──
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: mobileNoTextEditor,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'chef@mitabl.com',
                                  hintStyle: TextStyle(
                                    color: MitablColors.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                    fontFamily: 'DM Sans',
                                  ),
                                  filled: true,
                                  fillColor: MitablColors.surfaceContainerLow,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: MitablColors.primary
                                          .withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  errorText: state.email.invalid
                                      ? 'Please enter a valid email id'
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                                onChanged: (text) {
                                  context
                                      .read<LoginCubit>()
                                      .onEmailChanged(value: text);
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Password Field ──
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 4, right: 4, bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => navigatorKey.currentState!
                                          .pushNamed('/ForgotPage'),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'DM Sans',
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextFormField(
                                controller: passwordTextEditor,
                                obscureText: state.showPassword,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                                  hintStyle: TextStyle(
                                    color: MitablColors.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                    fontFamily: 'DM Sans',
                                  ),
                                  filled: true,
                                  fillColor: MitablColors.surfaceContainerLow,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: MitablColors.primary
                                          .withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  errorText: state.password.invalid
                                      ? 'Please enter a valid password'
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                                onChanged: (text) {
                                  context
                                      .read<LoginCubit>()
                                      .onPasswordChanged(value: text);
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── Login Button ──
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: state.status.isValidated
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            MitablColors.primary,
                                            MitablColors.primaryContainer,
                                          ],
                                        )
                                      : null,
                                  color: state.status.isValidated
                                      ? null
                                      : MitablColors.tertiaryFixedDim,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: state.status.isValidated
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEA580C)
                                                .withValues(alpha: 0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: state.status.isValidated
                                        ? () {
                                            context
                                                .read<LoginCubit>()
                                                .doLogin();
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(100),
                                    child: Center(
                                      child: state
                                              .apiStatus.isSubmissionInProgress
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'DM Sans',
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // ── "Or continue with" divider ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'Or continue with',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Social Login Buttons (3-col grid) ──
                              const Row(
                                children: [
                                  Expanded(
                                    child: _SocialLoginTile(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Google',
                                      iconSize: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _SocialLoginTile(
                                      icon: Icons.apple,
                                      label: 'Apple',
                                      iconSize: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _SocialLoginTile(
                                      icon: Icons.facebook_rounded,
                                      label: 'Facebook',
                                      iconSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Social sign-in will be available in a future release.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // ── Sign up link ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'DM Sans',
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => navigatorKey.currentState!
                                        .pushNamed('/SignUpPage'),
                                    child: const Text(
                                      'Join now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

/// A rounded-[20px] social login tile matching the HTML design.
class _SocialLoginTile extends StatelessWidget {
  const _SocialLoginTile({
    required this.icon,
    required this.label,
    this.iconSize = 24,
  });

  final IconData icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: MitablColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
