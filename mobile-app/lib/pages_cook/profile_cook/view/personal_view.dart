import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/mobile_contact_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class PersonalTabView extends StatefulWidget {
  const PersonalTabView({super.key});

  @override
  State<PersonalTabView> createState() => _PersonalTabViewState();
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

class _PersonalTabViewState extends State<PersonalTabView> {
  bool _switchingRole = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

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
  // Role-switch helpers (mifoodi)
  // ─────────────────────────────────────────────────────────────────────────

  AvailableRoleMembership? _targetMifoodiRole(ProfileCookState state) {
    final availableRoles =
        state.cookProfile?.data?.availableRoles ?? const [];
    for (final role in availableRoles) {
      final normalizedRole = role.role?.trim().toLowerCase();
      if (role.roleId == AppConstants.FOODI ||
          normalizedRole == 'mifoodi' ||
          normalizedRole == 'foodie' ||
          normalizedRole == 'foodi') {
        return role;
      }
    }
    return null;
  }

  _RoleCtaState _mifoodiCtaState(ProfileCookState state) {
    final availableRole = _targetMifoodiRole(state);
    if (availableRole != null) {
      final status = availableRole.status?.trim().toLowerCase();
      return _RoleCtaState(
        exists: true,
        active: status == 'active',
        onboarding: availableRole.onboarding,
        disabled: status == 'disabled',
      );
    }

    final membership = state.cookProfile?.data?.foodieRoleMembership;
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

  String _mifoodiCtaText(ProfileCookState state) {
    final ctaState = _mifoodiCtaState(state);
    if (ctaState.disabled) {
      return 'mifoodi disabled';
    }
    if (!ctaState.exists) {
      return 'Register as mifoodi';
    }
    if (ctaState.onboarding) {
      return 'Continue mifoodi setup';
    }
    if (ctaState.active) {
      return 'Switch to mifoodi';
    }

    return 'Register as mifoodi';
  }

  bool _mifoodiTransitionDisabled(ProfileCookState state) {
    return _mifoodiCtaState(state).disabled;
  }

  String _disabledMifoodiMessage() {
    return 'mifoodi access is currently disabled. Please contact support for help.';
  }

  String _mifoodiStepDescription(String? step) {
    switch (step) {
      case 'profile':
        return 'Complete your mifoodi profile details to continue.';
      case 'phone_verification':
        return 'Verify your phone number to continue as mifoodi.';
      default:
        return 'Complete your remaining mifoodi setup steps to continue.';
    }
  }

  Map<String, dynamic> _extractRoleTransition(Map<String, dynamic> payload) {
    final data = payload['data'];
    final transition =
        data is Map<String, dynamic> ? data['role_transition'] : null;
    return transition is Map<String, dynamic>
        ? transition
        : <String, dynamic>{};
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

  Future<void> _switchToMifoodi() async {
    if (_switchingRole) return;

    setState(() => _switchingRole = true);
    final userRepository = context.read<UserRepository>();
    try {
      final response = await userRepository.switchRole(
        roleId: AppConstants.FOODI,
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final transitionMap = _extractRoleTransition(payload);
        final onboardingRequired = _isOnboardingRequired(transitionMap);

        if (onboardingRequired) {
          await userRepository.refreshRoleMembershipState();
          if (!mounted) return;
          final step = transitionMap['next_required_step']?.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_mifoodiStepDescription(step))),
          );
        } else {
          await userRepository.refreshRoleMembershipState();
          if (!mounted) return;
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/HomePage',
            (route) => false,
          );
        }
        return;
      }

      String message =
          'We could not switch to mifoodi yet. Please try again shortly.';
      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final transitionMap = _extractRoleTransition(payload);
        if (_isOnboardingRequired(transitionMap)) {
          final step = transitionMap['next_required_step']?.toString();
          message = _mifoodiStepDescription(step);
        } else {
          final serverMessage = payload['isError'] ?? payload['message'];
          if (serverMessage is String && serverMessage.trim().isNotEmpty) {
            message = serverMessage;
          }
        }
      } catch (_) {}

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
      builder: (context, state) {
        final profileData = state.cookProfile?.data;
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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MitablSpacing.pagePadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── 1. Profile hero section ──
              _buildAvatar(avatarUrl),
              const SizedBox(height: 16),
              if (fullName.isNotEmpty)
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.onSurface,
                    fontFamily: 'Nunito',
                  ),
                ),
              if (email.isNotEmpty || phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [email, phone]
                      .where((s) => s.isNotEmpty)
                      .join('  |  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: MitablColors.onSurfaceVariant,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── 2. Edit Profile pill button ──
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    navigatorKey.currentState!
                        .pushNamed('/ProfileCook')
                        .then((value) {
                      if (!context.mounted) return;
                      if (value == true) {
                        context.read<ProfileCookCubit>().getCookProfile();
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

              // ── 3. Switch to mifoodi CTA ──
              _buildMifoodiCta(state),

              const SizedBox(height: MitablSpacing.listItem),

              // ── 4a. Account section card ──
              _buildSectionCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.credit_card,
                    label: 'Payments',
                    onTap: () {
                      Navigator.of(context).pushNamed('/Payments');
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
                        arguments: RouteArguments(id: 'cook'),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: MitablSpacing.listItem),

              // ── 4b. Security section card ──
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

              // ── 4c. Logout ──
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    context.read<DashboardCookCubit>().doLogout();
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

              // ── Bottom spacing for nav bar ──
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 80,
              ),
            ],
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

  /// mifoodi CTA card.
  Widget _buildMifoodiCta(ProfileCookState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MitablRadius.card),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MitablRadius.card),
          onTap: _switchingRole
              ? null
              : () {
                  if (_mifoodiTransitionDisabled(state)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_disabledMifoodiMessage()),
                      ),
                    );
                    return;
                  }
                  _switchToMifoodi();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MitablSpacing.cardPadding + 4,
              vertical: 16,
            ),
            child: Row(
              children: [
                _iconCircle(Icons.swap_horiz, filled: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _mifoodiCtaText(state),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MitablColors.onSurface,
                      fontFamily: 'DM Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_switchingRole)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MitablColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.swap_horiz,
                    color: MitablColors.onSurfaceVariant,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
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
          color:
              filled ? MitablColors.primary : MitablColors.onSurfaceVariant,
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
