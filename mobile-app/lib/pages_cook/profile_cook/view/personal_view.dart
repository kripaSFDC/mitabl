import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/cubit/dashboard_cook_cubit.dart';
import 'package:mitabl_user/pages_cook/profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/mobile_contact_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

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

  AvailableRoleMembership? _targetMifoodiRole(ProfileCookState state) {
    final availableRoles = state.cookProfile?.data?.availableRoles ?? const [];
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: config.AppConfig(context).appHeight(3)),
            CachedNetworkImage(
              imageUrl:
                  "${GlobalConfiguration().getValue<String>('base_url')}/${state.cookProfile != null ? state.cookProfile!.data!.avatar : ''}",
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
              errorWidget: (context, url, error) => Container(
                height: config.AppConfig(context).appWidth(18),
                width: config.AppConfig(context).appWidth(18),
                padding: EdgeInsets.all(config.AppConfig(context).appWidth(3)),
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
            SizedBox(height: config.AppConfig(context).appHeight(1)),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.firstName : ''} ${state.cookProfile != null ? state.cookProfile!.data!.lastName : ''}',
                  style: GoogleFonts.gothicA1(
                    color: Theme.of(context).primaryColorDark,
                    fontSize: config.AppConfig(context).appWidth(5),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: config.AppConfig(context).appHeight(1)),
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.email : ''}',
                  style: GoogleFonts.gothicA1(
                    color: const Color(0xffAEAEAE),
                    fontSize: config.AppConfig(context).appWidth(3.5),
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: config.AppConfig(context).appHeight(0.5)),
                Text(
                  '${state.cookProfile != null ? state.cookProfile!.data!.phone : ''}',
                  style: GoogleFonts.gothicA1(
                    color: const Color(0xffAEAEAE),
                    fontSize: config.AppConfig(context).appWidth(3.5),
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: config.AppConfig(context).appHeight(3)),
                Text(
                  state.cookProfile != null
                      ? state.cookProfile!.data!.description ?? ''
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
                SizedBox(height: config.AppConfig(context).appHeight(2)),
                Align(
                  alignment: Alignment.centerLeft,
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
                    icon: Icon(
                      Icons.edit_outlined,
                      size: config.AppConfig(context).appWidth(4.5),
                    ),
                    label: const Text('Edit profile'),
                  ),
                ),
              ],
            ),
            Divider(
              color: const Color(0xffAEAEAE),
              thickness: 0.4,
              height: config.AppConfig(context).appHeight(5),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ListTile(
                      onTap: _switchingRole
                          ? null
                          : () {
                              if (_mifoodiTransitionDisabled(state)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(_disabledMifoodiMessage())),
                                );
                                return;
                              }
                              _switchToMifoodi();
                            },
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/foodi.png',
                            height: config.AppConfig(context).appHeight(3),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            _mifoodiCtaText(state),
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
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'payments',
                            style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4.5),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      onTap: () async {
                        final userRepository = context.read<UserRepository>();
                        try {
                          final user = await userRepository.getUser();
                          final payload = await MobileContactRepository(
                            httpClient: userRepository.httpClient,
                          ).fetch(user);
                          final message = payload['message']?.toString() ??
                              'Contact information loaded.';
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
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
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'contact us',
                            style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4.5),
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
                          arguments: RouteArguments(id: 'cook'),
                        );
                      },
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/setting.png',
                            height: config.AppConfig(context).appHeight(4),
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'settings',
                            style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4.5),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      onTap: () {
                        context.read<DashboardCookCubit>().doLogout();
                      },
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/img/background.svg',
                                  height: config.AppConfig(
                                    context,
                                  ).appHeight(4.5),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                widthFactor: config.AppConfig(
                                  context,
                                ).appWidth(0.38),
                                child: Icon(
                                  Icons.exit_to_app,
                                  size: config.AppConfig(context).appWidth(5.5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: config.AppConfig(context).appWidth(4),
                          ),
                          Text(
                            'logout',
                            style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4.5),
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
        );
      },
    );
  }
}
