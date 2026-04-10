import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
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
    // Pin theme: w-16 h-20 (64x80), rounded-lg, bg surface-container-low
    final defaultTheme = PinTheme(
      width: 64,
      height: 80,
      textStyle: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
        color: MitablColors.onSurface,
      ),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
    );

    final focusedTheme = defaultTheme.copyDecorationWith(
      color: MitablColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: MitablColors.primary.withValues(alpha: 0.2),
        width: 2,
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
          final isLoading =
              state.statusAPI?.isSubmissionInProgress ?? false;
          final isValidated = state.status?.isValidated ?? false;

          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // ── Header: back arrow only ──
                    ClipRect(
                      child: BackdropFilter(
                        filter: MitablGlass.blur,
                        child: Container(
                          color: MitablGlass.background,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: MitablColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Scrollable content ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),

                              // ── Email icon in green circle ──
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: MitablColors.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mark_email_unread,
                                  size: 40,
                                  color:
                                      MitablColors.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── Heading ──
                              const Text(
                                'Verify Identity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ── Subtitle ──
                              const SizedBox(
                                width: 280,
                                child: Text(
                                  "We've sent a 4-digit verification code to your culinary profile email.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'DM Sans',
                                    color: MitablColors.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // ── OTP Input (4 digits) ──
                              Pinput(
                                length: 4,
                                defaultPinTheme: defaultTheme,
                                focusedPinTheme: focusedTheme,
                                submittedPinTheme: defaultTheme,
                                separatorBuilder: (_) =>
                                    const SizedBox(width: 16),
                                onChanged: (value) {
                                  context
                                      .read<OtpCubit>()
                                      .onOtpChanged(value: value);
                                },
                              ),
                              const SizedBox(height: 48),

                              // ── Verify Code button ──
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: isValidated && !isLoading
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            MitablColors.primary,
                                            MitablColors.primaryContainer,
                                          ],
                                        )
                                      : null,
                                  color: isValidated && !isLoading
                                      ? null
                                      : MitablColors.tertiaryFixedDim,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: isValidated && !isLoading
                                      ? [
                                          BoxShadow(
                                            color: MitablColors.primary
                                                .withValues(alpha: 0.1),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isValidated && !isLoading
                                        ? () => context
                                            .read<OtpCubit>()
                                            .onSubmitted()
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(100),
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Verify Code',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontFamily: 'Nunito',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.verified,
                                                    color: Colors.white,
                                                    size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Resend Code ──
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Verification code resent'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'RESEND CODE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DM Sans',
                                        letterSpacing: 1.0,
                                        color: MitablColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.refresh,
                                        size: 18,
                                        color: MitablColors.primary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),

                              // ── Contextual illustration card ──
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: const Color(0xFFF8FAFC),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Gradient overlay
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              MitablColors.surface
                                                  .withValues(alpha: 0.9),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Bottom label
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        right: 16,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFEDD5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.restaurant,
                                                size: 14,
                                                color: Color(0xFF431407),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'JOIN THE MITABL ATELIER',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'DM Sans',
                                                letterSpacing: 2.0,
                                                color: MitablColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Footer ──
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DM Sans',
                            color: MitablColors.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                                text: "Didn't receive a code? "),
                            TextSpan(
                              text: 'Contact Support',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: MitablColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isLoading) const CommonProgressWidget(),
            ],
          );
        },
      ),
    );
  }
}
