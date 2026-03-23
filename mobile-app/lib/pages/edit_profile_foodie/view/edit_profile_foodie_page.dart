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
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
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

  void _toggleDietaryPref(int dietId) {
    setState(() {
      if (_selectedDietaryPrefs.contains(dietId)) {
        _selectedDietaryPrefs.remove(dietId);
      } else {
        _selectedDietaryPrefs.add(dietId);
      }
    });
  }

  void _openGallery(BuildContext context) async {
    final cubit = context.read<ProfileFoodieCubit>();
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (!context.mounted || picture == null) {
        Helper.showToast('No image selected.');
        return;
      }

      cubit.onAvatarImageSelect(path: picture.path);
    } catch (e) {
      Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    final cubit = context.read<ProfileFoodieCubit>();
    final picture = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    try {
      if (!context.mounted || picture == null) {
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
      if (!context.mounted) return;
      if (value != null) {
        if (value) {
          _openCamera(context);
        } else {
          _openGallery(context);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── "Edit Profile" heading with subtitle ──
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Refine your culinary preferences and details',
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // ── Avatar section with CHANGE PHOTO label ──
            Center(
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: const Text(
                      'CHANGE PHOTO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Personal Details card: Full Name, Phone Number, Email Address ──
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return MitablTextField(
                        controller: firstName,
                        label: 'Full Name',
                        hint: 'Full Name',
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
                      return MitablTextField(
                        controller: phone,
                        label: 'Phone Number',
                        hint: 'Phone Number',
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 4),
                          child: Icon(Icons.phone_outlined,
                              size: 20, color: MitablColors.onSurfaceVariant),
                        ),
                        errorText: state.phoneNo!.invalid
                            ? 'Please enter a valid phone no'
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return MitablTextField(
                        controller: email,
                        label: 'Email Address',
                        hint: 'Email Address',
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        errorText: state.email!.invalid
                            ? 'Please enter a valid email id'
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Delivery Address card with location pin ──
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: MitablColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                          builder: (context, state) {
                            return MitablTextField(
                              controller: description,
                              label: 'Home Address',
                              hint: 'Enter your delivery address...',
                              textInputAction: TextInputAction.done,
                              maxLines: 2,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Preferences
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dietary preferences',
                    style: TextStyle(
                      fontSize: 13,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryIdToLabel.entries.map((entry) {
                      final isSelected =
                          _selectedDietaryPrefs.contains(entry.key);
                      return MitablChip(
                        label: entry.value,
                        selected: isSelected,
                        onSelected: (_) => _toggleDietaryPref(entry.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Update button
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
                return MitablButton(
                  label: 'SAVE CHANGES',
                  isLoading: state.statusUpload!.isSubmissionInProgress || _isSavingDietary,
                  onPressed: state.status!.isValidated
                      ? () {
                          context
                              .read<ProfileFoodieCubit>()
                              .updateFoodieProfile();
                          _saveDietaryPrefs();
                        }
                      : null,
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

        Widget avatarWidget;
        if (avatarPath.isNotEmpty) {
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.file(
              File(avatarPath),
              fit: BoxFit.cover,
              height: 100,
              width: 100,
            ),
          );
        } else if (imageUrl.isNotEmpty) {
          avatarWidget = CachedNetworkImage(
            imageUrl: imageUrl,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                CircularProgressIndicator(
              value: downloadProgress.progress,
              color: MitablColors.primary,
            ),
            errorWidget: (context, url, error) => _defaultAvatarWidget(),
            imageBuilder: (context, imageProvider) => Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          );
        } else {
          avatarWidget = _defaultAvatarWidget();
        }

        return GestureDetector(
          onTap: _showImagePickerDialog,
          child: Stack(
            children: [
              avatarWidget,
              // Semi-transparent edit overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MitablColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MitablColors.surface,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
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

  Widget _defaultAvatarWidget() {
    return Container(
      height: 100,
      width: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MitablColors.primaryContainer,
      ),
      child: const Icon(
        Icons.person,
        color: MitablColors.onPrimary,
        size: 48,
      ),
    );
  }
}
