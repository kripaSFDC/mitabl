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
import 'package:mitabl_user/widgets/mitabl_chip.dart';

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
        body: BlocConsumer<AddMenuCubit, AddMenuState>(
          builder: (context, state) {
            return Stack(
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
                          color: MitablColors.surface
                              .withValues(alpha: 0.80),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (!isEdit) {
                                  context
                                      .read<AddMenuCubit>()
                                      .resetFields();
                                }
                                navigatorKey.currentState!.pop();
                              },
                              icon: const Icon(Icons.arrow_back,
                                  color: MitablColors.primary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEdit ? 'Edit Menu Item' : 'Add Menu Item',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: MitablColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF0EDE9),
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
                            // Item Photography section
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Item Photography',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'MAX 4 PHOTOS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Photo grid
                            SizedBox(
                              height: 200,
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
                                        return Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 4),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                                    );
                                                  },
                                                  placeholder:
                                                      (context, s) =>
                                                          Container(
                                                    color: MitablColors
                                                        .surfaceContainerLow,
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      context
                                                          .read<
                                                              AddMenuCubit>()
                                                          .onDeleteImage(
                                                            path: state
                                                                .pathFiles[
                                                                    index]
                                                                .path,
                                                            pictures: state
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
                                                            .surface
                                                            .withValues(
                                                                alpha:
                                                                    0.8),
                                                        shape: BoxShape
                                                            .circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .delete_outline,
                                                        color: MitablColors
                                                            .error,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: state.pathFiles.length,
                                    )
                                  : _PhotoPlaceholderGrid(),
                            ),

                            // Page dots
                            if (state.pathFiles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(
                                    state.pathFiles.length,
                                    (index) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            state.selectedPage == index
                                                ? MitablColors.primary
                                                : MitablColors
                                                    .outlineVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            const _UploadButton(),
                            const SizedBox(height: 32),

                            // Food Name
                            _FormLabel(label: 'Food Name'),
                            const SizedBox(height: 8),
                            _FormInput(
                              controller: itemNameController,
                              hint:
                                  'e.g. Heirloom Tomato & Basil Gnocchi',
                              errorText: state.itemName!.invalid
                                  ? 'Please enter a valid name'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Description
                            _FormLabel(label: 'Description'),
                            const SizedBox(height: 8),
                            _FormInput(
                              controller: descriptionController,
                              hint:
                                  'Share the story behind this dish...',
                              maxLines: 4,
                              errorText: state.description!.invalid
                                  ? 'Please enter a valid description'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Price
                            _FormLabel(label: 'Price (\$)'),
                            const SizedBox(height: 8),
                            _FormInput(
                              controller: priceController,
                              hint: '0.00',
                              prefix: '\$',
                              keyboardType: TextInputType.number,
                              errorText: state.price!.invalid
                                  ? 'Please enter a valid price'
                                  : null,
                            ),
                            const SizedBox(height: 32),

                            // Cooking Style & Dietary
                            const Text(
                              'Cooking Style & Dietary',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Cooking Style label
                            Text(
                              'COOKING STYLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.60),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Cooking style chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StyleChip(
                                  label: cookingStyleController
                                          .text.isNotEmpty
                                      ? cookingStyleController.text
                                      : 'Select Style',
                                  isSelected: true,
                                  onTap: () {
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
                            const SizedBox(height: 20),

                            // Dietary Options label
                            Text(
                              'DIETARY OPTIONS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.60),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Special diet button
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (contextB) {
                                      return BlocProvider(
                                        create: (context) =>
                                            SpecialDietCubit(
                                          specialDietDataList:
                                              state.specialDietDataList,
                                        ),
                                        child:
                                            const SpecialDietDialog(),
                                      );
                                    },
                                  ).then((value) {
                                    if (!context.mounted) return;
                                    if (value != null) {
                                      for (var element in (value
                                          as List<SpecialDietData>)) {
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
                                icon: const Icon(
                                    Icons.restaurant_menu,
                                    size: 18,
                                    color: MitablColors.primary),
                                label: const Text('Special Diet'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: MitablColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        MitablRadius.pillBorder,
                                  ),
                                  side: BorderSide(
                                    color: MitablColors.outlineVariant
                                        .withValues(alpha: 0.40),
                                  ),
                                ),
                              ),
                            ),

                            // Selected diet chips
                            if (state.specialDietDataList!
                                .where(
                                    (element) => element.isSelected!)
                                .toList()
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.specialDietDataList!
                                    .where((element) =>
                                        element.isSelected!)
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
                                      color: MitablColors
                                          .onSurfaceVariant,
                                    ),
                                    onDeleted: () {
                                      context
                                          .read<AddMenuCubit>()
                                          .onDeleteSpecialDiet(
                                              id: diet.id);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 32),

                            // Service Availability section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    MitablColors.surfaceContainerLow,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Service Availability',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Dine-in toggle
                                  _AvailabilityToggle(
                                    icon: Icons.restaurant,
                                    title: 'Dine-in Experience',
                                    subtitle:
                                        'Allow guests to eat at your atelier',
                                    value: true,
                                    onChanged: (_) {},
                                  ),
                                  Container(
                                    height: 1,
                                    color: MitablColors.outlineVariant
                                        .withValues(alpha: 0.10),
                                  ),
                                  // Take-away toggle
                                  _AvailabilityToggle(
                                    icon: Icons.shopping_bag_outlined,
                                    title: 'Take-away',
                                    subtitle:
                                        'Guests pick up their meal to-go',
                                    value: false,
                                    onChanged: (_) {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Availability Schedule
                            const _AvailabilityScheduleSection(),
                            const SizedBox(height: 32),

                            // Action bar
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 64,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: MitablColors
                                            .primaryGradient,
                                        borderRadius:
                                            MitablRadius.pillBorder,
                                        boxShadow: [
                                          BoxShadow(
                                            color: MitablColors.primary
                                                .withValues(
                                                    alpha: 0.20),
                                            blurRadius: 20,
                                            offset:
                                                const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              MitablRadius.pillBorder,
                                          onTap: state.formzStatus!
                                                  .isValidated
                                              ? () {
                                                  if (state.pathFiles
                                                      .isNotEmpty) {
                                                    if (state
                                                        .specialDietDataList!
                                                        .firstWhere(
                                                          (element) =>
                                                              element
                                                                  .isSelected!,
                                                          orElse: () {
                                                            return SpecialDietData(
                                                              isSelected:
                                                                  false,
                                                            );
                                                          },
                                                        )
                                                        .isSelected!) {
                                                      if (state
                                                                  .selectedCookingStyle!
                                                                  .isSelected !=
                                                              null &&
                                                          state
                                                              .selectedCookingStyle!
                                                              .isSelected!) {
                                                        context
                                                            .read<
                                                                AddMenuCubit>()
                                                            .onAddFood(
                                                              isEdit:
                                                                  isEdit,
                                                              foodId: widget.routeArguments!.foodData !=
                                                                      null
                                                                  ? widget
                                                                      .routeArguments!
                                                                      .foodData!
                                                                      .id
                                                                      .toString()
                                                                  : '',
                                                            );
                                                      } else {
                                                        Helper
                                                            .showToast(
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
                                          child: Center(
                                            child: Text(
                                              isEdit
                                                  ? 'Update Item'
                                                  : 'Save Item',
                                              style: const TextStyle(
                                                fontFamily: 'Nunito',
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.w800,
                                                color: MitablColors
                                                    .onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<AddMenuCubit>()
                                          .resetFields();
                                      navigatorKey.currentState!.pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFF0EDE9),
                                      foregroundColor: MitablColors
                                          .onSurfaceVariant,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            MitablRadius.pillBorder,
                                      ),
                                      elevation: 0,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 32),
                                    ),
                                    child: const Text(
                                      'Discard',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
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

// ── Photo Placeholder Grid ──

class _PhotoPlaceholderGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main photo placeholder
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: MitablColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MitablColors.outlineVariant.withValues(alpha: 0.30),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 28, color: const Color(0xFF89726B)),
                const SizedBox(height: 8),
                Text(
                  'Main Photo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Small placeholders
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _SmallPlaceholder(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _SmallPlaceholder(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _SmallPlaceholder(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _SmallPlaceholder(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.30),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Color(0xFF89726B), size: 20),
      ),
    );
  }
}

// ── Form helpers ──

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: MitablColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.prefix,
    this.keyboardType,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? prefix;
  final TextInputType? keyboardType;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: MitablColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: MitablColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: const Color(0xFF89726B)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: prefix != null ? 40 : 20,
                vertical: maxLines > 1 ? 20 : 16,
              ),
              prefixIcon: prefix != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20, right: 4),
                      child: Text(
                        prefix!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: prefix != null
                  ? const BoxConstraints(minWidth: 0, minHeight: 0)
                  : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: MitablColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MitablColors.primary
              : MitablColors.tertiaryFixedDim,
          borderRadius: MitablRadius.pillBorder,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? MitablColors.onPrimary
                : const Color(0xFF251911),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: MitablColors.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MitablColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF4D6548),
            activeTrackColor: MitablColors.secondaryContainer,
            onChanged: onChanged,
          ),
        ],
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
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MitablColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Availability',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MitablColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a specific date, recurring weekdays, and an optional serving window.',
                style: TextStyle(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _pickAvailableDate(context, state.availableDate),
                  icon: const Icon(Icons.event_outlined,
                      size: 18, color: MitablColors.primary),
                  label: Text(
                    state.availableDate == null ||
                            state.availableDate!.isEmpty
                        ? 'Pick one specific date'
                        : 'Specific date: ${state.availableDate}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MitablColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    side: BorderSide(
                      color: MitablColors.outlineVariant
                          .withValues(alpha: 0.40),
                    ),
                  ),
                ),
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
                children:
                    List<Widget>.generate(_dayLabels.length, (index) {
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
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _pickTime(
                          context,
                          isStart: true,
                          initialValue: state.availableFromTime,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MitablColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: MitablRadius.pillBorder,
                          ),
                          side: BorderSide(
                            color: MitablColors.outlineVariant
                                .withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          state.availableFromTime == null ||
                                  state.availableFromTime!.isEmpty
                              ? 'Start time'
                              : 'From ${state.availableFromTime}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _pickTime(
                          context,
                          isStart: false,
                          initialValue: state.availableToTime,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MitablColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: MitablRadius.pillBorder,
                          ),
                          side: BorderSide(
                            color: MitablColors.outlineVariant
                                .withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          state.availableToTime == null ||
                                  state.availableToTime!.isEmpty
                              ? 'End time'
                              : 'To ${state.availableToTime}',
                        ),
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
                    onPressed: () => context
                        .read<AddMenuCubit>()
                        .onAvailableTimeChanged(
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
        return SizedBox(
          height: 48,
          child: OutlinedButton.icon(
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
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                navigatorKey.currentState!.pop(false);
                              },
                              icon: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 18),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MitablColors.primary,
                                foregroundColor: MitablColors.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: MitablRadius.pillBorder,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                navigatorKey.currentState!.pop(true);
                              },
                              icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                  color: MitablColors.primary),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MitablColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: MitablRadius.pillBorder,
                                ),
                                side: BorderSide(
                                  color: MitablColors.outlineVariant
                                      .withValues(alpha: 0.40),
                                ),
                              ),
                            ),
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
            icon: const Icon(Icons.camera_alt_outlined,
                size: 18, color: MitablColors.primary),
            label: const Text('Upload Photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MitablColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: MitablRadius.pillBorder,
              ),
              side: BorderSide(
                color:
                    MitablColors.outlineVariant.withValues(alpha: 0.40),
              ),
            ),
          ),
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
