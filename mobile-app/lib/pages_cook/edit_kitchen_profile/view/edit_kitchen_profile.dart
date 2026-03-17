import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFBF7),
            elevation: 0,
            leadingWidth: config.AppConfig(context).appWidth(50),
            leading: Padding(
              padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(5),
              ),
              child: InkWell(
                onTap: () {
                  navigatorKey.currentState!.pop();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).primaryColorDark,
                      size: config.AppConfig(context).appWidth(5),
                    ),
                    SizedBox(width: config.AppConfig(context).appWidth(2)),
                    Text(
                      state.isCreateMode ? 'Add mikitchn' : 'Edit mikitchn',
                      style: GoogleFonts.gothicA1(
                        color: Theme.of(context).primaryColorDark,
                        fontSize: config.AppConfig(context).appWidth(5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            alignment: Alignment.center,
            color: const Color(0xFFFFFBF7),
            height: config.AppConfig(context).appHeight(100),
            width: config.AppConfig(context).appWidth(100),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom +
                    MediaQuery.of(context).viewInsets.bottom +
                    config.AppConfig(context).appHeight(4),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: config.AppConfig(context).appHeight(2),
                  left: config.AppConfig(context).appWidth(5),
                  right: config.AppConfig(context).appWidth(5),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: config.AppConfig(context).appWidth(90),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: config.AppConfig(context).appHeight(2),
                        ),
                        state.pathFiles.isNotEmpty
                            ? SizedBox(
                                height: config.AppConfig(context).appHeight(20),
                                child: PageView.builder(
                                  controller: controller,
                                  onPageChanged: (page) {
                                    context
                                        .read<EditKitchenProfileCubit>()
                                        .onImageScroll(index: page);
                                  },
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: config.AppConfig(
                                          context,
                                        ).appWidth(2),
                                      ),
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: config.AppConfig(
                                              context,
                                            ).appHeight(20),
                                            width: config.AppConfig(
                                              context,
                                            ).appWidth(85),
                                            decoration: BoxDecoration(
                                              color: config.AppColors()
                                                  .textFieldBackgroundColor(1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                config.AppConfig(
                                                  context,
                                                ).appWidth(5),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                              errorWidget: (context, data, e) {
                                                return Image.file(
                                                  File(
                                                    state
                                                        .pathFiles[index].path!,
                                                  ),
                                                  errorBuilder:
                                                      (context, data, e) {
                                                    return const Icon(
                                                      Icons.error_outline,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            right: 6,
                                            top: 6,
                                            child: InkWell(
                                              onTap: () {
                                                context
                                                    .read<
                                                        EditKitchenProfileCubit>()
                                                    .onDeleteImage(
                                                      path: state
                                                          .pathFiles[index]
                                                          .path,
                                                      imagesCook: state
                                                          .pathFiles[index],
                                                    );
                                              },
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: config.AppConfig(
                                                  context,
                                                ).appWidth(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  itemCount: state.pathFiles.length,
                                ),
                              )
                            : Container(
                                height: config.AppConfig(context).appHeight(20),
                                decoration: BoxDecoration(
                                  color: config.AppColors()
                                      .textFieldBackgroundColor(1),
                                  borderRadius: BorderRadius.circular(
                                    config.AppConfig(context).appWidth(5),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.photo_outlined,
                                  size: config.AppConfig(context).appWidth(30),
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(2),
                        ),
                        state.pathFiles.isNotEmpty
                            ? Container(
                                alignment: Alignment.center,
                                height: config.AppConfig(context).appHeight(5),
                                child: ListView.separated(
                                  // controller: controller,
                                  separatorBuilder: (context, index) {
                                    return SizedBox(
                                      width: config.AppConfig(
                                        context,
                                      ).appWidth(2),
                                    );
                                  },
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: config.AppConfig(
                                        context,
                                      ).appWidth(2),
                                      decoration: BoxDecoration(
                                        color: state.selectedPage == index
                                            ? Colors.blue
                                            : const Color(0xFF9CA3AF),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                  itemCount: state.pathFiles.length,
                                ),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: config.AppConfig(context).appHeight(2),
                        ),
                        _UploadButton(loginForm: this),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _KitchenName(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.zero,
                              child: TextFormField(
                                controller: addressTextEditor,
                                style: const TextStyle(color: Colors.black),
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.name,
                                maxLength: 55,
                                onChanged: (text) {},
                                decoration: InputDecoration(
                                  counterText: '',
                                  errorText: state.address!.invalid
                                      ? 'Please enter a valid address'
                                      : null,

                                  hintStyle: GoogleFonts.gothicA1(
                                    color: Theme.of(context).hintColor,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4),
                                  ),
                                  // labelText: 'Mobile Number',
                                  hintText: 'Address',
                                  contentPadding: EdgeInsets.all(
                                    config.AppConfig(context).appWidth(2),
                                  ),
                                  fillColor: config.AppColors()
                                      .textFieldBackgroundColor(1),
                                  filled: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _PhoneNo(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _NoOfSeats(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _AbnField(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _CertificateField(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(2),
                            ),
                            _Timing(loginForm: this),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: config.AppConfig(
                                      context,
                                    ).appWidth(40),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: config.AppColors()
                                          .textFieldBackgroundColor(1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                value: state.dineIn,
                                                onChanged: (value) {
                                                  context
                                                      .read<
                                                          EditKitchenProfileCubit>()
                                                      .onDineInChange(
                                                        value: value,
                                                      );
                                                },
                                              ),
                                              Text(
                                                'Dine-in',
                                                style: GoogleFonts.gothicA1(
                                                  fontSize: config.AppConfig(
                                                    context,
                                                  ).appHeight(2),
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: config.AppConfig(
                                            context,
                                          ).appWidth(3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(3),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: config.AppConfig(
                                      context,
                                    ).appWidth(40),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: config.AppColors()
                                          .textFieldBackgroundColor(1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                value: state.takeAway,
                                                onChanged: (value) {
                                                  context
                                                      .read<
                                                          EditKitchenProfileCubit>()
                                                      .onTakeAwayChange(
                                                        value: value,
                                                      );
                                                },
                                              ),
                                              Text(
                                                'Takeaway',
                                                style: GoogleFonts.gothicA1(
                                                  fontSize: config.AppConfig(
                                                    context,
                                                  ).appHeight(2),
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ),
                                                ),
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
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            const _DineInSlotSection(),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.zero,
                              child: TextFormField(
                                controller: bioTextEditor,
                                style: const TextStyle(color: Colors.black),
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                maxLength: 200,
                                maxLines: 5,
                                onChanged: (text) {},
                                decoration: InputDecoration(
                                  counterText: '',
                                  errorText: state.bio!.invalid
                                      ? 'Please enter a valid bio'
                                      : null,

                                  hintStyle: GoogleFonts.gothicA1(
                                    color: Theme.of(context).hintColor,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(4),
                                  ),
                                  // labelText: 'Mobile Number',
                                  hintText: 'Bio',
                                  contentPadding: EdgeInsets.all(
                                    config.AppConfig(context).appWidth(2),
                                  ),
                                  fillColor: config.AppColors()
                                      .textFieldBackgroundColor(1),
                                  filled: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFFBF7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: config.AppConfig(context).appHeight(3),
                            ),
                            _LoginButton(loginForm: this),
                          ],
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

class _Timing extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _Timing({this.loginForm});

  @override
  State<_Timing> createState() => _TimingState();
}

class _TimingState extends State<_Timing> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
          builder: (context, state) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: TextFormField(
                readOnly: true,
                style: const TextStyle(color: Colors.black),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                maxLength: 55,
                onChanged: (text) {},
                decoration: InputDecoration(
                  counterText: '',

                  // errorText:
                  //     state.email!.invalid ? 'Please enter a valid email id' : null,
                  suffixIcon: InkWell(
                    onTap: () {
                      context
                          .read<EditKitchenProfileCubit>()
                          .onOpenTimingDialog();
                      showDialog(
                        context: context,
                        builder: (contexts) {
                          return BlocProvider.value(
                            value: context.read<EditKitchenProfileCubit>(),
                            child: EditTimingDialog(),
                          );
                        },
                      );
                    },
                    child: Icon(
                      Icons.access_time_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  hintStyle: GoogleFonts.gothicA1(
                    color: Theme.of(context).hintColor,
                    fontSize: config.AppConfig(context).appWidth(4),
                  ),
                  // labelText: 'Mobile Number',
                  hintText: 'Timings',
                  contentPadding: EdgeInsets.all(
                    config.AppConfig(context).appWidth(2),
                  ),
                  fillColor: config.AppColors().textFieldBackgroundColor(1),
                  filled: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFFBF7),
                    ),
                  ),
                  border: InputBorder.none,
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFFBF7),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFFBF7),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFFBF7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFFBF7),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DineInSlotSection extends StatelessWidget {
  const _DineInSlotSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
      builder: (context, state) {
        final availableDays = _resolveOpenDays(
          state.daysTimingOriginal ?? state.daysTiming,
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(config.AppConfig(context).appWidth(4)),
          decoration: BoxDecoration(
            color: config.AppColors().textFieldBackgroundColor(1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dine-in timeslots',
                      style: GoogleFonts.gothicA1(
                        color: Colors.black,
                        fontSize: config.AppConfig(context).appWidth(4.5),
                        fontWeight: FontWeight.w700,
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
                    icon: const Icon(Icons.add),
                    label: const Text('Add slot'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Create bookable tables by day, time, and seat capacity.',
                style: GoogleFonts.gothicA1(
                  color: const Color(0xFF9CA3AF),
                  fontSize: config.AppConfig(context).appWidth(3.3),
                ),
              ),
              const SizedBox(height: 12),
              if (state.dineIn != true)
                const Text('Enable dine-in to manage dine-in slots.')
              else if (availableDays.isEmpty)
                const Text('Open at least one kitchen day before adding slots.')
              else if (state.dineInSlotsStatus.isSubmissionInProgress)
                const Center(child: CircularProgressIndicator())
              else if (state.dineInSlots.isEmpty)
                const Text('No dine-in slots added yet.')
              else
                ...List<Widget>.generate(state.dineInSlots.length, (index) {
                  final slot = state.dineInSlots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        '${slot.dayName ?? _labelForDay(slot.dayOfWeek)}  ${slot.startTime ?? '--:--'} - ${slot.endTime ?? '--:--'}',
                        style: GoogleFonts.gothicA1(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Seats: ${slot.seatCapacity ?? 0}',
                        style: GoogleFonts.gothicA1(),
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
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => context
                                .read<EditKitchenProfileCubit>()
                                .deleteDineInSlot(index),
                            icon: const Icon(Icons.delete_outline),
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
                          child: OutlinedButton(
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
                            child: Text(
                              startTime == null || startTime!.isEmpty
                                  ? 'Start time'
                                  : startTime!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
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
                            child: Text(
                              endTime == null || endTime!.isEmpty
                                  ? 'End time'
                                  : endTime!,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      title: const Text('Slot enabled'),
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
                ElevatedButton(
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

class _KitchenName extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _KitchenName({this.loginForm});

  @override
  State<_KitchenName> createState() => _KitchenNameState();
}

class _KitchenNameState extends State<_KitchenName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
      builder: (context, state) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: widget.loginForm!.nameTextEditor,
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            maxLength: 15,
            onChanged: (text) {
              context.read<EditKitchenProfileCubit>().onKitchnNameChanged(
                    value: text,
                  );
            },
            decoration: InputDecoration(
              counterText: '',
              errorText: state.nameKitchn!.invalid
                  ? 'Please enter a valid name'
                  : null,

              hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              // labelText: 'Mobile Number',
              hintText: 'mikitchn name',
              contentPadding: EdgeInsets.all(
                config.AppConfig(context).appWidth(2),
              ),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoOfSeats extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _NoOfSeats({this.loginForm});

  @override
  State<_NoOfSeats> createState() => _NoOfSeatsState();
}

class _NoOfSeatsState extends State<_NoOfSeats> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
      builder: (context, state) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: widget.loginForm!.noOfSeatsTextEditor,
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: (text) {
              context.read<EditKitchenProfileCubit>().onSeatChanged(
                    value: text,
                  );
            },
            decoration: InputDecoration(
              counterText: '',
              errorText:
                  state.noOfSeats.invalid ? 'Please enter a valid seats' : null,
              hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              hintText: 'No. of seats',
              contentPadding: EdgeInsets.all(
                config.AppConfig(context).appWidth(2),
              ),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneNo extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _PhoneNo({this.loginForm});

  @override
  State<_PhoneNo> createState() => _PhoneNoState();
}

class _PhoneNoState extends State<_PhoneNo> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
      builder: (context, state) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: widget.loginForm!.mobileNoTextEditor,
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            onChanged: (text) {
              context.read<EditKitchenProfileCubit>().onPhoneChanged(
                    value: text,
                  );
            },
            decoration: InputDecoration(
              counterText: '',
              errorText:
                  state.phone.invalid ? 'Please enter a valid phone no' : null,

              hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              // labelText: 'Mobile Number',
              hintText: 'Phone',
              contentPadding: EdgeInsets.all(
                config.AppConfig(context).appWidth(2),
              ),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AbnField extends StatelessWidget {
  const _AbnField({this.loginForm});

  final _EditKitchenProfilePageState? loginForm;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: loginForm!.abnNoTextEditor,
        style: const TextStyle(color: Colors.black),
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        maxLength: 20,
        decoration: InputDecoration(
          counterText: '',
          hintStyle: GoogleFonts.gothicA1(
            color: Theme.of(context).hintColor,
            fontSize: config.AppConfig(context).appWidth(4),
          ),
          hintText: 'ABN',
          contentPadding: EdgeInsets.all(config.AppConfig(context).appWidth(2)),
          fillColor: config.AppColors().textFieldBackgroundColor(1),
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          border: InputBorder.none,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
        ),
      ),
    );
  }
}

class _CertificateField extends StatelessWidget {
  const _CertificateField({this.loginForm});

  final _EditKitchenProfilePageState? loginForm;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: loginForm!.certificateTextEditor,
        style: const TextStyle(color: Colors.black),
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        maxLength: 50,
        decoration: InputDecoration(
          counterText: '',
          hintStyle: GoogleFonts.gothicA1(
            color: Theme.of(context).hintColor,
            fontSize: config.AppConfig(context).appWidth(4),
          ),
          hintText: 'Certificate number',
          contentPadding: EdgeInsets.all(config.AppConfig(context).appWidth(2)),
          fillColor: config.AppColors().textFieldBackgroundColor(1),
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          border: InputBorder.none,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFFFBF7)),
          ),
        ),
      ),
    );
  }
}

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
        return Container(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          child: MaterialButton(
            minWidth: config.AppConfig(context).appWidth(100),
            height: 50.0,
            onPressed: () {
              // _pickImage();

              if (state.pathFiles.length <= 4) {
                showDialog<bool>(
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        'Add image',
                        style: GoogleFonts.gothicA1(
                          color: Colors.black,
                          fontSize: config.AppConfig(context).appWidth(5),
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MaterialButton(
                            color: Theme.of(context).primaryColor,
                            child: const Text(
                              "Gallery",
                              style: TextStyle(
                                color: Color(0xB3FFFBF7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              navigatorKey.currentState!.pop(false);
                            },
                          ),
                          MaterialButton(
                            color: Theme.of(context).primaryColor,
                            child: const Text(
                              "Camera",
                              style: TextStyle(
                                color: Color(0xB3FFFBF7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                      //Get from camera
                      _openCamera(context);
                    } else {
                      //Get from gallery
                      _openGallery(context);
                    }
                  }
                });
              } else {
                Helper.showToast('Photos limit reached.');
              }
            },
            child: Text(
              'Upload Photos',
              style: GoogleFonts.gothicA1(
                fontSize: config.AppConfig(context).appWidth(3.5),
                color: const Color(0xFFFFFBF7),
              ),
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

class _LoginButton extends StatelessWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _LoginButton({this.loginForm});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: state.status!.isValidated
                  ? [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor,
                    ]
                  : [
                      Theme.of(context).primaryColorLight,
                      Theme.of(context).primaryColorLight,
                    ],
            ),
          ),
          child: MaterialButton(
            minWidth: config.AppConfig(context).appWidth(100),
            height: 50.0,
            onPressed: () {
              if (state.status!.isValidated) {
                context.read<EditKitchenProfileCubit>().onKitchenEditUpload();
              }
            },
            child: state.statusApi!.isSubmissionInProgress
                ? const Center(
                    child: CupertinoActivityIndicator(
                      color: Color(0xFFFFFBF7),
                    ),
                  )
                : Text(
                    state.isCreateMode ? 'CREATE MIKITCHN' : 'UPDATE MIKITCHN',
                    style: GoogleFonts.gothicA1(
                      fontSize: config.AppConfig(context).appWidth(3.5),
                      color: const Color(0xFFFFFBF7),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
