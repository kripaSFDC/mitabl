import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/timing_model.dart';
import 'package:mitabl_user/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_cubit.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

import '../../../helper/helper.dart';
import '../elements/timing_edit.dart';

class EditKitchenProfilePage extends StatefulWidget {
  const EditKitchenProfilePage({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => EditKitchenProfileCubit(
          routeArguments: routeArguments,
          userRepository: context.read<UserRepository>(),
        ),
        child: EditKitchenProfilePage(routeArguments: routeArguments),
      ),
    );
  }

  @override
  State<EditKitchenProfilePage> createState() => _EditKitchenProfilePageState();
}

class _EditKitchenProfilePageState extends State<EditKitchenProfilePage> {
  TextEditingController? nameTextEditor = TextEditingController();
  TextEditingController? addressTextEditor = TextEditingController();
  TextEditingController? noOfSeatsTextEditor = TextEditingController();
  TextEditingController? abnNoTextEditor = TextEditingController();
  TextEditingController? certificateTextEditor = TextEditingController();
  TextEditingController? bioTextEditor = TextEditingController();
  TextEditingController? mobileNoTextEditor = TextEditingController();

  PageController? controller = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    final kitchen = widget.routeArguments?.kitchen;
    nameTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onKitchnNameChanged(
            value: nameTextEditor!.text,
          );
    });

    addressTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onAddressChanged(
            value: addressTextEditor!.text,
          );
    });
    mobileNoTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onPhoneChanged(
            value: mobileNoTextEditor!.text,
          );
    });
    noOfSeatsTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onSeatChanged(
            value: noOfSeatsTextEditor!.text,
          );
    });

    abnNoTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onAbnChanged(
            value: abnNoTextEditor!.text,
          );
    });
    certificateTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onCertificateNoChanged(
            value: certificateTextEditor!.text,
          );
    });
    bioTextEditor!.addListener(() {
      context.read<EditKitchenProfileCubit>().onBioChanged(
            value: bioTextEditor!.text,
          );
    });

    nameTextEditor!.text = kitchen?.name ?? '';
    addressTextEditor!.text = kitchen?.address ?? '';
    mobileNoTextEditor!.text = kitchen?.phone ?? '';
    noOfSeatsTextEditor!.text = kitchen?.noOfSeats?.toString() ?? '';
    abnNoTextEditor!.text = kitchen?.abn ?? '';
    certificateTextEditor!.text = kitchen?.certificateNo ?? '';
    bioTextEditor!.text = kitchen?.description ?? '';
  }

  @override
  void dispose() {
    nameTextEditor?.dispose();
    addressTextEditor?.dispose();
    noOfSeatsTextEditor?.dispose();
    abnNoTextEditor?.dispose();
    certificateTextEditor?.dispose();
    bioTextEditor?.dispose();
    mobileNoTextEditor?.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: MitablColors.surface,
          body: Stack(
            children: [
              Column(
                children: [
                  // TopAppBar
                  SafeArea(
                    bottom: false,
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: MitablColors.surface.withValues(alpha: 0.80),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back,
                                color: MitablColors.primary),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'mitabl',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: MitablColors.primary,
                            ),
                          ),
                          const Spacer(),
                          // Profile avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: MitablColors.primary
                                    .withValues(alpha: 0.10),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.person,
                                color: MitablColors.onSurfaceVariant,
                                size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(context).padding.bottom +
                            MediaQuery.of(context).viewInsets.bottom +
                            config.AppConfig(context).appHeight(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          const Text(
                            'SETTINGS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: MitablColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.isCreateMode
                                ? 'Add Kitchen Profile'
                                : 'Edit Kitchen Profile',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: MitablColors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage how your miKitchn appears to guests.',
                            style: TextStyle(
                              fontSize: 16,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Go Live toggle card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: MitablColors.outlineVariant
                                    .withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Go Live Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: MitablColors.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Kitchen is visible',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF506140),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: true,
                                  activeThumbColor: const Color(0xFF506140),
                                  activeTrackColor:
                                      MitablColors.secondaryContainer,
                                  onChanged: (_) {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // General Information card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'General Information',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                MitablTextField(
                                  controller: nameTextEditor,
                                  label: 'Kitchen Name',
                                  hint: 'Enter kitchen name',
                                  errorText: state.nameKitchn!.invalid
                                      ? 'Please enter a valid name'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                MitablTextField(
                                  controller: addressTextEditor,
                                  label: 'Location Address',
                                  hint: 'Kitchen address',
                                  errorText: state.address!.invalid
                                      ? 'Please enter a valid address'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Guest Space card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: MitablColors.secondaryContainer
                                  .withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: MitablColors.secondaryContainer,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guest Space',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                MitablTextField(
                                  controller: noOfSeatsTextEditor,
                                  label: 'Dine-in Capacity',
                                  hint: 'Enter number of seats',
                                  keyboardType: TextInputType.number,
                                  errorText: state.noOfSeats.invalid
                                      ? 'Please enter valid seats'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                // Pro Tip
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: MitablColors.surfaceContainerLowest
                                        .withValues(alpha: 0.50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: MitablColors.secondaryContainer
                                          .withValues(alpha: 0.50),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: Color(0xFF506140),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Pro Tip',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: MitablColors
                                                    .onSecondaryContainer,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Keeping capacity accurate helps us manage your booking slots effectively during peak hours.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: MitablColors
                                                    .onSecondaryContainer
                                                    .withValues(alpha: 0.80),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Kitchen Story card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kitchen Story',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                MitablTextField(
                                  controller: bioTextEditor,
                                  label: 'Long Description',
                                  hint:
                                      'Tell your guests about your culinary journey...',
                                  maxLines: 5,
                                  errorText: state.bio!.invalid
                                      ? 'Please enter a valid bio'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Operating Hours card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Operating Hours',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Day rows from state
                                ...List.generate(
                                  (state.daysTimingOriginal ??
                                          state.daysTiming)
                                      .length,
                                  (index) {
                                    final day =
                                        (state.daysTimingOriginal ??
                                            state.daysTiming)[index];
                                    final isOn = day.isOn ?? false;
                                    final dayLabel =
                                        _dayAbbrev(day.day.toString());
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            child: Text(
                                              dayLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: MitablColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          if (isOn &&
                                              day.timing != null) ...[
                                            _MiniTimeBox(
                                                time: day.timing!
                                                        .startTime ??
                                                    '--:--'),
                                            const Padding(
                                              padding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: Text(
                                                '-',
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 12,
                                                  color: Color(
                                                      0xFF64748B),
                                                ),
                                              ),
                                            ),
                                            _MiniTimeBox(
                                                time: day.timing!
                                                        .endTime ??
                                                    '--:--'),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () =>
                                                  _openTimingDialog(
                                                      context),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color:
                                                    Color(0xFF64748B),
                                              ),
                                            ),
                                          ] else ...[
                                            const Text(
                                              'Closed',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: MitablColors
                                                    .outlineVariant,
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () =>
                                                  _openTimingDialog(
                                                      context),
                                              child: const Icon(
                                                Icons.add_circle_outline,
                                                size: 16,
                                                color:
                                                    Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Kitchen Gallery card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Kitchen Gallery',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: MitablColors.onSurface,
                                      ),
                                    ),
                                    _UploadButton(loginForm: this),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Image grid
                                SizedBox(
                                  height: 256,
                                  child: state.pathFiles.isNotEmpty
                                      ? GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                          ),
                                          itemCount:
                                              state.pathFiles.length > 4
                                                  ? 4
                                                  : state.pathFiles.length,
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  CachedNetworkImage(
                                                    imageUrl:
                                                        '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                                    fit: BoxFit.cover,
                                                    errorWidget:
                                                        (context, data,
                                                            e) {
                                                      return Image.file(
                                                        File(state
                                                            .pathFiles[
                                                                index]
                                                            .path!),
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (context, data,
                                                                e) {
                                                          return const Icon(
                                                              Icons
                                                                  .error_outline);
                                                        },
                                                      );
                                                    },
                                                  ),
                                                  // Delete overlay
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        context
                                                            .read<
                                                                EditKitchenProfileCubit>()
                                                            .onDeleteImage(
                                                              path: state
                                                                  .pathFiles[
                                                                      index]
                                                                  .path,
                                                              imagesCook: state
                                                                      .pathFiles[
                                                                  index],
                                                            );
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: MitablColors
                                                              .primary
                                                              .withValues(
                                                                  alpha:
                                                                      0.20),
                                                          shape: BoxShape
                                                              .circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .delete_outline,
                                                          color:
                                                              Colors.white,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: MitablColors
                                                  .outlineVariant
                                                  .withValues(alpha: 0.30),
                                              width: 2,
                                              strokeAlign: BorderSide
                                                  .strokeAlignInside,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              color: Color(0xFF64748B),
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Service Options card
                          MitablCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Options',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dine-in',
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: MitablColors.onSurface,
                                      ),
                                    ),
                                    Switch(
                                      value: state.dineIn ?? false,
                                      activeThumbColor: MitablColors.accent,
                                      onChanged: (value) {
                                        context
                                            .read<EditKitchenProfileCubit>()
                                            .onDineInChange(value: value);
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Takeaway',
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: MitablColors.onSurface,
                                      ),
                                    ),
                                    Switch(
                                      value: state.takeAway ?? false,
                                      activeThumbColor: MitablColors.accent,
                                      onChanged: (value) {
                                        context
                                            .read<EditKitchenProfileCubit>()
                                            .onTakeAwayChange(value: value);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: MitablSpacing.listItem),

                          // Dine-in slots
                          const _DineInSlotSection(),
                          const SizedBox(height: MitablSpacing.listItem),

                          // Additional fields
                          MitablTextField(
                            controller: mobileNoTextEditor,
                            label: 'Phone',
                            hint: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                            errorText: state.phone.invalid
                                ? 'Please enter a valid phone no'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          MitablTextField(
                            controller: abnNoTextEditor,
                            label: 'ABN',
                            hint: 'Enter ABN',
                          ),
                          const SizedBox(height: 16),
                          MitablTextField(
                            controller: certificateTextEditor,
                            label: 'Certificate No.',
                            hint: 'Enter certificate number',
                          ),
                          const SizedBox(height: 32),

                          // Save bar
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          MitablColors.onSurfaceVariant,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            MitablRadius.pillBorder,
                                      ),
                                    ),
                                    child: const Text(
                                      'Discard',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MitablButton(
                                  label: 'Save Changes',
                                  variant: MitablButtonVariant.primary,
                                  isLoading:
                                      state.statusApi!.isSubmissionInProgress,
                                  onPressed: state.status!.isValidated
                                      ? () {
                                          context
                                              .read<
                                                  EditKitchenProfileCubit>()
                                              .onKitchenEditUpload();
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTimingDialog(BuildContext context) {
    context.read<EditKitchenProfileCubit>().onOpenTimingDialog();
    showDialog(
      context: context,
      builder: (contexts) {
        return BlocProvider.value(
          value: context.read<EditKitchenProfileCubit>(),
          child: EditTimingDialog(),
        );
      },
    );
  }

  static String _dayAbbrev(String dayName) {
    if (dayName.length >= 3) {
      return dayName.substring(0, 3);
    }
    return dayName;
  }
}

class _MiniTimeBox extends StatelessWidget {
  const _MiniTimeBox({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MitablColors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Dine-In Slot Section ──

class _DineInSlotSection extends StatelessWidget {
  const _DineInSlotSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
      builder: (context, state) {
        final availableDays = _resolveOpenDays(
          state.daysTimingOriginal ?? state.daysTiming,
        );

        return MitablCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dine-in timeslots',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: state.dineIn == true && availableDays.isNotEmpty
                        ? () => _showSlotEditor(
                              context,
                              state: state,
                              availableDays: availableDays,
                            )
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add slot'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Create bookable tables by day, time, and seat capacity.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (state.dineIn != true)
                Text(
                  'Enable dine-in to manage dine-in slots.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: MitablColors.onSurfaceVariant,
                  ),
                )
              else if (availableDays.isEmpty)
                Text(
                  'Open at least one kitchen day before adding slots.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: MitablColors.onSurfaceVariant,
                  ),
                )
              else if (state.dineInSlotsStatus.isSubmissionInProgress)
                const Center(child: CircularProgressIndicator())
              else if (state.dineInSlots.isEmpty)
                Text(
                  'No dine-in slots added yet.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: MitablColors.onSurfaceVariant,
                  ),
                )
              else
                ...List<Widget>.generate(state.dineInSlots.length, (index) {
                  final slot = state.dineInSlots[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MitablRadius.card),
                    ),
                    child: ListTile(
                      title: Text(
                        '${slot.dayName ?? _labelForDay(slot.dayOfWeek)}  ${slot.startTime ?? '--:--'} - ${slot.endTime ?? '--:--'}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Seats: ${slot.seatCapacity ?? 0}',
                        style: GoogleFonts.nunito(
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: () => _showSlotEditor(
                              context,
                              state: state,
                              availableDays: availableDays,
                              existing: slot,
                              index: index,
                            ),
                            icon: const Icon(Icons.edit_outlined,
                                color: MitablColors.primary, size: 20),
                          ),
                          IconButton(
                            onPressed: () => context
                                .read<EditKitchenProfileCubit>()
                                .deleteDineInSlot(index),
                            icon: const Icon(Icons.delete_outline,
                                color: MitablColors.error, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSlotEditor(
    BuildContext context, {
    required EditKitchenProfileState state,
    required List<_OpenDayOption> availableDays,
    DineInSlotTemplate? existing,
    int? index,
  }) async {
    int selectedDay = existing?.dayOfWeek ?? availableDays.first.dayOfWeek;
    String? startTime = existing?.startTime;
    String? endTime = existing?.endTime;
    bool enabled = (existing?.status ?? 1) == 1;
    final seatController = TextEditingController(
      text: (existing?.seatCapacity ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: MitablColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MitablRadius.card),
              ),
              title: Text(
                existing == null ? 'Add slot' : 'Edit slot',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onSurface,
                ),
              ),
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
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedDay = value;
                        });
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
                          child: MitablButton(
                            label: startTime == null || startTime!.isEmpty
                                ? 'Start time'
                                : startTime!,
                            variant: MitablButtonVariant.outline,
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: _parseTimeOfDay(startTime) ??
                                    const TimeOfDay(hour: 12, minute: 0),
                              );
                              if (picked == null) {
                                return;
                              }

                              setDialogState(() {
                                startTime = _formatTime(picked);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MitablButton(
                            label: endTime == null || endTime!.isEmpty
                                ? 'End time'
                                : endTime!,
                            variant: MitablButtonVariant.outline,
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: _parseTimeOfDay(endTime) ??
                                    const TimeOfDay(hour: 13, minute: 0),
                              );
                              if (picked == null) {
                                return;
                              }

                              setDialogState(() {
                                endTime = _formatTime(picked);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      title: Text(
                        'Slot enabled',
                        style: GoogleFonts.nunito(
                          color: MitablColors.onSurface,
                        ),
                      ),
                      activeThumbColor: MitablColors.accent,
                      onChanged: (value) {
                        setDialogState(() {
                          enabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                MitablButton(
                  label: 'Save',
                  variant: MitablButtonVariant.primary,
                  fullWidth: false,
                  onPressed: () {
                    final capacity = int.tryParse(seatController.text.trim());
                    if (capacity == null || capacity <= 0) {
                      Helper.showToast('Enter a valid seat capacity.');
                      return;
                    }
                    if (startTime == null ||
                        startTime!.isEmpty ||
                        endTime == null ||
                        endTime!.isEmpty) {
                      Helper.showToast('Choose both start and end times.');
                      return;
                    }
                    if (!_isEndAfterStart(startTime!, endTime!)) {
                      Helper.showToast('End time must be after start time.');
                      return;
                    }

                    final selectedDayTiming = _timingForDay(
                      state.daysTimingOriginal ?? state.daysTiming,
                      selectedDay,
                    );

                    if (selectedDayTiming == null) {
                      Helper.showToast(
                        'Select an open kitchen day before adding a slot.',
                      );
                      return;
                    }
                    if (!_fitsWithinWindow(
                      startTime: startTime!,
                      endTime: endTime!,
                      windowStart: selectedDayTiming.startTime,
                      windowEnd: selectedDayTiming.endTime,
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

                    context
                        .read<EditKitchenProfileCubit>()
                        .addOrUpdateDineInSlot(
                          DineInSlotTemplate(
                            id: existing?.id,
                            dayOfWeek: selectedDay,
                            dayName: selectedOption.label,
                            startTime: startTime,
                            endTime: endTime,
                            seatCapacity: capacity,
                            status: enabled ? 1 : 0,
                          ),
                          index: index,
                        );

                    Navigator.of(dialogContext).pop();
                  },
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

  static TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static bool _isEndAfterStart(String start, String end) {
    final startParts = start.split(':');
    final endParts = end.split(':');
    if (startParts.length < 2 || endParts.length < 2) {
      return false;
    }

    final startMinutes = ((int.tryParse(startParts[0]) ?? 0) * 60) +
        (int.tryParse(startParts[1]) ?? 0);
    final endMinutes = ((int.tryParse(endParts[0]) ?? 0) * 60) +
        (int.tryParse(endParts[1]) ?? 0);

    return endMinutes > startMinutes;
  }

  static Timing? _timingForDay(List<Days> days, int dayOfWeek) {
    final dayLabels = <int, List<String>>{
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
          dayLabels[dayOfWeek]!.contains(day.day) &&
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
    if (windowStart == null ||
        windowStart.isEmpty ||
        windowEnd == null ||
        windowEnd.isEmpty) {
      return false;
    }

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
      if (excludeIndex != null && i == excludeIndex) {
        continue;
      }

      final slot = slots[i];
      if (slot.dayOfWeek != dayOfWeek ||
          slot.startTime == null ||
          slot.endTime == null) {
        continue;
      }

      final startsBeforeExistingEnds =
          _compareTime(startTime, slot.endTime!) < 0;
      final endsAfterExistingStarts =
          _compareTime(endTime, slot.startTime!) > 0;
      if (startsBeforeExistingEnds && endsAfterExistingStarts) {
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
  bool operator ==(Object other) {
    return other is _OpenDayOption && other.dayOfWeek == dayOfWeek;
  }

  @override
  int get hashCode => dayOfWeek.hashCode;
}

// ── Upload Button ──

class _UploadButton extends StatefulWidget {
  const _UploadButton({this.loginForm});

  final _EditKitchenProfilePageState? loginForm;

  @override
  _UploadbuttonState createState() => _UploadbuttonState();
}

class _UploadbuttonState extends State<_UploadButton> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return TextButton.icon(
          onPressed: () {
            if (state.pathFiles.length <= 4) {
              showDialog<bool>(
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: MitablColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MitablRadius.card),
                    ),
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
                          variant: MitablButtonVariant.primary,
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18, color: MitablColors.onPrimary),
                          onPressed: () {
                            navigatorKey.currentState!.pop(false);
                          },
                        ),
                        const SizedBox(height: 12),
                        MitablButton(
                          label: 'Camera',
                          variant: MitablButtonVariant.outline,
                          icon: const Icon(Icons.camera_alt_outlined,
                              size: 18, color: MitablColors.primary),
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
          icon: const Icon(Icons.add_a_photo_outlined,
              size: 18, color: MitablColors.primary),
          label: const Text(
            'Add Images',
            style: TextStyle(
              color: MitablColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  void _openGallery(BuildContext context) async {
    final cubit = context.read<EditKitchenProfileCubit>();
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (!context.mounted || picture == null) {
        Helper.showToast('No image selected.');
        return;
      }

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
    final cubit = context.read<EditKitchenProfileCubit>();
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
