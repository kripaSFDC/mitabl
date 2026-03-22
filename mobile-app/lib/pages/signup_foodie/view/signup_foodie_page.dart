import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/pages/common/social_login_placeholder.dart';
import 'package:mitabl_user/pages/signup/cubit/sign_up_cubit.dart';

class SignupFoodiePage extends StatefulWidget {
  const SignupFoodiePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) =>
            SignUpCubit(context.read<AuthenticationRepository>()),
        child: const SignupFoodiePage(),
      ),
    );
  }

  @override
  State<SignupFoodiePage> createState() => _SignupFoodiePageState();
}

class _SignupFoodiePageState extends State<SignupFoodiePage> {
  @override
  void initState() {
    super.initState();
    // Lock role to FOODI — no role selector shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignUpCubit>().onRoleChanged(role: AppConstants.FOODI);
    });
  }

  void _splitAndSetName(String fullName) {
    final cubit = context.read<SignUpCubit>();
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      cubit.onFirstNameChanged(value: parts.first);
      cubit.onLastNameChanged(value: parts.sublist(1).join(' '));
    } else {
      cubit.onFirstNameChanged(value: fullName);
      cubit.onLastNameChanged(value: '.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: MitablColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SignUpCubit, SignUpState>(
        listener: (context, state) {
          if (state.statusApi?.isSubmissionFailure ?? false) {
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
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Branding
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                MitablColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant,
                              size: 18, color: MitablColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'miFoodi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: MitablColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Heading
                    const Text(
                      'Join the\nCommunity',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                        color: MitablColors.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your culinary journey with us today',
                      style: TextStyle(
                        fontSize: 15,
                        color: MitablColors.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form fields
                    MitablTextField(
                      hint: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: MitablColors.onSurfaceVariant),
                      onChanged: _splitAndSetName,
                      errorText:
                          (state.nameFirst?.isNotValid ?? false)
                              ? 'Please enter your name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    MitablTextField(
                      hint: 'Email or Phone',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: MitablColors.onSurfaceVariant),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) =>
                          context.read<SignUpCubit>().onEmailChanged(value: v),
                      errorText: (state.email?.isNotValid ?? false)
                          ? 'Please enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    MitablTextField(
                      hint: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: MitablColors.onSurfaceVariant),
                      obscureText: state.showPassword,
                      onChanged: (v) =>
                          context.read<SignUpCubit>().onPasswordChanged(value: v),
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: MitablColors.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            context.read<SignUpCubit>().showPassword(),
                      ),
                      errorText: state.password.isNotValid
                          ? 'Min 6 characters required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    MitablTextField(
                      hint: 'Delivery Address',
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: MitablColors.onSurfaceVariant),
                      onChanged: (v) =>
                          context.read<SignUpCubit>().onAddressChanged(value: v),
                      errorText: (state.address?.isNotValid ?? false)
                          ? 'Please enter your address'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // Create Account button
                    MitablButton(
                      label: 'Create Account',
                      icon: const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                      onPressed: (state.status?.isValidated ?? false)
                          ? () => context.read<SignUpCubit>().onSignUp()
                          : null,
                      isLoading:
                          state.statusApi?.isSubmissionInProgress ?? false,
                    ),
                    const SizedBox(height: 28),

                    // Social login
                    const OrDivider(text: 'Or join with'),
                    const SizedBox(height: 16),
                    const SocialLoginRow(),
                    const SizedBox(height: 28),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already a miFoodi? ',
                          style: TextStyle(
                            color: MitablColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigatorKey.currentState!
                              .pushNamed('/LoginPage'),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: MitablColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Loading overlay
              if (state.statusApi?.isSubmissionInProgress ?? false)
                const CommonProgressWidget(),
            ],
          );
        },
      ),
    );
  }
}
