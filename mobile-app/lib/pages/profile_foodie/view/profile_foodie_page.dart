import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_navigator.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/pages/common/view/faq_webview_page.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/mobile_contact_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/role_switch_card.dart';

class ProfileFoodiePage extends StatefulWidget {
  const ProfileFoodiePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfileFoodiePage());
  }

  @override
  State<ProfileFoodiePage> createState() => _ProfileFoodiePageState();
}

class _RoleCtaState {
  final bool exists;
  final bool active;
  final bool onboarding;
  final bool disabled;

  const _RoleCtaState({
    required this.exists,
    required this.active,
    required this.onboarding,
    required this.disabled,
  });
}

class _ProfileFoodiePageState extends State<ProfileFoodiePage> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _switchingRole = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Biometric helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadBiometricPreference() async {
    try {
      final biometricService = BiometricService.instance;
      final available = await biometricService.isAvailable();
      final enabled = available ? await biometricService.isEnabled() : false;

      if (!mounted) return;
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _onBiometricChanged(bool enabled) async {
    if (enabled && !_biometricAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is not available on this device.',
          ),
        ),
      );
      return;
    }

    try {
      await BiometricService.instance.setEnabled(enabled);
      if (!mounted) return;
      setState(() => _biometricEnabled = enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update biometric preference right now.'),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Role-switch helpers (micook)
  // ─────────────────────────────────────────────────────────────────────────

  bool _isSuccessfulResponse(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  Map<String, dynamic> _decodeResponsePayload(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final payload = jsonDecode(rawBody);
      if (payload is Map<String, dynamic>) {
        return payload;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  String _extractResponseMessage(
    String rawBody, {
    required String fallback,
  }) {
    final payload = _decodeResponsePayload(rawBody);
    final serverMessage = payload['isError'] ?? payload['message'];
    if (serverMessage is String && serverMessage.trim().isNotEmpty) {
      return serverMessage;
    }

    return fallback;
  }

  AvailableRoleMembership? _targetMicookRole(ProfileFoodieState state) {
    final availableRoles =
        state.foodieProfile?.data?.availableRoles ?? const [];
    for (final role in availableRoles) {
      final normalizedRole = role.role?.trim().toLowerCase();
      if (role.roleId == AppConstants.COOK ||
          normalizedRole == 'micook' ||
          normalizedRole == 'mikitchn' ||
          normalizedRole == 'cook' ||
          normalizedRole == 'restaurant' ||
          normalizedRole == 'vendor') {
        return role;
      }
    }
    return null;
  }

  _RoleCtaState _micookCtaState(ProfileFoodieState state) {
    final availableRole = _targetMicookRole(state);
    if (availableRole != null) {
      final status = availableRole.status?.trim().toLowerCase();
      return _RoleCtaState(
        exists: true,
        active: status == 'active',
        onboarding: availableRole.onboarding,
        disabled: status == 'disabled',
      );
    }

    final membership = state.foodieProfile?.data?.cookRoleMembership;
    if (membership != null) {
      return _RoleCtaState(
        exists: membership.exists,
        active: membership.active,
        onboarding: membership.onboardingRequired,
        disabled: membership.isDisabled,
      );
    }

    return const _RoleCtaState(
      exists: false,
      active: false,
      onboarding: false,
      disabled: false,
    );
  }

  bool _isOnboardingRequired(Map<String, dynamic> transition) {
    final value = transition['onboarding_required'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  String _onboardingStepDescription(String? step) {
    switch (step) {
      case 'kitchen_profile':
        return 'Complete your mikitchn profile to continue micook setup.';
      case 'certificate':
        return 'Upload your kitchen certification to continue micook setup.';
      case 'payout_setup':
      case 'vendor_account':
        return 'Finish payout account setup to continue micook setup.';
      default:
        return 'Continue micook setup from your profile to unlock switching.';
    }
  }

  String _disabledMicookMessage() {
    return 'micook access is currently disabled. Please contact support for reactivation.';
  }

  String _micookCtaText(ProfileFoodieState state) {
    final ctaState = _micookCtaState(state);
    if (ctaState.disabled) return 'micook disabled';
    if (!ctaState.exists) return 'Register as micook';
    if (ctaState.onboarding) return 'Continue micook setup';
    if (ctaState.active) return 'Switch to micook';
    return 'Register as micook';
  }

  bool _micookTransitionDisabled(ProfileFoodieState state) {
    return _micookCtaState(state).disabled;
  }

  Map<String, dynamic> _extractRoleTransition(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final directTransition = data['role_transition'];
      if (directTransition is Map<String, dynamic>) {
        return directTransition;
      }

      final onboarding = data['onboarding'];
      if (onboarding is Map<String, dynamic>) {
        final onboardingTransition = onboarding['role_transition'];
        if (onboardingTransition is Map<String, dynamic>) {
          return onboardingTransition;
        }

        return onboarding;
      }

      return data;
    }

    return payload;
  }

  Future<void> _continueCookOnboarding(Map<String, dynamic> transition) async {
    final userRepository = context.read<UserRepository>();
    final currentUser =
        userRepository.currentUser ?? await userRepository.getUser();

    if (!mounted) return;

    final step = transition['next_required_step']?.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_onboardingStepDescription(step))));

    final routeData = currentUser?.data;
    if (routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please restart the app and try again to continue micook onboarding.',
          ),
        ),
      );
      return;
    }

    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      '/CookProfile',
      (route) => false,
      arguments: RouteArguments(data: routeData),
    );
  }

  Future<void> _switchToMicook() async {
    if (_switchingRole) return;

    setState(() => _switchingRole = true);
    final userRepository = context.read<UserRepository>();
    try {
      final activationResponse = await userRepository.startCookOnboarding();
      if (!mounted) return;

      if (!_isSuccessfulResponse(activationResponse.statusCode)) {
        final message = _extractResponseMessage(
          activationResponse.body,
          fallback: 'Register as micook to begin onboarding before switching.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final activationPayload = _decodeResponsePayload(activationResponse.body);
      final transitionMap = _extractRoleTransition(activationPayload);
      final onboardingRequired = _isOnboardingRequired(transitionMap);

      if (onboardingRequired) {
        await userRepository.refreshRoleMembershipState();
        if (!mounted) return;
        await _continueCookOnboarding(transitionMap);
        return;
      }

      final switchResponse = await userRepository.switchRole(
        roleId: AppConstants.COOK,
      );
      if (!mounted) return;

      if (_isSuccessfulResponse(switchResponse.statusCode)) {
        final switchPayload = _decodeResponsePayload(switchResponse.body);
        final switchTransition = _extractRoleTransition(switchPayload);
        final switchNeedsOnboarding = _isOnboardingRequired(switchTransition);

        await userRepository.refreshRoleMembershipState();
        if (!mounted) return;

        if (switchNeedsOnboarding) {
          await _continueCookOnboarding(switchTransition);
          return;
        }

        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/DashboardCook',
          (route) => false,
        );
        return;
      }

      final message = _extractResponseMessage(
        switchResponse.body,
        fallback:
            'We could not switch to micook yet. Complete remaining setup steps and try again.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to switch profile right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _switchingRole = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Contact Us handler
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleContactUs() async {
    final userRepository = context.read<UserRepository>();
    try {
      final user = await userRepository.getUser();
      final payload = await MobileContactRepository(
        httpClient: userRepository.httpClient,
      ).fetch(user);
      final message =
          payload['message']?.toString() ?? 'Contact information loaded.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load contact info: $error'),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
      builder: (context, state) {
        final profileData = state.foodieProfile?.data;
        final fullName =
            '${profileData?.firstName ?? ''} ${profileData?.lastName ?? ''}'
                .trim();
        final email = (profileData?.email ?? '').toString();
        final phone = (profileData?.phone ?? '').toString();
        final description = profileData?.description ?? '';
        final avatarPath = profileData?.avatar ?? '';
        final avatarUrl = avatarPath.isNotEmpty
            ? "${GlobalConfiguration().getValue<String>('base_url')}/$avatarPath"
            : '';

        return Scaffold(
          backgroundColor: MitablColors.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MitablSpacing.pagePadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── 1. Profile hero section ──
                  _buildAvatar(avatarUrl),
                  const SizedBox(height: 16),
                  if (fullName.isNotEmpty)
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: MitablColors.onSurface,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  if (email.isNotEmpty || phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [email, phone].where((s) => s.isNotEmpty).join('  |  '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 2. Edit Profile button ──
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        navigatorKey.currentState!
                            .pushNamed('/EditProfileFoodie')
                            .then((value) {
                          if (!context.mounted) return;
                          if (value == true) {
                            context
                                .read<ProfileFoodieCubit>()
                                .getFoodieProfile();
                          }
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MitablColors.primary,
                        side: const BorderSide(
                          color: MitablColors.outlineVariant,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── 3. miCook CTA section ──
                  _buildMicookCta(state),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── 4a. Account section card ──
                  _buildSectionCard(
                    children: [
                      _buildMenuRow(
                        icon: Icons.receipt_long,
                        label: 'My Orders',
                        onTap: () {
                          Navigator.of(context).pushNamed('/MiOrders');
                        },
                      ),
                      const _MenuDivider(),
                      _buildMenuRow(
                        icon: Icons.favorite,
                        label: 'Favourites',
                        onTap: () {
                          Navigator.of(context).pushNamed('/Favourites');
                        },
                      ),
                      const _MenuDivider(),
                      _buildMenuRow(
                        icon: Icons.credit_card,
                        label: 'Payments',
                        onTap: () {
                          Navigator.of(context).pushNamed('/Payments');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── 4b. Support section card ──
                  _buildSectionCard(
                    children: [
                      _buildMenuRow(
                        icon: Icons.help_outline,
                        label: 'FAQ',
                        onTap: () {
                          Navigator.of(context).push(FaqWebviewPage.route());
                        },
                      ),
                      const _MenuDivider(),
                      _buildMenuRow(
                        icon: Icons.phone,
                        label: 'Contact Us',
                        onTap: _handleContactUs,
                      ),
                      const _MenuDivider(),
                      _buildMenuRow(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          navigatorKey.currentState!.pushNamed(
                            '/SettingsCook',
                            arguments: RouteArguments(id: 'foodie'),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── 4c. Security section card ──
                  _buildSectionCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MitablSpacing.cardPadding,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            _iconCircle(Icons.fingerprint),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Biometric Lock',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                            Switch(
                              value: _biometricEnabled,
                              activeTrackColor: MitablColors.primary,
                              onChanged: _biometricAvailable
                                  ? _onBiometricChanged
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: MitablSpacing.listItem),

                  // ── 4d. Logout ──
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.read<ProfileFoodieCubit>().doLogout();
                      },
                      icon: const Icon(Icons.exit_to_app, size: 20),
                      label: const Text('Logout'),
                      style: TextButton.styleFrom(
                        foregroundColor: MitablColors.onSurfaceVariant,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),

                  // ── 5. Bottom spacing for nav bar ──
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────────────────────────────────────────

  /// Circular avatar (80px) with CachedNetworkImage.
  Widget _buildAvatar(String imageUrl) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    color: MitablColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => _defaultAvatar(),
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MitablColors.primaryContainer,
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: MitablColors.onPrimary,
          size: 36,
        ),
      ),
    );
  }

  /// miCook CTA card.
  Widget _buildMicookCta(ProfileFoodieState state) {
    final isDisabled = _micookTransitionDisabled(state);

    return RoleSwitchCard(
      actionText: _micookCtaText(state),
      isDisabled: isDisabled,
      isLoading: _switchingRole,
      onTap: _switchingRole
          ? null
          : () {
              if (_micookTransitionDisabled(state)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_disabledMicookMessage())),
                );
                return;
              }
              _switchToMicook();
            },
    );
  }

  /// A grouped section card with rounded-20 corners.
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MitablRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  /// A single menu row inside a section card.
  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MitablRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MitablSpacing.cardPadding,
            vertical: 14,
          ),
          child: Row(
            children: [
              _iconCircle(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MitablColors.onSurface,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: MitablColors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 40x40 circle with icon.
  Widget _iconCircle(IconData icon, {bool filled = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: filled
            ? MitablColors.primary.withValues(alpha: 0.10)
            : MitablColors.surfaceContainerLowest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: filled ? MitablColors.primary : MitablColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Thin divider between menu rows inside a section card.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MitablSpacing.cardPadding + 52, // icon circle + gap
      ),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: MitablColors.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
