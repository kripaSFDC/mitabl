import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import '../../../helper/helper.dart';
import '../../../helper/route_arguement.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
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
          shape: RoundedRectangleBorder(
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
      appBar: const GlassAppBar(title: Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: MitablSpacing.pagePadding,
          right: MitablSpacing.pagePadding,
          bottom: MediaQuery.of(context).padding.bottom +
              MediaQuery.of(context).viewInsets.bottom +
              32,
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar section
            _buildAvatarSection(),

            const SizedBox(height: MitablSpacing.listItem),

            // Personal Information
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
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
                        label: 'First Name',
                        hint: 'First Name',
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
                        controller: lastName,
                        label: 'Last Name',
                        hint: 'Last Name',
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        errorText: state.lastName!.invalid
                            ? 'Please enter a valid last name'
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Contact Details
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Details',
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
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileFoodieCubit, ProfileFoodieState>(
                    builder: (context, state) {
                      return MitablTextField(
                        controller: phone,
                        label: 'Phone',
                        hint: 'Phone',
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        errorText: state.phoneNo!.invalid
                            ? 'Please enter a valid phone no'
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Description
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
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
                        controller: description,
                        label: 'Description',
                        hint: 'Tell us about yourself...',
                        textInputAction: TextInputAction.done,
                        maxLines: 4,
                        errorText: state.description!.invalid
                            ? 'Please enter a valid description'
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Preferences (visual placeholder)
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
                    children: const [
                      MitablChip(label: 'Vegetarian'),
                      MitablChip(label: 'Vegan'),
                      MitablChip(label: 'Gluten-Free'),
                      MitablChip(label: 'Halal'),
                      MitablChip(label: 'Keto'),
                      MitablChip(label: 'Dairy-Free'),
                    ],
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
                  Navigator.of(context).pop(true);
                }
              },
              builder: (context, state) {
                return MitablButton(
                  label: 'Save Changes',
                  isLoading: state.statusUpload!.isSubmissionInProgress,
                  onPressed: state.status!.isValidated
                      ? () {
                          context
                              .read<ProfileFoodieCubit>()
                              .updateFoodieProfile();
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
