import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/get_profile_model.dart';
import 'package:mitabl_user/model/timing_model.dart';
import 'package:mitabl_user/pages/profile_signup_cook/cook_profile/element/timing_dialog.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<CookProfileCubit, CookProfileState>(
          builder: (context, state) {
            return Stack(
              children: [
                Container(
                  color: const Color(0xFFFFFBF7),
                  height: config.AppConfig(context).appHeight(100),
                  width: config.AppConfig(context).appWidth(100),
                  child: SingleChildScrollView(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  Text(
                                    'Your account has been created',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: config.AppConfig(
                                        context,
                                      ).appWidth(6.0),
                                      fontWeight: config.FontFamily().demi,
                                    ),
                                  ),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(0.5),
                                  ),
                                  Text(
                                    'Please enter mikitchn details to continue',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: 16,
                                      fontWeight: config.FontFamily().book,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(2),
                              ),
                              state.pathFiles.isNotEmpty
                                  ? SizedBox(
                                      height: config.AppConfig(
                                        context,
                                      ).appHeight(20),
                                      child: PageView.builder(
                                        controller: controller,
                                        onPageChanged: (page) {
                                          context
                                              .read<CookProfileCubit>()
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
                                                        .textFieldBackgroundColor(
                                                          1,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          config.AppConfig(
                                                            context,
                                                          ).appWidth(5),
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Image.file(
                                                    File(
                                                      state.pathFiles[index],
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 6,
                                                  top: 6,
                                                  child: InkWell(
                                                    onTap: () {
                                                      context
                                                          .read<
                                                            CookProfileCubit
                                                          >()
                                                          .onDeleteImage(
                                                            path: state
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
                                      height: config.AppConfig(
                                        context,
                                      ).appHeight(20),
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
                                        size: config.AppConfig(
                                          context,
                                        ).appWidth(30),
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                              SizedBox(
                                height: config.AppConfig(context).appHeight(2),
                              ),
                              state.pathFiles.isNotEmpty
                                  ? Container(
                                      alignment: Alignment.center,
                                      height: config.AppConfig(
                                        context,
                                      ).appHeight(5),
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
                                height: config.AppConfig(context).appHeight(1),
                              ),
                              _UploadButton(loginForm: this),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  _KitchenName(loginForm: this),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: TextFormField(
                                      // controller: widget.loginForm!.mobileNoTextEditor,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.name,
                                      maxLength: 55,
                                      onChanged: (text) {
                                        context
                                            .read<CookProfileCubit>()
                                            .onAddressChanged(value: text);
                                      },
                                      decoration: InputDecoration(
                                        counterText: '',
                                        errorText: state.address!.invalid
                                            ? 'Please enter a valid address'
                                            : null,
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 16,
                                          fontWeight: config.FontFamily().book,
                                        ),
                                        // labelText: 'Mobile Number',
                                        hintText: 'Address',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: config.AppConfig(
                                            context,
                                          ).appWidth(5),
                                          vertical: config.AppConfig(
                                            context,
                                          ).appWidth(3),
                                        ),
                                        fillColor: config.AppColors()
                                            .textFieldBackgroundColor(1),
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: const Color(0xFFFFFBF7),
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: const Color(0xFFFFFBF7),
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: const Color(0xFFFFFBF7),
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: const Color(0xFFFFFBF7),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: const Color(0xFFFFFBF7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  _PhoneNo(loginForm: this),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  _NoOfSeats(loginForm: this),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(2),
                                  ),
                                  _Timing(loginForm: this),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(3),
                                  ),
                                  _ServiceTypeSection(),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(3),
                                  ),
                                  const _CreateKitchenSlotSection(),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(3),
                                  ),
                                  _LoginButton(loginForm: this),
                                  SizedBox(
                                    height: config.AppConfig(
                                      context,
                                    ).appHeight(4.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                state.statusApi!.isSubmissionInProgress
                    ? const CommonProgressWidget()
                    : const SizedBox(),
              ],
            );
          },
          listener: (context, state) async {
            if (state.statusApi!.isSubmissionFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${state.serverMessage}')));
            }
          },
        ),
      ),
    );
  }
}

class _Timing extends StatefulWidget {
  final _CookProfilePage? loginForm;

  const _Timing({this.loginForm});

  @override
  State<_Timing> createState() => _TimingState();
}

class _TimingState extends State<_Timing> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return BlocBuilder<CookProfileCubit, CookProfileState>(
          builder: (context, state) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: TextFormField(
                readOnly: true,
                controller: widget.loginForm!.mobileNoTextEditor,
                style: const TextStyle(color: Colors.black),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                maxLength: 55,
                onChanged: (text) {
                  // context.read<SignUpCubit>().onEmailChanged(value: text);
                },
                decoration: InputDecoration(
                  counterText: '',

                  // errorText:
                  //     state.email!.invalid ? 'Please enter a valid email id' : null,
                  suffixIcon: InkWell(
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
                    child: Icon(
                      Icons.access_time_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 16,
                    fontWeight: config.FontFamily().book,
                  ),
                  // labelText: 'Mobile Number',
                  hintText: 'Timings',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: config.AppConfig(context).appWidth(5),
                    vertical: config.AppConfig(context).appWidth(3),
                  ),
                  fillColor: config.AppColors().textFieldBackgroundColor(1),
                  filled: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: const Color(0xFFFFFBF7),
                    ),
                  ),
                  border: InputBorder.none,
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: const Color(0xFFFFFBF7),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: const Color(0xFFFFFBF7),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: const Color(0xFFFFFBF7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: const Color(0xFFFFFBF7),
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

class _ServiceTypeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: config.AppColors().textFieldBackgroundColor(1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CheckboxListTile(
                  value: state.dineIn,
                  onChanged: (value) => context
                      .read<CookProfileCubit>()
                      .onDineInChange(value: value),
                  title: const Text('Dine-in'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: config.AppColors().textFieldBackgroundColor(1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CheckboxListTile(
                  value: state.takeAway,
                  onChanged: (value) => context
                      .read<CookProfileCubit>()
                      .onTakeAwayChange(value: value),
                  title: const Text('Takeaway'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreateKitchenSlotSection extends StatelessWidget {
  const _CreateKitchenSlotSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CookProfileCubit, CookProfileState>(
      builder: (context, state) {
        final availableDays = _resolveOpenDays(state.daysTimingOriginal);
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
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
                    icon: const Icon(Icons.add),
                    label: const Text('Add slot'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!state.dineIn)
                const Text('Enable dine-in to add bookable table slots.')
              else if (availableDays.isEmpty)
                const Text('Turn on at least one kitchen opening day first.')
              else if (state.dineInSlots.isEmpty)
                const Text('No dine-in slots added yet.')
              else
                ...List<Widget>.generate(state.dineInSlots.length, (index) {
                  final slot = state.dineInSlots[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${slot.dayName ?? _labelForDay(slot.dayOfWeek)}  ${slot.startTime} - ${slot.endTime}',
                      ),
                      subtitle: Text('Seats: ${slot.seatCapacity ?? 0}'),
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
                                .read<CookProfileCubit>()
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
                                initialTime:
                                    _parseTime(startTime) ??
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
                                initialTime:
                                    _parseTime(endTime) ??
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
    final leftMinutes =
        ((int.tryParse(leftParts[0]) ?? 0) * 60) +
        (int.tryParse(leftParts[1]) ?? 0);
    final rightMinutes =
        ((int.tryParse(rightParts[0]) ?? 0) * 60) +
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
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            // controller: widget.loginForm!.mobileNoTextEditor,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            maxLength: 15,
            onChanged: (text) {
              context.read<CookProfileCubit>().onKitchnNameChanged(value: text);
            },
            decoration: InputDecoration(
              counterText: '',
              errorText: state.nameKitchn!.invalid
                  ? 'Please enter a valid name'
                  : null,

              hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: config.FontFamily().book,
              ),
              // labelText: 'Mobile Number',
              hintText: 'mikitchn name',
              contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(3),
              ),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TextFormField(
            // controller: widget.loginForm!.mobileNoTextEditor,
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: (text) {
              context.read<CookProfileCubit>().onSeatChanged(value: text);
            },
            decoration: InputDecoration(
              counterText: '',
              errorText: state.noOfSeats.invalid
                  ? 'Please enter a valid seats'
                  : null,
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: config.FontFamily().book,
              ),
              hintText: 'No. of seats',
              contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(3),
              ),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              border: InputBorder.none,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
          children: [
            SizedBox(
              width: config.AppConfig(context).appWidth(22),
              child: TextFormField(
                controller: _countryCodeController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                maxLength: 5,
                onChanged: (value) {
                  context.read<CookProfileCubit>().onCountryCodeChanged(
                    value: value,
                    localNumber: _phoneController.text,
                  );
                },
                decoration: _phoneInputDecoration(
                  context,
                  hintText: '+61',
                  showError: state.phone.invalid,
                ),
              ),
            ),
            SizedBox(width: config.AppConfig(context).appWidth(3)),
            Expanded(
              child: TextFormField(
                style: const TextStyle(color: Colors.black, fontSize: 16),
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 14,
                onChanged: (text) {
                  context.read<CookProfileCubit>().onPhoneChanged(
                    value: InternationalPhone.compose(
                      countryCode: _countryCodeController.text,
                      number: text,
                    ),
                  );
                },
                decoration: _phoneInputDecoration(
                  context,
                  hintText: 'Phone',
                  showError: state.phone.invalid,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _phoneInputDecoration(
    BuildContext context, {
    required String hintText,
    required bool showError,
  }) {
    return InputDecoration(
      counterText: '',
      errorText: showError ? 'Enter valid country code and phone no' : null,
      hintStyle: TextStyle(
        color: Theme.of(context).hintColor,
        fontSize: 16,
        fontWeight: config.FontFamily().book,
      ),
      hintText: hintText,
      contentPadding: EdgeInsets.symmetric(
        horizontal: config.AppConfig(context).appWidth(5),
        vertical: config.AppConfig(context).appWidth(3),
      ),
      fillColor: config.AppColors().textFieldBackgroundColor(1),
      filled: true,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
      ),
      border: InputBorder.none,
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: const Color(0xFFFFFBF7)),
      ),
    );
  }
}

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
                                color: const Color(0xB3FFFBF7),
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
                                color: const Color(0xB3FFFBF7),
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
            child: Text(
              'Upload Photos',
              style: TextStyle(
                color: const Color(0xFFFFFBF7),
                fontSize: 18,
                fontWeight: config.FontFamily().book,
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
      if (!context.mounted || picture == null) {
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

class _LoginButton extends StatelessWidget {
  final _CookProfilePage? loginForm;

  const _LoginButton({this.loginForm});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CookProfileCubit, CookProfileState>(
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
                context.read<CookProfileCubit>().onKitchnUpload();
              }
            },
            child: Text(
              'SUBMIT',
              style: TextStyle(
                color: const Color(0xFFFFFBF7),
                fontSize: 18,
                fontWeight: config.FontFamily().book,
              ),
            ),
          ),
        );
      },
    );
  }
}
