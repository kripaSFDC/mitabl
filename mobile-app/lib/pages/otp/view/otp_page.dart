import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/otp/cubit/otp_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
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

    // Pin theme matching HTML: rounded-2xl, bg surface-container-low
    final defaultPinTheme = PinTheme(
      width: 72,
      height: 72,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'DM Sans',
        color: MitablColors.onSurface,
      ),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
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
          if (state.statusAPI!.isSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.serverMessage}')),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.statusAPI!.isSubmissionInProgress;
          final isValidated = state.status!.isValidated;

          return Stack(
            children: [
              // ── Decorative background blurs ──
              Positioned(
                bottom: -96,
                left: -96,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color: MitablColors.secondaryContainer
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
                right: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    // ── Header: back + centered "Mitabl" + spacer ──
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
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
                              const Expanded(
                                child: Text(
                                  'Mitabl',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Nunito',
                                    color: MitablColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Centered scrollable body ──
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: Column(
                              children: [
                                // ── Hero icon ──
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Soft glow behind
                                    Container(
                                      width: 144,
                                      height: 144,
                                      decoration: BoxDecoration(
                                        color: MitablColors.primary
                                            .withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    // Icon circle
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: MitablColors
                                            .surfaceContainerLowest,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.lock_person,
                                        size: 40,
                                        color: MitablColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),

                                // ── Heading ──
                                const Text(
                                  'Verify Identity',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Nunito',
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ── Subtitle ──
                                SizedBox(
                                  width: 280,
                                  child: Text(
                                    'We sent a code to your phone. Please enter it below to continue.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'DM Sans',
                                      color: MitablColors.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),

                                // ── OTP Pinput ──
                                Pinput(
                                  length: 6,
                                  defaultPinTheme: defaultPinTheme,
                                  focusedPinTheme: focusedPinTheme,
                                  separatorBuilder: (index) =>
                                      const SizedBox(width: 12),
                                  pinputAutovalidateMode:
                                      PinputAutovalidateMode.onSubmit,
                                  showCursor: true,
                                  onChanged: (value) {
                                    context
                                        .read<OtpCubit>()
                                        .onOtpChanged(value: value);
                                  },
                                  onCompleted: (pin) {},
                                ),
                                const SizedBox(height: 48),

                                // ── Verify button ──
                                Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(maxWidth: 384),
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
                                            : const Text(
                                                'Verify',
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
                                const SizedBox(height: 32),

                                // ── Resend code ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive the code? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Code resent')),
                                        );
                                      },
                                      child: const Text(
                                        'Resend Code',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'DM Sans',
                                          color: MitablColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ── Divider bar ──
                                Container(
                                  width: 48,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Security badge ──
                                Text(
                                  'SECURE 256-BIT ENCRYPTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 1.6,
                                    color: MitablColors.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // ── Demo bypass (debug builds only) ──
                                if (kDebugMode) TextButton(
                                  onPressed: () async {
                                    final cubit = context.read<OtpCubit>();
                                    final userId =
                                        cubit.routeArguments?.id;
                                    if (userId == null) return;

                                    try {
                                      final uri = ApiContract.uri(
                                          'dev/otp/$userId');
                                      final resp =
                                          await http.get(uri, headers: {
                                        'Accept': 'application/json',
                                      }).timeout(
                                          const Duration(seconds: 10));

                                      if (resp.statusCode == 200) {
                                        final otp = json
                                                .decode(resp.body)['otp']
                                                ?.toString() ??
                                            '';
                                        if (otp.isNotEmpty) {
                                          cubit.onOtpChanged(value: otp);
                                          cubit.onSubmitted();
                                          return;
                                        }
                                      }
                                    } catch (_) {}

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Could not auto-verify. Please enter OTP manually.')),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Auto-Verify (Demo)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: MitablColors.accent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
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
            ],
          );
        },
      ),
    );
  }
}
