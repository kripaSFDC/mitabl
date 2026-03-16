import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/pages/common/view/faq_webview_page.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/mobile_contact_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class ProfileFoodiePage extends StatefulWidget {
  const ProfileFoodiePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfileFoodiePage());
    // );
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
  bool _switchingRole = false;

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
    final availableRoles = state.foodieProfile?.data?.availableRoles ?? const [];
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

  bool _shouldRegisterMicook(ProfileFoodieState state) {
    final ctaState = _micookCtaState(state);
    return !ctaState.exists;
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
      final onboardingRequired = _isOnboardingRequired(
        transitionMap['onboarding_required'],
      );

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
        await userRepository.refreshRoleMembershipState();
        if (!mounted) return;
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/DashboardCook',
          (route) => false,
        );
        return;
      }

      final message = _extractResponseMessage(
        switchResponse.body,
        fallback: 'We could not switch to micook yet. Complete remaining setup steps and try again.',
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              shadowColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: config.AppConfig(context).appWidth(5),
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () => {navigatorKey.currentState!.pop()},
              ),
            ),
            backgroundColor: const Color(0xFFFFFBF7),
            body: Padding(
              padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(3),
                right: config.AppConfig(context).appWidth(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.firstName : ''} ${state.foodieProfile != null ? state.foodieProfile!.data!.lastName : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.gothicA1(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: config.AppConfig(context).appWidth(5),
                              ),
                            ),
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.email : ''}',
                              style: GoogleFonts.gothicA1(
                                color: const Color(0xffAEAEAE),
                                fontSize: config.AppConfig(
                                  context,
                                ).appWidth(3.5),
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${state.foodieProfile != null ? state.foodieProfile!.data!.phone : ''}',
                              style: GoogleFonts.gothicA1(
                                color: const Color(0xffAEAEAE),
                                fontSize: config.AppConfig(
                                  context,
                                ).appWidth(3.5),
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl:
                            "${GlobalConfiguration().getValue<String>('base_url')}/${state.foodieProfile != null ? state.foodieProfile!.data!.avatar : ''}",
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                  value: downloadProgress.progress,
                                ),
                        errorWidget: (context, url, error) => Container(
                          height: config.AppConfig(context).appWidth(18),
                          width: config.AppConfig(context).appWidth(18),
                          padding: EdgeInsets.all(
                            config.AppConfig(context).appWidth(3),
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColorDark,
                          ),
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFFFFFBF7),
                            size: config.AppConfig(context).appWidth(8),
                          ),
                        ),
                        imageBuilder: (context, imageProvider) => Container(
                          height: config.AppConfig(context).appWidth(18),
                          width: config.AppConfig(context).appWidth(18),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: config.AppConfig(context).appHeight(1)),
                  Container(
                    alignment: Alignment.topLeft,
                    constraints: BoxConstraints(
                      minHeight: config.AppConfig(context).appHeight(8.0),
                      minWidth: double.infinity,
                    ),
                    child: Text(
                      state.foodieProfile != null
                          ? state.foodieProfile!.data!.description ?? ''
                          : '',
                      style: GoogleFonts.gothicA1(
                        color: Theme.of(context).primaryColorDark,
                        fontSize: config.AppConfig(context).appWidth(4),
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ListTile(
                    onTap: _switchingRole
                        ? null
                        : () {
                            if (_micookTransitionDisabled(state)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_disabledMicookMessage())),
                              );
                              return;
                            }
                            if (_shouldRegisterMicook(state)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Register as micook from onboarding to enable role switching.',
                                  ),
                                ),
                              );
                              return;
                            }
                            _switchToMicook();
                          },
                    minVerticalPadding: 0,
                    contentPadding: EdgeInsets.zero,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/img/cook.png',
                          height: config.AppConfig(context).appHeight(3),
                        ),
                        SizedBox(width: config.AppConfig(context).appWidth(4)),
                        Text(
                          _micookCtaText(state),
                          style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColorDark,
                            fontSize: config.AppConfig(context).appWidth(5),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: _switchingRole
                        ? SizedBox(
                            height: config.AppConfig(context).appWidth(5),
                            width: config.AppConfig(context).appWidth(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          )
                        : Icon(
                            Icons.swap_horiz,
                            color: Theme.of(context).primaryColorDark,
                          ),
                  ),
                  const Divider(color: Color(0xffAEAEAE), thickness: 0.4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ListTile(
                            onTap: () {
                              Navigator.of(context).pushNamed('/MiOrders');
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/miorders.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'miorders',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).pushNamed('/Favourites');
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/favourites.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'favourites',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).pushNamed('/Payments');
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/payments.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'payments',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(FaqWebviewPage.route());
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/faq.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'faq',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () async {
                              final userRepository = context
                                  .read<UserRepository>();
                              try {
                                final user = await userRepository.getUser();
                                final payload = await MobileContactRepository(
                                  httpClient: userRepository.httpClient,
                                ).fetch(user);
                                final message =
                                    payload['message']?.toString() ??
                                    'Contact information loaded.';
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to load contact info: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/contact.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'contact us',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              navigatorKey.currentState!.pushNamed(
                                '/SettingsCook',
                                arguments: RouteArguments(id: 'foodie'),
                              );
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/setting.png',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'settings',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  size: config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'biometric lock',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: config.AppConfig(context).appWidth(20),
                              child: Switch(
                                value: _biometricEnabled,
                                inactiveTrackColor: Theme.of(
                                  context,
                                ).primaryColorDark,
                                onChanged: _onBiometricChanged,
                              ),
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              context.read<ProfileFoodieCubit>().doLogout();
                            },
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.exit_to_app,
                                  size: config.AppConfig(context).appHeight(4),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(4),
                                ),
                                Text(
                                  'logout',
                                  style: GoogleFonts.gothicA1(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
