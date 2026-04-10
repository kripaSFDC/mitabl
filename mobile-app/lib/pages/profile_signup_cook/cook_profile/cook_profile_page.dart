import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/timing_model.dart';
import 'package:mitabl_user/pages/profile_signup_cook/cook_profile/element/timing_dialog.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

import 'cubit/cook_profile_cubit.dart';
import 'package:mitabl_user/model/international_phone.dart';

class CookProfilePage extends StatefulWidget {
  const CookProfilePage({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => CookProfileCubit(
          context.read<AuthenticationRepository>(),
          routeArguments,
        ),
        child: const CookProfilePage(),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _CookProfilePage();
}

class _CookProfilePage extends State<CookProfilePage>
    with TickerProviderStateMixin {
  _CookProfilePage();

  bool _openingSavedKitchen = false;
  final GlobalKey _kitchenStoryKey = GlobalKey();
  final GlobalKey _operatingHoursKey = GlobalKey();
  final GlobalKey _serviceTypeKey = GlobalKey();
  final FocusNode _kitchenStoryFocusNode = FocusNode();
  final TextEditingController _kitchenStoryController =
      TextEditingController();

  Future<void> _openSavedKitchen() async {
    if (_openingSavedKitchen) return;

    setState(() => _openingSavedKitchen = true);
    try {
      final userRepository = context.read<UserRepository>();
      final response = await userRepository.getCookProfile();

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load saved mikitchn right now.'),
          ),
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved mikitchn data is unavailable right now.'),
          ),
        );
        return;
      }

