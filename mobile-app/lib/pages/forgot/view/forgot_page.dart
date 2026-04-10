import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/pages/forgot/cubit/forgot_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

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
          final isValidated = state.status!.isValidated;

          return Stack(
            children: [
              // ── Decorative background blurs ──
              Positioned(
                bottom: 0,
                right: 0,
                child: Transform.translate(
                  offset: const Offset(96, 96),
                  child: Container(
                    width: 384,
                    height: 384,
                    decoration: BoxDecoration(
                      color: MitablColors.primaryContainer
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Transform.translate(
                  offset: const Offset(-96, -96),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      color: MitablColors.secondaryContainer
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    // ── Header: back + brand ──
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
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: MitablColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'The Culinary Atelier',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Centered form body ──
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: Column(
                              children: [
                                // ── Lock-reset icon circle ──
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: MitablColors.secondaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset,
                                    size: 40,
                                    color:
                                        MitablColors.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // ── Heading ──
                                const Text(
                                  'Forgot Password?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Nunito',
                                    color: MitablColors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Subtitle ──
                                const Text(
                                  "Don't worry! Enter your email below and we'll send you a link to reset your password.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'DM Sans',
                                    color: MitablColors.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 48),

                                // ── Interaction Card ──
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: MitablColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Email label
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(left: 4),
                                        child: Text(
                                          'Email Address',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'DM Sans',
                                            color: MitablColors
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Email field
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction:
                                            TextInputAction.done,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'DM Sans',
                                          color: MitablColors.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'chef@culinaryatelier.com',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontFamily: 'DM Sans',
                                          ),
                                          filled: true,
                                          fillColor: MitablColors
                                              .surfaceContainerLowest,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: MitablColors.primary
                                                  .withValues(alpha: 0.2),
                                              width: 2,
                                            ),
                                          ),
                                          errorText: state.email!.invalid
                                              ? 'Please enter a valid email address'
                                              : null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 18),
                                        ),
                                        onChanged: (text) {
                                          context
                                              .read<ForgotCubit>()
                                              .onEmailChanged(value: text);
                                        },
                                      ),
                                      const SizedBox(height: 32),

                                      // ── Send Reset Link button ──
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: isValidated && !isLoading
                                              ? const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment
                                                      .bottomRight,
                                                  colors: [
                                                    MitablColors.primary,
                                                    MitablColors
                                                        .primaryContainer,
                                                  ],
                                                )
                                              : null,
                                          color: isValidated && !isLoading
                                              ? null
                                              : MitablColors
                                                  .tertiaryFixedDim,
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          boxShadow:
                                              isValidated && !isLoading
                                                  ? [
                                                      BoxShadow(
                                                        color: MitablColors
                                                            .primary
                                                            .withValues(
                                                                alpha:
                                                                    0.2),
                                                        blurRadius: 16,
                                                        offset:
                                                            const Offset(
                                                                0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap:
                                                isValidated && !isLoading
                                                    ? () => context
                                                        .read<
                                                            ForgotCubit>()
                                                        .forgot()
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
                                                          'Send Reset Link',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700,
                                                            fontFamily:
                                                                'DM Sans',
                                                            color: Colors
                                                                .white,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(Icons.send,
                                                            color: Colors
                                                                .white,
                                                            size: 20),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // ── Back to Login link ──
                                GestureDetector(
                                  onTap: () =>
                                      navigatorKey.currentState!.pop(),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back,
                                          size: 16,
                                          color: MitablColors.primary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Back to Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'DM Sans',
                                          color: MitablColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
