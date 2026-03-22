import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/pages/forgot/cubit/forgot_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) =>
            ForgotCubit(context.read<AuthenticationRepository>()),
        child: const ForgotPage(),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: Image.asset(
          'assets/img/logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      body: BlocConsumer<ForgotCubit, ForgotState>(
        listener: (context, state) {
          if (state.status!.isSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.serverMessage}')),
            );
          } else if (state.status!.isSubmissionSuccess) {
            navigatorKey.currentState!.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state.status!.isSubmissionInProgress;
          final isValid = state.email!.valid;
          final isValidated = state.status!.isValidated;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MitablSpacing.pagePadding * 1.5,
                vertical: MitablSpacing.breathe,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Lock-reset icon circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: MitablColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 36,
                      color: MitablColors.onSecondaryContainer,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Heading
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: MitablColors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    "Don't worry! Enter your email below and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: MitablColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Email field
                  MitablTextField(
                    controller: _emailController,
                    hint: 'chef@culinaryatelier.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: MitablColors.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: isValid
                        ? const Icon(
                            Icons.check_circle,
                            color: MitablColors.accent,
                            size: 20,
                          )
                        : null,
                    errorText: state.email!.invalid
                        ? 'Please enter a valid email address'
                        : null,
                    onChanged: (text) {
                      context.read<ForgotCubit>().onEmailChanged(value: text);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit button
                  MitablButton(
                    label: 'Send Reset Link >',
                    isLoading: isLoading,
                    onPressed: isValidated && !isLoading
                        ? () => context.read<ForgotCubit>().forgot()
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Back to Login
                  TextButton(
                    onPressed: () => navigatorKey.currentState!.pop(),
                    child: const Text(
                      '\u2190 Back to Login',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