      final profile = GetCookProfileModel.fromJson(decoded);
      final kitchen = profile.data?.kitchen;
      if (kitchen == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved mikitchn found yet.'),
          ),
        );
        return;
      }

      final result = await navigatorKey.currentState?.pushNamed(
        '/EditKitchenProfile',
        arguments: RouteArguments(kitchen: kitchen),
      );

      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('mikitchn updated successfully.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open saved mikitchn right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingSavedKitchen = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  TextEditingController? mobileNoTextEditor = TextEditingController();
  TextEditingController? passwordTextEditor = TextEditingController();
  PageController? controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    mobileNoTextEditor?.dispose();
    passwordTextEditor?.dispose();
    controller?.dispose();
    _kitchenStoryFocusNode.dispose();
    _kitchenStoryController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  Future<void> _focusKitchenStory() async {
    await _scrollToSection(_kitchenStoryKey);
    if (!mounted) return;
    _kitchenStoryFocusNode.requestFocus();
  }

  Future<void> _openKitchenSpecsActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MitablColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kitchen Specs',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Health and safety documents are completed later in onboarding. You can jump to the current specs-related sections from here.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushNamed('/KitchenCertification');
                    },
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Open Certification Step'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _scrollToSection(_operatingHoursKey);
                    },
                    icon: const Icon(Icons.access_time_rounded),
                    label: const Text('Jump to Operating Hours'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _scrollToSection(_serviceTypeKey);
                    },
                    icon: const Icon(Icons.room_service_outlined),
                    label: const Text('Jump to Service Type'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<CookProfileCubit, CookProfileState>(
        listener: (context, state) {
          if (state.statusApi!.isSubmissionSuccess) {
            Navigator.of(context).pushNamed('/SetupPayouts');
          }
          if (state.statusApi!.isSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.serverMessage ?? 'Something went wrong'),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // ── Fixed Top App Bar ──
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 24,
                      right: 24,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: MitablColors.surface.withValues(alpha: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/HomePage',
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: MitablColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'mitabl',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: MitablColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Step 1 of 3',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable content ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // ── Hero Heading ──
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                const TextSpan(text: 'The Culinary\n'),
                                TextSpan(
                                  text: 'Atelier',
                                  style: GoogleFonts.nunito(
                                    fontStyle: FontStyle.italic,
                                    color: MitablColors.primary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(text: ' Starts Here.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Set the stage for your home-cooked masterpieces. Define your identity as a miCook.',
                            style: TextStyle(
                              fontSize: 16,
                              color: MitablColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Semantics(
                              button: true,
                              label: 'Open saved mikitchn',
                              hint:
                                  'Opens your existing kitchen profile for editing if one exists.',
                              child: OutlinedButton.icon(
                                onPressed: _openingSavedKitchen
                                    ? null
                                    : _openSavedKitchen,
                                icon: _openingSavedKitchen
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.storefront_outlined),
                                label: const Text('Open Saved mikitchn'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Kitchen Name field ──
                          _buildFieldLabel('KITCHEN NAME'),
                          const SizedBox(height: 8),
                          _KitchenName(loginForm: this),
                          const SizedBox(height: 24),

                          // ── Kitchen Story (description) ──
                          Column(
                            key: _kitchenStoryKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('KITCHEN STORY'),
                              const SizedBox(height: 8),
                              BlocBuilder<CookProfileCubit, CookProfileState>(
                                builder: (context, state) {
                                  if (_kitchenStoryController.text !=
                                      state.bio.value) {
                                    _kitchenStoryController.value =
                                        _kitchenStoryController.value.copyWith(
                                      text: state.bio.value,
                                      selection: TextSelection.collapsed(
                                        offset: state.bio.value.length,
                                      ),
                                      composing: TextRange.empty,
                                    );
                                  }

                                  return TextFormField(
                                    controller: _kitchenStoryController,
                                    focusNode: _kitchenStoryFocusNode,
                                    maxLines: 4,
                                    onChanged: (text) {
                                      context
                                          .read<CookProfileCubit>()
                                          .onBioChanged(value: text);
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          'Describe the soul of your cooking, the ingredients you love, and the atmosphere you create...',
                                      errorText: state.bio.invalid
                                          ? 'Please enter a valid kitchen story'
                                          : null,
                                      hintStyle: TextStyle(
                                        color: MitablColors.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                        fontSize: 15,
                                      ),
                                      filled: true,
                                      fillColor:
                                          MitablColors.surfaceContainerLow,
                                      border: const OutlineInputBorder(
                                        borderRadius:
                                            MitablRadius.inputBorder,
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            MitablRadius.inputBorder,
                                        borderSide: BorderSide(
                                          color: MitablColors.primary
                                              .withValues(alpha: 0.2),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.all(20),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: MitablColors.onSurface,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Cuisine Style / Kitchen Specs cards ──
                          Row(
                            children: [
                              Expanded(
                                child: _ActionInfoTile(
                                  icon: Icons.restaurant_menu,
                                  title: 'Cuisine Style',
                                  description:
                                      'Artisan, Traditional, Fusion, or Home Comfort.',
                                  semanticsLabel:
                                      'Cuisine Style information. Artisan, Traditional, Fusion, or Home Comfort.',
                                  semanticsHint:
                                      'Jumps to the kitchen story field.',
                                  onTap: _focusKitchenStory,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ActionInfoTile(
                                  icon: Icons.verified_user,
                                  title: 'Kitchen Specs',
                                  description:
                                      'Health certifications and safety standards.',
                                  semanticsLabel:
                                      'Kitchen Specs information. Health certifications and safety standards.',
                                  semanticsHint:
                                      'Opens actions for related setup sections.',
                                  onTap: _openKitchenSpecsActions,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Kitchen Photo area ──
                          _buildKitchenPhotoSection(state),
                          const SizedBox(height: 24),

                          // ── Address ──
                          _buildFieldLabel('ADDRESS'),
                          const SizedBox(height: 8),
                          BlocBuilder<CookProfileCubit, CookProfileState>(
                            builder: (context, state) {
                              return MitablTextField(
                                hint: 'Enter kitchen address',
                                maxLines: 1,
                                errorText: state.address!.invalid
                                    ? 'Please enter a valid address'
                                    : null,
                                onChanged: (text) {
                                  context
                                      .read<CookProfileCubit>()
                                      .onAddressChanged(value: text);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Phone ──
                          _buildFieldLabel('PHONE NUMBER'),
                          const SizedBox(height: 8),
                          _PhoneNo(loginForm: this),
                          const SizedBox(height: 24),

                          // ── Number of Seats ──
                          _buildFieldLabel('NUMBER OF SEATS'),
                          const SizedBox(height: 8),
                          _NoOfSeats(loginForm: this),
                          const SizedBox(height: 24),

                          // ── Operating Hours ──
                          Column(
                            key: _operatingHoursKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('OPERATING HOURS'),
                              const SizedBox(height: 8),
                              _Timing(loginForm: this),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Service Type ──
                          Column(
                            key: _serviceTypeKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('SERVICE TYPE'),
                              const SizedBox(height: 8),
                              _ServiceTypeSection(),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Dine-in Slots ──
                          const _CreateKitchenSlotSection(),
                          const SizedBox(height: 32),

                          // Extra space for bottom bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Fixed Bottom Bar ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: MitablColors.surface.withValues(alpha: 0.9),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress info
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ONBOARDING PROFILE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: MitablColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '35% COMPLETE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: MitablColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      const ClipRRect(
                        borderRadius: MitablRadius.pillBorder,
                        child: LinearProgressIndicator(
                          value: 0.35,
                          minHeight: 6,
                          color: MitablColors.primary,
                          backgroundColor: Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Next button
                      _LoginButton(loginForm: this),
                    ],
                  ),
                ),
              ),

              if (state.statusApi!.isSubmissionInProgress)
                const CommonProgressWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: MitablColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildKitchenPhotoSection(CookProfileState state) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MitablColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image or placeholder
          if (state.pathFiles.isNotEmpty)
            PageView.builder(
              controller: controller,
              onPageChanged: (page) {
                context.read<CookProfileCubit>().onImageScroll(index: page);
              },
              itemCount: state.pathFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(state.pathFiles[index]),
                      fit: BoxFit.cover,
                    ),
                    // Delete button
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.read<CookProfileCubit>().onDeleteImage(
                                  path: state.pathFiles[index],
                                );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC).withValues(alpha: 0.8),
              ),
              child: Center(
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 48,
                  color: MitablColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),

          // Gradient overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF8FAFC).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Add Kitchen Photo button
          Positioned(
            left: 24,
            bottom: 24,
            child: _UploadButton(loginForm: this),
          ),

          // Page indicator dots
          if (state.pathFiles.length > 1)
            Positioned(
              bottom: 28,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  state.pathFiles.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: state.selectedPage == index
                          ? MitablColors.primary
                          : MitablColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timing widget
// ─────────────────────────────────────────────────────────────────────────────
class _Timing extends StatefulWidget {
  final _CookProfilePage? loginForm;

  const _Timing({this.loginForm});

  @override
  State<_Timing> createState() => _TimingState();
}

class _TimingState extends State<_Timing> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return InkWell(
          borderRadius: MitablRadius.inputBorder,
          onTap: () {
            context.read<CookProfileCubit>().onOpenTimingDialog();
            showDialog(
              context: context,
              builder: (contexts) {
                return BlocProvider.value(
                  value: context.read<CookProfileCubit>(),
                  child: TimingDialog(),
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: MitablColors.surfaceContainerLow,
              borderRadius: MitablRadius.inputBorder,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Set Timings',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: MitablColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionInfoTile extends StatelessWidget {
  const _ActionInfoTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.semanticsLabel,
    required this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final String description;
  final Future<void> Function() onTap;
  final String semanticsLabel;
  final String semanticsHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      hint: semanticsHint,
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: MitablColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Type Section
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceTypeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ServiceTypeTile(
                title: 'Dine-in',
                value: state.dineIn,
                onChanged: (value) => context
                    .read<CookProfileCubit>()
                    .onDineInChange(value: value),
              ),
              Divider(
                height: 1,
                color: MitablColors.outlineVariant.withValues(alpha: 0.3),
              ),
              _ServiceTypeTile(
                title: 'Takeaway',
                value: state.takeAway,
                onChanged: (value) => context
                    .read<CookProfileCubit>()
                    .onTakeAwayChange(value: value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceTypeTile extends StatelessWidget {
  const _ServiceTypeTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MitablColors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: MitablColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dine-in Slots Section
// ─────────────────────────────────────────────────────────────────────────────
class _CreateKitchenSlotSection extends StatelessWidget {
  const _CreateKitchenSlotSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        final availableDays = _resolveOpenDays(state.daysTimingOriginal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dine-in Timeslots',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: state.dineIn && availableDays.isNotEmpty
                      ? () => _showSlotEditor(
                            context,
                            state: state,
                            availableDays: availableDays,
                          )
                      : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add slot'),
                  style: TextButton.styleFrom(
                    foregroundColor: MitablColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!state.dineIn)
              const Text(
                'Enable dine-in to add bookable table slots.',
                style: TextStyle(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              )
            else if (availableDays.isEmpty)
              const Text(
                'Turn on at least one kitchen opening day first.',
                style: TextStyle(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              )
            else if (state.dineInSlots.isEmpty)
              const Text(
                'No dine-in slots added yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              )
            else
              ...List<Widget>.generate(state.dineInSlots.length, (index) {
                final slot = state.dineInSlots[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: MitablColors.surfaceContainerLow,
                    borderRadius: MitablRadius.cardBorder,
                  ),
                  child: ListTile(
                    onTap: () => _showSlotEditor(
                      context,
                      state: state,
                      availableDays: availableDays,
                      existing: slot,
                      index: index,
                    ),
                    title: Text(
                      '${slot.dayName ?? _labelForDay(slot.dayOfWeek)}  ${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Seats: ${slot.seatCapacity ?? 0}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          onPressed: () => _showSlotEditor(
                            context,
                            state: state,
                            availableDays: availableDays,
                            existing: slot,
                            index: index,
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: MitablColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<CookProfileCubit>()
                              .deleteDineInSlot(index),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: MitablColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _showSlotEditor(
    BuildContext context, {
    required CookProfileState state,
    required List<_OpenDayOption> availableDays,
    DineInSlotTemplate? existing,
    int? index,
  }) async {
    int selectedDay = existing?.dayOfWeek ?? availableDays.first.dayOfWeek;
    String? startTime = existing?.startTime;
    String? endTime = existing?.endTime;
    final seatController = TextEditingController(
      text: (existing?.seatCapacity ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add slot' : 'Edit slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      items: availableDays
                          .map(
                            (day) => DropdownMenuItem<int>(
                              value: day.dayOfWeek,
                              child: Text(day.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedDay = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: seatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seat capacity',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: _parseTime(startTime) ??
                                    const TimeOfDay(hour: 12, minute: 0),
                              );
                              if (picked != null) {
                                setDialogState(
                                  () => startTime = _formatTime(picked),
                                );
                              }
                            },
                            child: Text(startTime ?? 'Start time'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: _parseTime(endTime) ??
                                    const TimeOfDay(hour: 13, minute: 0),
                              );
                              if (picked != null) {
                                setDialogState(
                                  () => endTime = _formatTime(picked),
                                );
                              }
                            },
                            child: Text(endTime ?? 'End time'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final seats = int.tryParse(seatController.text.trim());
                    if (seats == null || seats <= 0) {
                      Helper.showToast('Enter a valid seat capacity.');
                      return;
                    }
                    if (startTime == null || endTime == null) {
                      Helper.showToast('Choose both start and end times.');
                      return;
                    }
                    if (!_isEndAfterStart(startTime!, endTime!)) {
                      Helper.showToast('End time must be after start time.');
                      return;
                    }
                    final timing = _timingForDay(
                      state.daysTimingOriginal,
                      selectedDay,
                    );
                    if (timing == null ||
                        !_fitsWithinWindow(
                          startTime: startTime!,
                          endTime: endTime!,
                          windowStart: timing.startTime,
                          windowEnd: timing.endTime,
                        )) {
                      Helper.showToast(
                        'Slots must stay within the kitchen opening hours for that day.',
                      );
                      return;
                    }
                    if (_overlapsExistingSlot(
                      slots: state.dineInSlots,
                      dayOfWeek: selectedDay,
                      startTime: startTime!,
                      endTime: endTime!,
                      excludeIndex: index,
                    )) {
                      Helper.showToast(
                        'This slot overlaps another dine-in slot on the same day.',
                      );
                      return;
                    }

                    final selectedOption = availableDays.firstWhere(
                      (day) => day.dayOfWeek == selectedDay,
                    );
                    context.read<CookProfileCubit>().addOrUpdateDineInSlot(
                          DineInSlotTemplate(
                            dayOfWeek: selectedDay,
                            dayName: selectedOption.label,
                            startTime: startTime,
                            endTime: endTime,
                            seatCapacity: seats,
                            status: 1,
                          ),
                          index: index,
                        );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_OpenDayOption> _resolveOpenDays(List<Days> days) {
    const mapping = <String, _OpenDayOption>{
      'Sun': _OpenDayOption(0, 'Sunday'),
      'Mon': _OpenDayOption(1, 'Monday'),
      'Tue': _OpenDayOption(2, 'Tuesday'),
      'Wed': _OpenDayOption(3, 'Wednesday'),
      'Thus': _OpenDayOption(4, 'Thursday'),
      'Thu': _OpenDayOption(4, 'Thursday'),
      'Fri': _OpenDayOption(5, 'Friday'),
      'Sat': _OpenDayOption(6, 'Saturday'),
    };

    return days
        .where((day) => day.isOn == true && mapping.containsKey(day.day ?? ''))
        .map((day) => mapping[day.day ?? '']!)
        .toSet()
        .toList(growable: false)
      ..sort((left, right) => left.dayOfWeek.compareTo(right.dayOfWeek));
  }

  static String _labelForDay(int? dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Day';
    }
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static bool _isEndAfterStart(String start, String end) =>
      _compareTime(end, start) > 0;

  static Timing? _timingForDay(List<Days> days, int dayOfWeek) {
    final labels = <int, List<String>>{
      0: ['Sun'],
      1: ['Mon'],
      2: ['Tue'],
      3: ['Wed'],
      4: ['Thu', 'Thus'],
      5: ['Fri'],
      6: ['Sat'],
    };

    for (final day in days) {
      if (day.isOn == true &&
          labels[dayOfWeek]!.contains(day.day) &&
          day.timing != null) {
        return day.timing;
      }
    }
    return null;
  }

  static bool _fitsWithinWindow({
    required String startTime,
    required String endTime,
    required String? windowStart,
    required String? windowEnd,
  }) {
    if (windowStart == null || windowEnd == null) return false;
    return _compareTime(startTime, windowStart) >= 0 &&
        _compareTime(endTime, windowEnd) <= 0;
  }

  static bool _overlapsExistingSlot({
    required List<DineInSlotTemplate> slots,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? excludeIndex,
  }) {
    for (var i = 0; i < slots.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;
      final slot = slots[i];
      if (slot.dayOfWeek != dayOfWeek ||
          slot.startTime == null ||
          slot.endTime == null) {
        continue;
      }
      if (_compareTime(startTime, slot.endTime!) < 0 &&
          _compareTime(endTime, slot.startTime!) > 0) {
        return true;
      }
    }
    return false;
  }

  static int _compareTime(String left, String right) {
    final leftParts = left.split(':');
    final rightParts = right.split(':');
    final leftMinutes = ((int.tryParse(leftParts[0]) ?? 0) * 60) +
        (int.tryParse(leftParts[1]) ?? 0);
    final rightMinutes = ((int.tryParse(rightParts[0]) ?? 0) * 60) +
        (int.tryParse(rightParts[1]) ?? 0);
    return leftMinutes.compareTo(rightMinutes);
  }
}

class _OpenDayOption {
  const _OpenDayOption(this.dayOfWeek, this.label);

  final int dayOfWeek;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is _OpenDayOption && other.dayOfWeek == dayOfWeek;

  @override
  int get hashCode => dayOfWeek.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Kitchen Name
// ─────────────────────────────────────────────────────────────────────────────
class _KitchenName extends StatefulWidget {
  final _CookProfilePage? loginForm;

  const _KitchenName({this.loginForm});

  @override
  State<_KitchenName> createState() => _KitchenNameState();
}

class _KitchenNameState extends State<_KitchenName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return MitablTextField(
          hint: "e.g. Grandma's Secret Hearth",
          errorText:
              state.nameKitchn!.invalid ? 'Please enter a valid name' : null,
          onChanged: (text) {
            context.read<CookProfileCubit>().onKitchnNameChanged(value: text);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number of Seats
// ─────────────────────────────────────────────────────────────────────────────
class _NoOfSeats extends StatefulWidget {
  final _CookProfilePage? loginForm;

  const _NoOfSeats({this.loginForm});

  @override
  State<_NoOfSeats> createState() => _NoOfSeatsState();
}

class _NoOfSeatsState extends State<_NoOfSeats> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return MitablTextField(
          hint: 'Enter total seating capacity',
          keyboardType: TextInputType.number,
          errorText: state.noOfSeats.invalid
              ? 'Please enter a valid number of seats'
              : null,
          onChanged: (text) {
            context.read<CookProfileCubit>().onSeatChanged(value: text);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone Number
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneNo extends StatefulWidget {
  final _CookProfilePage? loginForm;

  const _PhoneNo({this.loginForm});

  @override
  State<_PhoneNo> createState() => _PhoneNoState();
}

class _PhoneNoState extends State<_PhoneNo> {
  late final TextEditingController _countryCodeController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _countryCodeController = TextEditingController(text: '+61');
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: _countryCodeController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                maxLength: 5,
                style: const TextStyle(
                  fontSize: 15,
                  color: MitablColors.onSurface,
                ),
                onChanged: (value) {
                  context.read<CookProfileCubit>().onCountryCodeChanged(
                        value: value,
                        localNumber: _phoneController.text,
                      );
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '+61',
                  filled: true,
                  fillColor: MitablColors.surfaceContainerLow,
                  border: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide(
                      color: MitablColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintStyle: TextStyle(
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 14,
                style: const TextStyle(
                  fontSize: 15,
                  color: MitablColors.onSurface,
                ),
                onChanged: (text) {
                  context.read<CookProfileCubit>().onPhoneChanged(
                        value: InternationalPhone.compose(
                          countryCode: _countryCodeController.text,
                          number: text,
                        ),
                      );
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Phone number',
                  errorText: state.phone.invalid
                      ? 'Enter valid country code and phone no'
                      : null,
                  filled: true,
                  fillColor: MitablColors.surfaceContainerLow,
                  border: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide(
                      color: MitablColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide(color: MitablColors.error, width: 1),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: MitablRadius.inputBorder,
                    borderSide: BorderSide(color: MitablColors.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintStyle: TextStyle(
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload Button
// ─────────────────────────────────────────────────────────────────────────────
class _UploadButton extends StatefulWidget {
  const _UploadButton({this.loginForm});

  final _CookProfilePage? loginForm;

  @override
  _UploadbuttonState createState() => _UploadbuttonState();
}

class _UploadbuttonState extends State<_UploadButton> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CookProfileCubit, CookProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            if (state.pathFiles.length <= 4) {
              showDialog<bool>(
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      'Add image',
                      style: GoogleFonts.nunito(
                        color: MitablColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MitablButton(
                          label: 'Gallery',
                          variant: MitablButtonVariant.secondary,
                          onPressed: () {
                            navigatorKey.currentState!.pop(false);
                          },
                        ),
                        const SizedBox(height: 12),
                        MitablButton(
                          label: 'Camera',
                          variant: MitablButtonVariant.secondary,
                          onPressed: () {
                            navigatorKey.currentState!.pop(true);
                          },
                        ),
                      ],
                    ),
                  );
                },
                context: context,
              ).then((value) {
                if (!context.mounted) return;
                if (value != null) {
                  if (value) {
                    _openCamera(context);
                  } else {
                    _openGallery(context);
                  }
                }
              });
            } else {
              Helper.showToast('Photos limit reached.');
            }
          },
          child: Semantics(
            button: true,
            label: 'Add kitchen photo',
            hint: 'Choose from gallery or capture from camera.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLowest,
                borderRadius: MitablRadius.pillBorder,
                boxShadow: [
                  BoxShadow(
                    color: MitablColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo,
                      size: 18, color: MitablColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Add Kitchen Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.primary,
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

  void _openGallery(BuildContext context) async {
    final cubit = context.read<CookProfileCubit>();
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (!context.mounted || picture == null) return;
      cubit.onNewImageAdded(path: picture.path);
      if (widget.loginForm?.controller?.hasClients ?? false) {
        widget.loginForm!.controller!.jumpTo(
          widget.loginForm!.controller!.position.maxScrollExtent,
        );
      }
    } catch (e) {
      Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    final cubit = context.read<CookProfileCubit>();
    final picture = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    try {
      if (!context.mounted || picture == null) {
        Helper.showToast('No image captured.');
        return;
      }
      cubit.onNewImageAdded(path: picture.path);
      if (widget.loginForm?.controller?.hasClients ?? false) {
        widget.loginForm!.controller!.jumpTo(
          widget.loginForm!.controller!.position.maxScrollExtent,
        );
      }
    } catch (e) {
      Helper.showToast('No image captured.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit / Next Button
// ─────────────────────────────────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  final _CookProfilePage? loginForm;

  const _LoginButton({this.loginForm});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        final isEnabled = state.status!.isValidated;
        return SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            enabled: isEnabled,
            label: 'Next. Setup payout.',
            hint: 'Saves kitchen profile and continues to payout setup.',
            child: Container(
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? const LinearGradient(
                        colors: [
                          MitablColors.primary,
                          MitablColors.primaryContainer
                        ],
                      )
                    : null,
                color: isEnabled ? null : MitablColors.tertiaryFixedDim,
                borderRadius: MitablRadius.pillBorder,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: MitablColors.primary.withValues(alpha: 0.2),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled
                      ? () {
                          context.read<CookProfileCubit>().onKitchnUpload();
                        }
                      : null,
                  borderRadius: MitablRadius.pillBorder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next: Setup Payout',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isEnabled
                                ? MitablColors.onPrimary
                                : MitablColors.onPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward,
                          color: isEnabled
                              ? MitablColors.onPrimary
                              : MitablColors.onPrimary.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
