import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import '../../../helper/helper.dart';
import '../../../helper/route_arguement.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileFoodiePage extends StatefulWidget {
  const EditProfileFoodiePage({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => const EditProfileFoodiePage(),
    );
  }

  @override
  State<EditProfileFoodiePage> createState() => _EditProfileFoodiePageState();
}

class _EditProfileFoodiePageState extends State<EditProfileFoodiePage> {
  TextEditingController? firstName = TextEditingController();
  TextEditingController? lastName = TextEditingController();
  TextEditingController? email = TextEditingController();
  TextEditingController? phone = TextEditingController();
  TextEditingController? description = TextEditingController();

  static const _prefKey = 'foodie_dietary_prefs';

  /// API ID to label mapping for dietary preferences.
  // ignore: unused_field
  static const Map<int, String> _dietaryIdToLabel = {
    1: 'Vegan',
    2: 'Gluten Free',
    3: 'Halal',
    4: 'Kosher',
    5: 'Contains Dairy',
    6: 'Spicy',
    7: 'Contains Tree nut',
    8: 'Contains Fish',
  };

  Set<int> _selectedDietaryPrefs = {};
  bool _isSavingDietary = false;

  @override
  void initState() {
    super.initState();
    _loadDietaryPrefs();
    context.read<ProfileFoodieCubit>().resetSubmissionStatus();
    firstName!.addListener(() {
      context.read<ProfileFoodieCubit>().onFirstNameChanged(
            value: firstName!.text,
          );
    });
    lastName!.addListener(() {
      context.read<ProfileFoodieCubit>().onLastNameChanged(
            value: lastName!.text,
          );
    });
    email!.addListener(() {
      context.read<ProfileFoodieCubit>().onEmailChanged(value: email!.text);
    });
    phone!.addListener(() {
      context.read<ProfileFoodieCubit>().onPhoneChanged(value: phone!.text);
    });
    description!.addListener(() {
      context.read<ProfileFoodieCubit>().onDescriptionChanged(
            value: description!.text,
          );
    });

    firstName!.text = context.read<ProfileFoodieCubit>().state.firstName!.value;
    lastName!.text = context.read<ProfileFoodieCubit>().state.lastName!.value;
    description!.text =
        context.read<ProfileFoodieCubit>().state.description!.value;
    email!.text = context.read<ProfileFoodieCubit>().state.email!.value;
    phone!.text = context.read<ProfileFoodieCubit>().state.phoneNo!.value;
  }

  @override
  void dispose() {
    firstName?.dispose();
    lastName?.dispose();
    email?.dispose();
    phone?.dispose();
    description?.dispose();
    super.dispose();
  }

