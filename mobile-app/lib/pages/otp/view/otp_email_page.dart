import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:pinput/pinput.dart';

import '../cubit/otp_cubit.dart';

/// Email-based OTP verification variant.
/// Reuses [OtpCubit] — same logic, different visual treatment.
class OtpEmailPage extends StatelessWidget {
  const OtpEmailPage({super.key});

  static Route route({required RouteArguments routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => OtpCubit(
          context.read<AuthenticationRepository>(),
          context.read<UserRepository>(),
          routeArguments,
        ),
        child: const OtpEmailPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: MitablColors.onSurface,
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(
          color: MitablColors.primary.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.statusAPI?.isSubmissionFailure ?? false) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.serverMessage ?? 'Verification failed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Email icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: MitablColors.secondaryContainer
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 36,
                          color: MitablColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Heading
                      const Text(
                        'Verify Identity',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We've sent a verification code\nto your culinary profile email",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OTP input (4 circular fields)
                      Pinput(
                        length: 4,
                        defaultPinTheme: defaultTheme,
                        focusedPinTheme: focusedTheme,
                        submittedPinTheme: defaultTheme,
                        separatorBuilder: (_) => const SizedBox(width: 12),
                        onChanged: (value) {
                          context
                              .read<OtpCubit>()
                              .onOtpChanged(value: value);
                        },
                      ),
                      const SizedBox(height: 36),

                      // Verify button
                      MitablButton(
                        label: 'Verify Code',
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 20),
                        onPressed: (state.status?.isValidated ?? false)
                            ? () =>
                                context.read<OtpCubit>().onSubmitted()
                            : null,
                        isLoading:
                            state.statusAPI?.isSubmissionInProgress ?? false,
                      ),
                      const SizedBox(height: 20),

                      // Resend
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification code resent'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'RESEND CODE',
                          style: TextStyle(
                            color: MitablColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Contact support
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact support coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text(
                          "Didn't receive a code? Contact Support",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              if (state.statusAPI?.isSubmissionInProgress ?? false)
                const CommonProgressWidget(),
            ],
          );
        },
      ),
    );
  }
}
