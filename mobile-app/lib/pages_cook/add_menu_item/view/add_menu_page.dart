import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/special_diet.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/cooking_style_dialog.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/special_diet/cubit/special_diet_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/special_diet/special_diet_dialog.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => AddMenuPage(routeArguments: routeArguments),
    );
  }

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  Future<bool> _onBackPressed() async {
    context.read<AddMenuCubit>().resetFields();
    return true;
  }

  PageController? controller = PageController(viewportFraction: 0.9);
  TextEditingController itemNameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController cookingStyleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    itemNameController.addListener(() {
      context.read<AddMenuCubit>().onItemNameChange(
            value: itemNameController.text,
          );
    });
    priceController.addListener(() {
      context.read<AddMenuCubit>().onPriceChange(value: priceController.text);
    });
    descriptionController.addListener(() {
      context.read<AddMenuCubit>().onDescriptionChange(
            value: descriptionController.text,
          );
    });

    cookingStyleController.addListener(() {});
    cookingStyleController.text = context
        .read<AddMenuCubit>()
        .state
        .selectedCookingStyle!
        .name
        .toString();
    if (widget.routeArguments!.foodData != null) {
      CookingStyleData cookingStyleData =
          context.read<AddMenuCubit>().state.cookingStyleList.firstWhere(
                (element) =>
                    element.id == widget.routeArguments!.foodData!.cookingstyle,
              );
      cookingStyleController.text = cookingStyleData.name!;

      itemNameController.text = widget.routeArguments!.foodData!.foodName!;
      descriptionController.text =
          widget.routeArguments!.foodData!.description!;
      priceController.text = widget.routeArguments!.foodData!.price.toString();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    itemNameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    cookingStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.routeArguments!.isEdit!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (await _onBackPressed() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: MitablColors.surface,
        appBar: GlassAppBar(
          title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: MitablColors.onSurface),
            onPressed: () {
              if (!isEdit) {
                context.read<AddMenuCubit>().resetFields();
              }
              navigatorKey.currentState!.pop();
            },
          ),
        ),
        body: BlocConsumer<AddMenuCubit, AddMenuState>(
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: MitablSpacing.pagePadding,
                    right: MitablSpacing.pagePadding,
                    top: MitablSpacing.pagePadding,
                    bottom: MediaQuery.of(context).padding.bottom +
                        MediaQuery.of(context).viewInsets.bottom +
                        config.AppConfig(context).appHeight(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Photo Section ──
                      MitablCard(
                        child: Column(
                          children: [
                            // Image carousel or placeholder
                            ClipRRect(
                              borderRadius: BorderRadius.circular(MitablRadius.card - 4),
                              child: SizedBox(
                                height: config.AppConfig(context).appHeight(20),
                                child: state.pathFiles.isNotEmpty
                                    ? PageView.builder(
                                        padEnds: true,
                                        clipBehavior: Clip.hardEdge,
                                        controller: controller,
                                        onPageChanged: (page) {
                                          context
                                              .read<AddMenuCubit>()
                                              .onImageScroll(index: page);
                                        },
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          return Stack(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, data, e) {
                                                    return Image.file(
                                                      File(state
                                                          .pathFiles[index]
                                                          .path!),
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                  placeholder: (context, s) =>
                                                      Container(
                                                    color: MitablColors
                                                        .surfaceContainerLow,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 6,
                                                top: 6,
                                                child: InkWell(
                                                  splashFactory:
                                                      NoSplash.splashFactory,
                                                  onTap: () {
                                                    context
                                                        .read<AddMenuCubit>()
                                                        .onDeleteImage(
                                                          path: state
                                                              .pathFiles[index]
                                                              .path,
                                                          pictures: state
                                                              .pathFiles[index],
                                                        );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: MitablColors
                                                          .surface
                                                          .withValues(
                                                              alpha: 0.8),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_outline,
                                                      color:
                                                          MitablColors.error,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        itemCount: state.pathFiles.length,
                                      )
                                    : Container(
                                        color:
                                            MitablColors.surfaceContainerLow,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.photo_outlined,
                                          size: 64,
                                          color:
                                              MitablColors.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            ),
                            // Page dots
                            if (state.pathFiles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    state.pathFiles.length,
                                    (index) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
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
                            const SizedBox(height: 12),
                            // Upload button
                            const _UploadButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: MitablSpacing.listItem),

                      // ── Item Details ──
                      MitablTextField(
                        controller: itemNameController,
                        label: 'Item Name',
                        hint: 'Enter item name',
                        errorText: state.itemName!.invalid
                            ? 'Please enter a valid name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      MitablTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: 'Enter price',
                        keyboardType: TextInputType.number,
                        errorText: state.price!.invalid
                            ? 'Please enter a valid price'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      MitablTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Describe your dish',
                        maxLines: 4,
                        errorText: state.description!.invalid
                            ? 'Please enter a valid description'
                            : null,
                      ),
                      const SizedBox(height: MitablSpacing.listItem),

                      // ── Cooking Style & Dietary Section ──
                      MitablCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cooking Style & Dietary',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Special diet trigger
                            MitablButton(
                              label: 'Special Diet',
                              variant: MitablButtonVariant.outline,
                              icon: const Icon(Icons.restaurant_menu,
                                  size: 18, color: MitablColors.primary),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (contextB) {
                                    return BlocProvider(
                                      create: (context) => SpecialDietCubit(
                                        specialDietDataList:
                                            state.specialDietDataList,
                                      ),
                                      child: const SpecialDietDialog(),
                                    );
                                  },
                                ).then((value) {
                                  if (!context.mounted) return;
                                  if (value != null) {
                                    for (var element
                                        in (value as List<SpecialDietData>)) {
                                      context
                                          .read<AddMenuCubit>()
                                          .onSpecialDietChange(
                                            id: element.id,
                                            value: element.isSelected,
                                          );
                                    }
                                  }
                                });
                              },
                            ),

                            // Selected special diets as chips
                            if (state.specialDietDataList!
                                .where((element) => element.isSelected!)
                                .toList()
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.specialDietDataList!
                                    .where((element) => element.isSelected!)
                                    .map((diet) {
                                  return Chip(
                                    label: Text(
                                      diet.name!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: MitablColors.onSurface,
                                      ),
                                    ),
                                    backgroundColor:
                                        MitablColors.tertiaryFixedDim,
                                    shape: const StadiumBorder(
                                      side: BorderSide.none,
                                    ),
                                    side: BorderSide.none,
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                    onDeleted: () {
                                      context
                                          .read<AddMenuCubit>()
                                          .onDeleteSpecialDiet(id: diet.id);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Cooking style trigger
                            MitablButton(
                              label: cookingStyleController.text.isNotEmpty
                                  ? cookingStyleController.text
                                  : 'Cooking Style',
                              variant: MitablButtonVariant.outline,
                              icon: const Icon(Icons.local_fire_department,
                                  size: 18, color: MitablColors.primary),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (contextB) {
                                    return const CookingStyleDialog();
                                  },
                                ).then((value) {
                                  if (!context.mounted) return;
                                  cookingStyleController.text = context
                                      .read<AddMenuCubit>()
                                      .state
                                      .selectedCookingStyle!
                                      .name
                                      .toString();
                                  setState(() {});
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MitablSpacing.listItem),

                      // ── Availability Schedule ──
                      const _AvailabilityScheduleSection(),
                      const SizedBox(height: MitablSpacing.listItem),

                      // ── Save / Update Button ──
                      MitablButton(
                        label: isEdit ? 'Update Item' : 'Save Item',
                        variant: MitablButtonVariant.primary,
                        onPressed: state.formzStatus!.isValidated
                            ? () {
                                if (state.pathFiles.isNotEmpty) {
                                  if (state.specialDietDataList!
                                      .firstWhere(
                                        (element) => element.isSelected!,
                                        orElse: () {
                                          return SpecialDietData(
                                            isSelected: false,
                                          );
                                        },
                                      )
                                      .isSelected!) {
                                    if (state.selectedCookingStyle!
                                                .isSelected !=
                                            null &&
                                        state.selectedCookingStyle!
                                            .isSelected!) {
                                      context
                                          .read<AddMenuCubit>()
                                          .onAddFood(
                                            isEdit: isEdit,
                                            foodId: widget.routeArguments!
                                                        .foodData !=
                                                    null
                                                ? widget.routeArguments!
                                                    .foodData!.id
                                                    .toString()
                                                : '',
                                          );
                                    } else {
                                      Helper.showToast(
                                        'Please select cooking style',
                                      );
                                    }
                                  } else {
                                    Helper.showToast(
                                      'Please select special diet',
                                    );
                                  }
                                } else {
                                  Helper.showToast(
                                    'Please upload images',
                                  );
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (state.addFoodStatus!.isSubmissionInProgress)
                  const CommonProgressWidget(),
              ],
            );
          },
          listener: (context, state) {},
        ),
      ),
    );
  }
}

// ── Availability Schedule Section ──

class _AvailabilityScheduleSection extends StatelessWidget {
  const _AvailabilityScheduleSection();

  static const List<String> _dayLabels = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMenuCubit, AddMenuState>(
      builder: (context, state) {
        return MitablCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Availability schedule',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MitablColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a specific date, recurring weekdays, and an optional serving window.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              MitablButton(
                label: state.availableDate == null ||
                        state.availableDate!.isEmpty
                    ? 'Pick one specific date'
                    : 'Specific date: ${state.availableDate}',
                variant: MitablButtonVariant.outline,
                icon: const Icon(Icons.event_outlined,
                    size: 18, color: MitablColors.primary),
                onPressed: () =>
                    _pickAvailableDate(context, state.availableDate),
              ),
              if ((state.availableDate ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: () => context
                        .read<AddMenuCubit>()
                        .onAvailableDateChanged(value: ''),
                    child: const Text(
                      'Clear specific date',
                      style: TextStyle(color: MitablColors.primary),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(_dayLabels.length, (index) {
                  final selected = state.availableDays.contains(index);
                  return MitablChip(
                    label: _dayLabels[index],
                    selected: selected,
                    onSelected: (_) => context
                        .read<AddMenuCubit>()
                        .onAvailableDayToggled(day: index),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MitablButton(
                      label: state.availableFromTime == null ||
                              state.availableFromTime!.isEmpty
                          ? 'Start time'
                          : 'From ${state.availableFromTime}',
                      variant: MitablButtonVariant.outline,
                      fullWidth: true,
                      onPressed: () => _pickTime(
                        context,
                        isStart: true,
                        initialValue: state.availableFromTime,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MitablButton(
                      label: state.availableToTime == null ||
                              state.availableToTime!.isEmpty
                          ? 'End time'
                          : 'To ${state.availableToTime}',
                      variant: MitablButtonVariant.outline,
                      fullWidth: true,
                      onPressed: () => _pickTime(
                        context,
                        isStart: false,
                        initialValue: state.availableToTime,
                      ),
                    ),
                  ),
                ],
              ),
              if ((state.availableFromTime ?? '').isNotEmpty ||
                  (state.availableToTime ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: () =>
                        context.read<AddMenuCubit>().onAvailableTimeChanged(
                              availableFromTime: '',
                              availableToTime: '',
                            ),
                    child: const Text(
                      'Clear time window',
                      style: TextStyle(color: MitablColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvailableDate(
    BuildContext context,
    String? currentValue,
  ) async {
    final parsed = _parseDate(currentValue);
    final now = DateTime.now();
    final initialDate = parsed ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (!context.mounted || picked == null) {
      return;
    }

    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    context.read<AddMenuCubit>().onAvailableDateChanged(value: formatted);
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStart,
    String? initialValue,
  }) async {
    final initialTime =
        _parseTimeOfDay(initialValue) ?? const TimeOfDay(hour: 12, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (!context.mounted || picked == null) {
      return;
    }

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    context.read<AddMenuCubit>().onAvailableTimeChanged(
          availableFromTime: isStart ? formatted : null,
          availableToTime: isStart ? null : formatted,
        );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
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
}

// ── Upload Button ──

class _UploadButton extends StatefulWidget {
  const _UploadButton();

  @override
  _UploadbuttonState createState() => _UploadbuttonState();
}

class _UploadbuttonState extends State<_UploadButton> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddMenuCubit, AddMenuState>(
      listener: (context, state) {},
      builder: (context, state) {
        return MitablButton(
          label: 'Upload Photos',
          variant: MitablButtonVariant.outline,
          icon: const Icon(Icons.camera_alt_outlined,
              size: 18, color: MitablColors.primary),
          onPressed: () {
            if (state.pathFiles.length <= 4) {
              showDialog<bool>(
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: MitablColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MitablRadius.card),
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
        );
      },
    );
  }

  void _openGallery(BuildContext context) async {
    final cubit = context.read<AddMenuCubit>();
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (!context.mounted || picture == null) {
        Helper.showToast('No image selected.');
        return;
      }

      cubit.onNewImageAdded(path: picture.path);
    } catch (e) {
      Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    final cubit = context.read<AddMenuCubit>();
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
    } catch (e) {
      Helper.showToast('No image captured.');
    }
  }
}