  Future<void> _loadDietaryPrefs() async {
    // Try API first, fall back to SharedPreferences
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final headers = authorizedHeadersForUser(
        userModel,
        includeJsonContentType: true,
      );

      final response = await http.get(
        ApiContract.uri('v2/account/dietary-preferences'),
        headers: headers,
      ).timeout(ApiContract.requestTimeout);

      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = body['preferences'];
        if (prefs is List) {
          final ids = prefs.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toSet();
          setState(() {
            _selectedDietaryPrefs = ids;
          });
          // Cache to SharedPreferences for offline fallback
          final sp = await SharedPreferences.getInstance();
          await sp.setStringList(
            _prefKey,
            ids.map((id) => id.toString()).toList(),
          );
          return;
        }
      }
    } catch (_) {
      // Fall through to SharedPreferences fallback
    }

    // Offline fallback: load from SharedPreferences
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getStringList(_prefKey);
    if (saved != null && mounted) {
      setState(() {
        _selectedDietaryPrefs =
            saved.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toSet();
      });
    }
  }

  Future<void> _saveDietaryPrefs() async {
    setState(() => _isSavingDietary = true);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final headers = authorizedHeadersForUser(
        userModel,
        includeJsonContentType: true,
      );

      final response = await http.put(
        ApiContract.uri('v2/account/dietary-preferences'),
        headers: headers,
        body: jsonEncode({
          'preference_ids': _selectedDietaryPrefs.toList(),
        }),
      ).timeout(ApiContract.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Also cache locally for offline fallback
        final sp = await SharedPreferences.getInstance();
        await sp.setStringList(
          _prefKey,
          _selectedDietaryPrefs.map((id) => id.toString()).toList(),
        );
      }
    } catch (_) {
      // Save locally as fallback even if API fails
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(
        _prefKey,
        _selectedDietaryPrefs.map((id) => id.toString()).toList(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDietary = false);
      }
    }
  }

  // ignore: unused_element
  void _toggleDietaryPref(int dietId) {
    setState(() {
      if (_selectedDietaryPrefs.contains(dietId)) {
        _selectedDietaryPrefs.remove(dietId);
      } else {
        _selectedDietaryPrefs.add(dietId);
      }
    });
  }

  void _openGallery() async {
    final cubit = context.read<ProfileFoodieCubit>();
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (!mounted || picture == null) {
        Helper.showToast('No image selected.');
        return;
      }

      cubit.onAvatarImageSelect(path: picture.path);
    } catch (e) {
      Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera() async {
    final cubit = context.read<ProfileFoodieCubit>();
    final picture = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    try {
      if (!mounted || picture == null) {
        Helper.showToast('No image captured.');
        return;
      }

      cubit.onAvatarImageSelect(path: picture.path);
    } catch (e) {
      Helper.showToast('No image captured.');
    }
  }

  void _showImagePickerDialog() {
    showDialog<bool>(
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: MitablRadius.cardBorder,
          ),
          title: const Text(
            'Update Photo',
            style: TextStyle(
              color: MitablColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: MitablColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: MitablColors.primary),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
      context: context,
    ).then((value) {
      if (!mounted) return;
      if (value != null) {
        if (value) {
          _openCamera();
        } else {
          _openGallery();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('miFoodi')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: MitablSpacing.pagePadding,
          right: MitablSpacing.pagePadding,
          bottom: MediaQuery.of(context).padding.bottom +
              MediaQuery.of(context).viewInsets.bottom +
              32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // ── Page Title: centered, large heading ──
            const Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Refine your culinary preferences and details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // ── Profile Photo Section: rotated square with edit FAB ──
            _buildAvatarSection(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: const Text(
                'CHANGE PHOTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.primary,
                  letterSpacing: 2.0,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Personal Details card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return MitablTextField(
                        controller: firstName,
                        label: 'Full Name',
                        hint: 'Enter your name',
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        errorText: state.firstName!.invalid
                            ? 'Please enter a valid first name'
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MitablColors.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Country code prefix
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: const BoxDecoration(
                                  color: MitablColors.surfaceContainerLowest,
                                  borderRadius: MitablRadius.inputBorder,
                                ),
                                child: const Text(
                                  '+1',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MitablTextField(
                                  controller: phone,
                                  hint: 'Phone number',
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.phone,
                                  errorText: state.phoneNo!.invalid
                                      ? 'Please enter a valid phone no'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MitablTextField(
                            controller: email,
                            label: 'Email Address',
                            hint: 'Email Address',
                            enabled: false,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            errorText: state.email!.invalid
                                ? 'Please enter a valid email id'
                                : null,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Email cannot be changed.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Delivery Address card with location icon ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        color: MitablColors.primary,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return MitablTextField(
                        controller: description,
                        label: 'Home Address',
                        hint: '123 Orchard Lane, Gastronomy District, NY 10001',
                        textInputAction: TextInputAction.done,
                        maxLines: 3,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Preferences Bento Grid: 2 square tiles ──
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: MitablColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: MitablColors.onSecondaryContainer,
                            size: 24,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUISINE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: Color(0xFF364C32),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Mediterranean',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3B4C2C),
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Color(0xFF475569),
                            size: 24,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREF. TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dinner (7PM)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF475569),
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Save Changes Button ──
            BlocConsumer<ProfileFoodieCubit, ProfileFoodieState>(
              listener: (context, state) {
                if (state.statusUpload!.isSubmissionSuccess &&
                    context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                  // Save dietary preferences alongside profile
                  _saveDietaryPrefs();
                }
              },
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (state.status!.isValidated &&
                              !state.statusUpload!.isSubmissionInProgress &&
                              !_isSavingDietary)
                          ? MitablColors.primaryGradient
                          : null,
                      color: (state.status!.isValidated &&
                              !state.statusUpload!.isSubmissionInProgress &&
                              !_isSavingDietary)
                          ? null
                          : MitablColors.tertiaryFixedDim,
                      borderRadius: MitablRadius.pillBorder,
                      boxShadow: (state.status!.isValidated &&
                              !state.statusUpload!.isSubmissionInProgress &&
                              !_isSavingDietary)
                          ? [
                              BoxShadow(
                                color: MitablColors.primary.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: MitablRadius.pillBorder,
                        onTap: (state.status!.isValidated &&
                                !state.statusUpload!.isSubmissionInProgress &&
                                !_isSavingDietary)
                            ? () {
                                context
                                    .read<ProfileFoodieCubit>()
                                    .updateFoodieProfile();
                                _saveDietaryPrefs();
                              }
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (state.statusUpload!.isSubmissionInProgress ||
                                _isSavingDietary)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MitablColors.onPrimary,
                                  ),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.check_circle,
                                  color: MitablColors.onPrimary,
                                  size: 20,
                                ),
                              ),
                            const Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onPrimary,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
      builder: (context, state) {
        final avatarPath = state.avatarPath ?? '';
        final remoteAvatar = state.foodieProfile?.data?.avatar;
        final imageUrl = remoteAvatar != null && remoteAvatar.isNotEmpty
            ? "${GlobalConfiguration().getValue<String>('base_url')}/$remoteAvatar"
            : '';

        Widget avatarImage;
        if (avatarPath.isNotEmpty) {
          avatarImage = Image.file(
            File(avatarPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else if (imageUrl.isNotEmpty) {
          avatarImage = CachedNetworkImage(
            imageUrl: imageUrl,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
              child: CircularProgressIndicator(
                value: downloadProgress.progress,
                color: MitablColors.primary,
              ),
            ),
            errorWidget: (context, url, error) => _defaultAvatarContent(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          avatarImage = _defaultAvatarContent();
        }

        return GestureDetector(
          onTap: _showImagePickerDialog,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rotated square avatar
              Transform.rotate(
                angle: 0.035, // ~2 degrees
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MitablColors.surfaceContainerLowest,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MitablColors.onSurface.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: avatarImage,
                  ),
                ),
              ),
              // Edit FAB
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MitablColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MitablColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: MitablColors.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultAvatarContent() {
    return Container(
      color: MitablColors.primaryContainer,
      child: const Center(
        child: Icon(
          Icons.person,
          color: MitablColors.onPrimary,
          size: 56,
        ),
      ),
    );
  }

}
