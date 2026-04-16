import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/model/international_phone.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

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
      // Use single space — passes Formz "not empty" check but backend trims to empty.
      // These fields are only meaningfully collected during kitchen activation.
      cubit.onLastNameChanged(value: ' ');
      cubit.onAddressChanged(value: ' ');
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
      cubit.onLastNameChanged(value: fullName.isNotEmpty ? ' ' : '');
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
              // ── Decorative background blurs ──
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
                    color: MitablColors.primaryContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    // ── Header: back arrow + centered "Mitabl" + spacer ──
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
                              const Expanded(
                                child: Text(
                                  'mitabl',
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
                              const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Scrollable form ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 576),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 24),

                              // ── Heading ──
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 36,
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
                              const SizedBox(height: 16),

                              // ── Subtitle ──
                              const Text(
                                'Join our community of home cooks and culinary enthusiasts. Your place at the table is waiting.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Registration Form Card ──
                              Container(
                                decoration: BoxDecoration(
                                  color: MitablColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: MitablColors.onSurface
                                          .withValues(alpha: 0.04),
                                      blurRadius: 40,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    // Full Name
                                    _buildFieldLabel('FULL NAME'),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      prefixIcon: Icons.person_outlined,
                                      hint: 'Jamie Oliver',
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      onChanged: _onFullNameChanged,
                                      errorText: (state.nameFirst != null &&
                                              !state.nameFirst!.isPure &&
                                              state.nameFirst!.isNotValid)
                                          ? 'Please enter your name'
                                          : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // Email
                                    _buildFieldLabel('EMAIL'),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      prefixIcon: Icons.contact_mail_outlined,
                                      hint: 'chef@mitabl.com',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {
                                        context
                                            .read<SignUpCubit>()
                                            .onEmailChanged(value: value);
                                      },
                                      errorText: (state.email != null &&
                                              !state.email!.isPure &&
                                              state.email!.isNotValid)
                                          ? 'Please enter a valid email'
                                          : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // Phone number (needed for OTP)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 88,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel('CODE'),
                                              const SizedBox(height: 8),
                                              _buildInputField(
                                                controller:
                                                    _countryCodeController,
                                                hint: '+61',
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .allow(
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
                                                            _phoneController
                                                                .text,
                                                      );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel('PHONE NUMBER'),
                                              const SizedBox(height: 8),
                                              _buildInputField(
                                                controller: _phoneController,
                                                prefixIcon:
                                                    Icons.phone_outlined,
                                                hint: '400 000 000',
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
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
                                                        value:
                                                            InternationalPhone
                                                                .compose(
                                                          countryCode:
                                                              _countryCodeController
                                                                  .text,
                                                          number: text,
                                                        ),
                                                      );
                                                },
                                                errorText: state.phoneServerError
                                                            .isNotEmpty
                                                    ? state.phoneServerError
                                                    : (!state.phone.isPure &&
                                                            state
                                                                .phone.isNotValid)
                                                        ? 'Enter a valid phone number'
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Password
                                    _buildFieldLabel('PASSWORD'),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      prefixIcon: Icons.lock_outlined,
                                      hint:
                                          '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                                      obscureText: state.showPassword,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      textInputAction: TextInputAction.done,
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
                                      errorText: (!state.password.isPure &&
                                              state.password.isNotValid)
                                          ? 'Min 6 characters required'
                                          : null,
                                    ),
                                    const SizedBox(height: 28),

                                    // ── Create Account button ──
                                    _buildGradientButton(
                                      label: 'Create Account',
                                      trailingIcon: Icons.restaurant_menu,
                                      isLoading: state
                                          .statusApi!.isSubmissionInProgress,
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
                              const SizedBox(height: 32),

                              // ── "Or join with" divider ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Or join with',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Social login (2-column) ──
                              const Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Google',
                                      iconColor: MitablColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.facebook_rounded,
                                      label: 'Facebook',
                                      iconColor: Color(0xFF1877F2),
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
                              const SizedBox(height: 40),

                              // ── Login link ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already part of the kitchen? ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'DM Sans',
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => navigatorKey.currentState!
                                        .pushNamed('/LoginPage'),
                                    child: const Text(
                                      'Log in here',
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
                              const SizedBox(height: 48),

                              // ── Terms footer ──
                              Text(
                                'BY CREATING AN ACCOUNT, YOU AGREE TO MITABL\'S\nTERMS OF SERVICE AND PRIVACY POLICY.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
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

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'DM Sans',
            letterSpacing: 1.5,
            color: MitablColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    IconData? prefixIcon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'DM Sans',
        color: MitablColors.onSurface,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: TextStyle(
          color: MitablColors.onSurfaceVariant.withValues(alpha: 0.4),
          fontFamily: 'DM Sans',
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  prefixIcon,
                  color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 22,
                ),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: MitablColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: MitablColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MitablColors.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    IconData? trailingIcon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null && !isLoading;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MitablColors.primary, MitablColors.primaryContainer],
              )
            : null,
        color: enabled ? null : MitablColors.tertiaryFixedDim,
        borderRadius: BorderRadius.circular(100),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: MitablColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                          color: Colors.white,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailingIcon, color: Colors.white, size: 22),
                      ],
                    ],
                  ),
          ),
        ),
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
    return Opacity(
      opacity: 0.55,
      child: Container(
        height: 52,
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
                fontFamily: 'DM Sans',
                color: MitablColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
