import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/otp/cubit/otp_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:pinput/pinput.dart';

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
  }

  @override
  State<StatefulWidget> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final defaultPinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: MitablColors.onSurface,
      ),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      color: MitablColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: MitablColors.primary.withValues(alpha: 0.2),
        width: 2,
      ),
    );

    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.statusAPI!.isSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.serverMessage}')),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.statusAPI!.isSubmissionInProgress;
          final isValidated = state.status!.isValidated;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: MitablSpacing.pagePadding * 1.5,
                  vertical: MitablSpacing.breathe,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock icon circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: MitablColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 36,
                        color: MitablColors.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Heading
                    const Text(
                      'Verify Identity',
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
                      'We sent a code to your phone. Please enter it below to continue.',
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

                    // Pinput
                    Pinput(
                      length: 4,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      separatorBuilder: (index) => const SizedBox(width: 12),
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onChanged: (value) {
                        context.read<OtpCubit>().onOtpChanged(value: value);
                      },
                      onCompleted: (pin) {},
                    ),

                    const SizedBox(height: 36),

                    // Verify button
                    MitablButton(
                      label: 'Verify',
                      isLoading: isLoading,
                      onPressed: isValidated && !isLoading
                          ? () => context.read<OtpCubit>().onSubmitted()
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Resend code
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code resent')),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: "Didn't receive the code? ",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Resend Code',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Demo bypass
                    TextButton(
                      onPressed: () {
                        navigatorKey.currentState!.pushNamedAndRemoveUntil(
                          '/HomePage',
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Skip Verification (Demo)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MitablColors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Security badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SECURE 256-BIT ENCRYPTION',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 2,
                            color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
