import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/model/international_phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

import '../cubit/sign_up_cubit.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) =>
            SignUpCubit(context.read<AuthenticationRepository>()),
        child: const SignupPage(),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> {
  final _countryCodeController = TextEditingController(text: '+61');
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill hidden fields with valid placeholders so Formz.validate() passes.
    // Address is only required for kitchen activation, not basic signup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SignUpCubit>();
      cubit.onLastNameChanged(value: '.');
      cubit.onAddressChanged(value: '.');
    });
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFullNameChanged(String fullName) {
    final cubit = context.read<SignUpCubit>();
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      cubit.onFirstNameChanged(value: parts.first);
      cubit.onLastNameChanged(value: parts.sublist(1).join(' '));
    } else {
      cubit.onFirstNameChanged(value: fullName);
      cubit.onLastNameChanged(value: fullName.isNotEmpty ? '.' : '');
    }
  }

  void _onPasswordChanged(String password) {
    final cubit = context.read<SignUpCubit>();
    cubit.onPasswordChanged(value: password);
    cubit.onConfirmPasswordChanged(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<SignUpCubit, SignUpState>(
        listener: (context, state) {
          if (state.statusApi!.isSubmissionFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.serverMessage),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Decorative blurs
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color:
                        MitablColors.secondaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color:
                        MitablColors.primaryContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back,
                              color: MitablColors.primary,
                              size: 24,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Mitabl',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                                color: MitablColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24), // Spacer for centering
                        ],
                      ),
                    ),

                    // Scrollable form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),

                            // Heading
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.onSurface,
                                  height: 1.15,
                                ),
                                children: [
                                  TextSpan(text: 'Pull up a '),
                                  TextSpan(
                                    text: 'chair',
                                    style: TextStyle(
                                      color: MitablColors.primary,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              'Join our community of home cooks and\nculinary enthusiasts. Your place at the\ntable is waiting.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Form Card
                            Container(
                              decoration: BoxDecoration(
                                color: MitablColors.surfaceContainerLowest,
                                borderRadius: MitablRadius.cardBorder,
                                boxShadow: [
                                  BoxShadow(
                                    color: MitablColors.onSurface
                                        .withValues(alpha: 0.04),
                                    blurRadius: 40,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Full Name
                                  MitablTextField(
                                    label: 'FULL NAME',
                                    hint: 'Jamie Oliver',
                                    prefixIcon: Icon(
                                      Icons.person_outlined,
                                      color: MitablColors.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.name,
                                    onChanged: _onFullNameChanged,
                                    errorText:
                                        (state.nameFirst != null && !state.nameFirst!.isPure && state.nameFirst!.isNotValid)
                                            ? 'Please enter your name'
                                            : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Email or Phone
                                  MitablTextField(
                                    label: 'EMAIL OR PHONE',
                                    hint: 'chef@mitabl.com',
                                    prefixIcon: Icon(
                                      Icons.contact_mail_outlined,
                                      color: MitablColors.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) {
                                      context
                                          .read<SignUpCubit>()
                                          .onEmailChanged(value: value);
                                    },
                                    errorText:
                                        (state.email != null && !state.email!.isPure && state.email!.isNotValid)
                                            ? 'Please enter a valid email'
                                            : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Phone number (needed for OTP)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 88,
                                        child: MitablTextField(
                                          controller: _countryCodeController,
                                          label: 'CODE',
                                          hint: '+61',
                                          keyboardType: TextInputType.phone,
                                          textInputAction:
                                              TextInputAction.next,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9+]'),
                                            ),
                                            LengthLimitingTextInputFormatter(
                                                5),
                                          ],
                                          onChanged: (value) {
                                            context
                                                .read<SignUpCubit>()
                                                .onCountryCodeChanged(
                                                  value: value,
                                                  localNumber:
                                                      _phoneController.text,
                                                );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: MitablTextField(
                                          controller: _phoneController,
                                          label: 'PHONE NUMBER',
                                          hint: '400 000 000',
                                          keyboardType: TextInputType.phone,
                                          textInputAction:
                                              TextInputAction.next,
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                            color: MitablColors
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                            size: 22,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                                14),
                                          ],
                                          onChanged: (text) {
                                            context
                                                .read<SignUpCubit>()
                                                .onPhoneChanged(
                                                  value: InternationalPhone
                                                      .compose(
                                                    countryCode:
                                                        _countryCodeController
                                                            .text,
                                                    number: text,
                                                  ),
                                                );
                                          },
                                          errorText: (!state.phone.isPure &&
                                                  state.phone.isNotValid)
                                              ? 'Enter a valid phone number'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Password
                                  MitablTextField(
                                    label: 'PASSWORD',
                                    hint: '••••••••',
                                    prefixIcon: Icon(
                                      Icons.lock_outlined,
                                      color: MitablColors.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    obscureText: state.showPassword,
                                    textInputAction: TextInputAction.done,
                                    keyboardType:
                                        TextInputType.visiblePassword,
                                    suffixIcon: IconButton(
                                      onPressed: () => context
                                          .read<SignUpCubit>()
                                          .showPassword(),
                                      icon: Icon(
                                        !state.showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: MitablColors.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                    ),
                                    onChanged: _onPasswordChanged,
                                    errorText: (!state.password.isPure && state.password.isNotValid)
                                        ? 'Min 6 characters required'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),

                                  // Create Account button
                                  MitablButton(
                                    label: 'Create Account',
                                    icon: const Icon(
                                      Icons.restaurant_menu,
                                      color: MitablColors.onPrimary,
                                      size: 20,
                                    ),
                                    isLoading: state
                                        .statusApi!.isSubmissionInProgress,
                                    // Check the 4 visible fields — hidden
                                    // fields (address, lastName) are
                                    // pre-filled with valid placeholders.
                                    onPressed: (state.nameFirst != null &&
                                            state.nameFirst!.isValid &&
                                            state.email != null &&
                                            state.email!.isValid &&
                                            state.phone.isValid &&
                                            state.password.isValid)
                                        ? () => context
                                            .read<SignUpCubit>()
                                            .onSignUp()
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Or join with divider
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
                                    'Or join with',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                            const SizedBox(height: 16),

                            // Social login buttons (2-column)
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    iconColor: MitablColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.facebook_rounded,
                                    label: 'Facebook',
                                    iconColor: const Color(0xFF1877F2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already part of the kitchen? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => navigatorKey.currentState!
                                      .pushNamed('/LoginPage'),
                                  child: const Text(
                                    'Log in here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Terms footer
                            Text(
                              'BY CREATING AN ACCOUNT, YOU AGREE TO MITABL\'S\nTERMS OF SERVICE AND PRIVACY POLICY.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (state.statusApi!.isSubmissionInProgress)
                const CommonProgressWidget(),
            ],
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label sign-in coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

