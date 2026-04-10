import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
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
              // ── Decorative floating icons ──
              const Positioned(
                bottom: -48,
                right: -48,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.soup_kitchen,
                      size: 192, color: MitablColors.primary),
                ),
              ),
              Positioned(
                top: 96,
                left: -32,
                child: Transform.rotate(
                  angle: 0.21,
                  child: const Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.eco,
                        size: 128, color: MitablColors.primary),
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    // ── Header: back arrow + centered "miFoodi" + spacer ──
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
                                  'miFoodi',
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
                          constraints: const BoxConstraints(maxWidth: 512),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 24),

                              // ── Hero heading ──
                              const Text(
                                'Join the Community',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start your culinary journey with us today.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Form Card ──
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
                                  children: [
                                    // Full Name
                                    _buildFieldLabel('FULL NAME'),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      prefixIcon: Icons.person_outlined,
                                      hint: 'Chef De Cuisine',
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      onChanged: _splitAndSetName,
                                      errorText:
                                          (state.nameFirst?.isNotValid ??
                                                  false)
                                              ? 'Please enter your name'
                                              : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // Email or Phone
                                    _buildFieldLabel('EMAIL OR PHONE'),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      prefixIcon: Icons.contact_mail_outlined,
                                      hint: 'hello@mifoodi.com',
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (v) => context
                                          .read<SignUpCubit>()
                                          .onEmailChanged(value: v),
                                      errorText:
                                          (state.email?.isNotValid ?? false)
                                              ? 'Please enter a valid email'
                                              : null,
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
                                      textInputAction: TextInputAction.next,
                                      suffixIcon: IconButton(
                                        onPressed: () => context
                                            .read<SignUpCubit>()
                                            .showPassword(),
                                        icon: Icon(
                                          state.showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color:
                                              const Color(0xFF64748B),
                                          size: 22,
                                        ),
                                      ),
                                      onChanged: (v) => context
                                          .read<SignUpCubit>()
                                          .onPasswordChanged(value: v),
                                      errorText: state.password.isNotValid
                                          ? 'Min 6 characters required'
                                          : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // Delivery Address
                                    _buildFieldLabel('DELIVERY ADDRESS'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      maxLines: 3,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'DM Sans',
                                        color: MitablColors.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            "Enter your kitchen's location",
                                        hintStyle: const TextStyle(
                                          color: MitablColors.outlineVariant,
                                          fontFamily: 'DM Sans',
                                        ),
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.only(
                                              left: 16,
                                              right: 8,
                                              bottom: 48),
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            color: Color(0xFF64748B),
                                            size: 22,
                                          ),
                                        ),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                                minWidth: 48, minHeight: 48),
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16),
                                      ),
                                      onChanged: (v) => context
                                          .read<SignUpCubit>()
                                          .onAddressChanged(value: v),
                                    ),
                                    const SizedBox(height: 28),

                                    // ── Create Account button ──
                                    _buildGradientButton(
                                      label: 'Create Account',
                                      trailingIcon: Icons.restaurant_menu,
                                      isLoading: state.statusApi
                                              ?.isSubmissionInProgress ??
                                          false,
                                      onPressed:
                                          (state.status?.isValidated ?? false)
                                              ? () => context
                                                  .read<SignUpCubit>()
                                                  .onSignUp()
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Terms ──
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'DM Sans',
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                        text:
                                            'By signing up, you agree to our '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: MitablColors.primary,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: MitablColors.primary,
                                      ),
                                    ),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── "Or join with" divider ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'OR JOIN WITH',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DM Sans',
                                        letterSpacing: 2.0,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: MitablColors.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Social login (2-column) ──
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Google',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: Icons.facebook_rounded,
                                      label: 'Facebook',
                                      iconColor: const Color(0xFF1877F2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // ── Login link ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already a miFoodi? ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'DM Sans',
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => navigatorKey.currentState!
                                        .pushNamed('/LoginPage'),
                                    child: const Text(
                                      'Log In',
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
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    IconData? prefixIcon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'DM Sans',
        color: MitablColors.onSurface,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: const TextStyle(
          color: MitablColors.outlineVariant,
          fontFamily: 'DM Sans',
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  prefixIcon,
                  color: const Color(0xFF64748B),
                  size: 22,
                ),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: MitablColors.surfaceContainerLowest,
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
      height: 60,
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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 12),
                        Icon(trailingIcon, color: Colors.white, size: 24),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
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
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: MitablColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor ?? MitablColors.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
