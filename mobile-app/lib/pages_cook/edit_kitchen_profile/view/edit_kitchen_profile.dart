import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages_cook/edit_kitchen_profile/cubit/edit_kitchen_profile_cubit.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/helper.dart';
import '../elements/timing_edit.dart';

class EditKitchenProfilePage extends StatefulWidget {
  EditKitchenProfilePage({Key? key, this.routeArguments}) : super(key: key);

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) =>
            BlocProvider(
              create: (context) =>
                  EditKitchenProfileCubit(
                      routeArguments: routeArguments,
                      userRepository: context.read<UserRepository>()),
              child: EditKitchenProfilePage(routeArguments: routeArguments),
            ));
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
    nameTextEditor!.addListener(() {
      context
          .read<EditKitchenProfileCubit>()
          .onKitchnNameChanged(value: nameTextEditor!.text);
    });

    addressTextEditor!.addListener(() {
      context
          .read<EditKitchenProfileCubit>()
          .onAddressChanged(value: addressTextEditor!.text);
    });
    mobileNoTextEditor!.addListener(() {
      context
          .read<EditKitchenProfileCubit>()
          .onPhoneChanged(value: mobileNoTextEditor!.text);
    });
    noOfSeatsTextEditor!.addListener(() {
      context
          .read<EditKitchenProfileCubit>()
          .onSeatChanged(value: noOfSeatsTextEditor!.text);
    });

    abnNoTextEditor!.addListener(() {
      // context.read<EditKitchenProfileCubit>().onSeatChanged(
      //     value: abnNoTextEditor!.text
      // );
    });
    certificateTextEditor!.addListener(() {
      // context.read<EditKitchenProfileCubit>().onSeatChanged(
      //     value: certificateTextEditor!.text
      // );
    });
    bioTextEditor!.addListener(() {
      context
          .read<EditKitchenProfileCubit>()
          .onBioChanged(value: bioTextEditor!.text);
    });

    nameTextEditor!.text = widget.routeArguments!.kitchen!.name!.toString();
    addressTextEditor!.text =
        widget.routeArguments!.kitchen!.address!.toString();
    mobileNoTextEditor!.text =
        widget.routeArguments!.kitchen!.phone!.toString();
    noOfSeatsTextEditor!.text =
        widget.routeArguments!.kitchen!.noOfSeats.toString();
    // abnNoTextEditor!.text = widget.routeArguments!.kitchen!.abn ?? '';
    // certificateTextEditor!.text =
    //     widget.routeArguments!.kitchen!.certificateNo ?? '';
    bioTextEditor!.text = widget.routeArguments!.kitchen!.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditKitchenProfileCubit, EditKitchenProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leadingWidth: config.AppConfig(context).appWidth(50),
              leading: Padding(
                padding: EdgeInsets.only(
                    left: config.AppConfig(context).appWidth(5)),
                child: InkWell(
                  onTap: () {
                    navigatorKey.currentState!.pop();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        color: Theme
                            .of(context)
                            .primaryColorDark,
                        size: config.AppConfig(context).appWidth(5),
                      ),
                      SizedBox(
                        width: config.AppConfig(context).appWidth(2),
                      ),
                      Text(
                        'Profile',
                        style: GoogleFonts.gothicA1(
                            color: Theme
                                .of(context)
                                .primaryColorDark,
                            fontSize: config.AppConfig(context).appWidth(5),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              alignment: Alignment.center,
              color: Colors.white,
              height: config.AppConfig(context).appHeight(100),
              width: config.AppConfig(context).appWidth(100),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: config.AppConfig(context).appHeight(2),
                      left: config.AppConfig(context).appWidth(5),
                      right: config.AppConfig(context).appWidth(5)),
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
                              ? Container(
                            height:
                            config.AppConfig(context).appHeight(20),
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
                                      horizontal:
                                      config.AppConfig(context)
                                          .appWidth(2)),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: config.AppConfig(context)
                                            .appHeight(20),
                                        width: config.AppConfig(context)
                                            .appWidth(85),
                                        decoration: BoxDecoration(
                                          color: config.AppColors()
                                              .textFieldBackgroundColor(
                                              1),
                                          borderRadius:
                                          BorderRadius.circular(
                                              config.AppConfig(
                                                  context)
                                                  .appWidth(5)),
                                        ),
                                        alignment: Alignment.center,
                                        child: CachedNetworkImage(
                                          imageUrl:
                                          '${GlobalConfiguration().getValue<
                                              String>('image_base_url')}${state
                                              .pathFiles[index].path}',
                                          errorWidget:
                                              (context, data, e) {
                                            return Image.file(File(state
                                                .pathFiles[index].path!),
                                              errorBuilder: (context, data, e) {
                                                return Icon(Icons.error_outline);
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
                                                      .pathFiles[
                                                  index]
                                                      .path,imagesCook: state
                                                  .pathFiles[
                                              index]);
                                            },
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: config.AppConfig(
                                                  context)
                                                  .appWidth(6),
                                            ),
                                          )),
                                    ],
                                  ),
                                );
                              },
                              itemCount: state.pathFiles.length,
                            ),
                          )
                              : Container(
                            height:
                            config.AppConfig(context).appHeight(20),
                            decoration: BoxDecoration(
                                color: config.AppColors()
                                    .textFieldBackgroundColor(1),
                                borderRadius: BorderRadius.circular(
                                    config.AppConfig(context)
                                        .appWidth(5))),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.photo_outlined,
                              size:
                              config.AppConfig(context).appWidth(30),
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(
                            height: config.AppConfig(context).appHeight(2),
                          ),
                          state.pathFiles.isNotEmpty
                              ? Container(
                            alignment: Alignment.center,
                            height:
                            config.AppConfig(context).appHeight(5),
                            child: ListView.separated(
                              // controller: controller,
                              separatorBuilder: (context, index) {
                                return SizedBox(
                                  width: config.AppConfig(context)
                                      .appWidth(2),
                                );
                              },
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: config.AppConfig(context)
                                      .appWidth(2),
                                  decoration: BoxDecoration(
                                      color: state.selectedPage == index
                                          ? Colors.blue
                                          : Colors.grey,
                                      shape: BoxShape.circle),
                                );
                              },
                              itemCount: state.pathFiles.length,
                            ),
                          )
                              : SizedBox(),
                          SizedBox(
                            height: config.AppConfig(context).appHeight(2),
                          ),
                          _UploadButton(
                            loginForm: this,
                          ),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(2),
                                ),
                                _KitchenName(
                                  loginForm: this,
                                ),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(2),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.zero,
                                  child: TextFormField(
                                    controller: addressTextEditor,
                                    style: TextStyle(color: Colors.black),
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
                                          color: Theme
                                              .of(context)
                                              .hintColor,
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4)),
                                      // labelText: 'Mobile Number',
                                      hintText: 'Address',
                                      contentPadding: EdgeInsets.all(
                                          config.AppConfig(context)
                                              .appWidth(2)),
                                      fillColor: config.AppColors()
                                          .textFieldBackgroundColor(1),
                                      filled: true,
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(2),
                                ),
                                _PhoneNo(
                                  loginForm: this,
                                ),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(2),
                                ),
                                _NoOfSeats(
                                  loginForm: this,
                                ),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(2),
                                ),
                                _Timing(loginForm: this),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(3),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        width: config.AppConfig(context)
                                            .appWidth(40),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: config.AppColors()
                                              .textFieldBackgroundColor(1),
                                          borderRadius:
                                          BorderRadius.circular(20),
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
                                                          value: value);
                                                    },
                                                  ),
                                                  Text(
                                                    'Dine-in',
                                                    style: GoogleFonts.gothicA1(
                                                        fontSize:
                                                        config.AppConfig(
                                                            context)
                                                            .appHeight(2),
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: config.AppConfig(context)
                                                  .appWidth(3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                      config.AppConfig(context).appWidth(3),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        width: config.AppConfig(context)
                                            .appWidth(40),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: config.AppColors()
                                              .textFieldBackgroundColor(1),
                                          borderRadius:
                                          BorderRadius.circular(20),
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
                                                          value: value);
                                                    },
                                                  ),
                                                  Text(
                                                    'Takeaway',
                                                    style: GoogleFonts.gothicA1(
                                                        fontSize:
                                                        config.AppConfig(
                                                            context)
                                                            .appHeight(2),
                                                        color: Colors.grey),
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
                                  height:
                                  config.AppConfig(context).appHeight(3),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.zero,
                                  child: TextFormField(
                                    controller: bioTextEditor,
                                    style: TextStyle(color: Colors.black),
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
                                          color: Theme
                                              .of(context)
                                              .hintColor,
                                          fontSize: config.AppConfig(context)
                                              .appWidth(4)),
                                      // labelText: 'Mobile Number',
                                      hintText: 'Bio',
                                      contentPadding: EdgeInsets.all(
                                          config.AppConfig(context)
                                              .appWidth(2)),
                                      fillColor: config.AppColors()
                                          .textFieldBackgroundColor(1),
                                      filled: true,
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                  config.AppConfig(context).appHeight(3),
                                ),
                                _LoginButton(
                                  loginForm: this,
                                ),
                              ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }
}

class _Timing extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _Timing({Key? key, this.loginForm}) : super(key: key);

  @override
  State<_Timing> createState() => _TimingState();
}

class _TimingState extends State<_Timing> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      print('constraibtWidth ${constraint.maxWidth}');
      return BlocBuilder<EditKitchenProfileCubit, EditKitchenProfileState>(
          builder: (context, state) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: TextFormField(
                readOnly: true,
                style: TextStyle(color: Colors.black),
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
                      context.read<EditKitchenProfileCubit>().onOpenTimingDialog();
                      showDialog(
                          context: context,
                          builder: (contexts) {
                            return BlocProvider.value(
                              value: context.read<EditKitchenProfileCubit>(),
                              child: EditTimingDialog(),
                            );
                          });
                    },
                    child: Icon(
                      Icons.access_time_rounded,
                      color: Theme
                          .of(context)
                          .primaryColor,
                    ),
                  ),
                  hintStyle: GoogleFonts.gothicA1(
                      color: Theme
                          .of(context)
                          .hintColor,
                      fontSize: config.AppConfig(context).appWidth(4)),
                  // labelText: 'Mobile Number',
                  hintText: 'Timings',
                  contentPadding:
                  EdgeInsets.all(config.AppConfig(context).appWidth(2)),
                  fillColor: config.AppColors().textFieldBackgroundColor(1),
                  filled: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  border: InputBorder.none,
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          });
    });
  }
}

class _KitchenName extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _KitchenName({Key? key, this.loginForm}) : super(key: key);

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
              style: TextStyle(color: Colors.black),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              maxLength: 15,
              onChanged: (text) {
                context
                    .read<EditKitchenProfileCubit>()
                    .onKitchnNameChanged(value: text);
              },
              decoration: InputDecoration(
                counterText: '',
                errorText:
                state.nameKitchn!.invalid ? 'Please enter a valid name' : null,

                hintStyle: GoogleFonts.gothicA1(
                    color: Theme
                        .of(context)
                        .hintColor,
                    fontSize: config.AppConfig(context).appWidth(4)),
                // labelText: 'Mobile Number',
                hintText: 'mikitchn name',
                contentPadding:
                EdgeInsets.all(config.AppConfig(context).appWidth(2)),
                fillColor: config.AppColors().textFieldBackgroundColor(1),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                border: InputBorder.none,
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class _NoOfSeats extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _NoOfSeats({Key? key, this.loginForm}) : super(key: key);

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
              style: TextStyle(color: Colors.black),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onChanged: (text) {
                context.read<EditKitchenProfileCubit>().onSeatChanged(
                    value: text);
              },
              decoration: InputDecoration(
                counterText: '',
                errorText:
                state.noOfSeats.invalid ? 'Please enter a valid seats' : null,
                hintStyle: GoogleFonts.gothicA1(
                    color: Theme
                        .of(context)
                        .hintColor,
                    fontSize: config.AppConfig(context).appWidth(4)),
                hintText: 'No. of seats',
                contentPadding:
                EdgeInsets.all(config.AppConfig(context).appWidth(2)),
                fillColor: config.AppColors().textFieldBackgroundColor(1),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                border: InputBorder.none,
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class _PhoneNo extends StatefulWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _PhoneNo({Key? key, this.loginForm}) : super(key: key);

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
              style: TextStyle(color: Colors.black),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              onChanged: (text) {
                context.read<EditKitchenProfileCubit>().onPhoneChanged(
                    value: text);
              },
              decoration: InputDecoration(
                counterText: '',
                errorText:
                state.phone.invalid ? 'Please enter a valid phone no' : null,

                hintStyle: GoogleFonts.gothicA1(
                    color: Theme
                        .of(context)
                        .hintColor,
                    fontSize: config.AppConfig(context).appWidth(4)),
                // labelText: 'Mobile Number',
                hintText: 'Phone',
                contentPadding:
                EdgeInsets.all(config.AppConfig(context).appWidth(2)),
                fillColor: config.AppColors().textFieldBackgroundColor(1),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                border: InputBorder.none,
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class _UploadButton extends StatefulWidget {
  const _UploadButton({Key? key, this.loginForm}) : super(key: key);

  final _EditKitchenProfilePageState? loginForm;

  @override
  _UploadbuttonState createState() => _UploadbuttonState();
}

class _UploadbuttonState extends State<_UploadButton> {
  final ImagePicker _picker = ImagePicker();

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
                    Theme
                        .of(context)
                        .primaryColor,
                    Theme
                        .of(context)
                        .primaryColor,
                  ])),
          child: MaterialButton(
              child: Text(
                'Upload Photos',
                style: GoogleFonts.gothicA1(
                    fontSize: config.AppConfig(context).appWidth(3.5),
                    color: Colors.white),
              ),
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
                                fontSize:
                                config.AppConfig(context).appWidth(5)),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MaterialButton(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
                                child: const Text(
                                  "Gallery",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  navigatorKey.currentState!.pop(false);
                                },
                              ),
                              MaterialButton(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
                                child: const Text(
                                  "Camera",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  navigatorKey.currentState!.pop(true);
                                },
                              )
                            ],
                          ),
                        );
                      },
                      context: context)
                      .then((value) {
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
              }),
        );
      },
    );
  }

  void _openGallery(BuildContext context) async {
    var picture = await ImagePicker().pickImage(source: ImageSource.gallery);
    // print('path ${picture!.path}');
    try {
      if (picture!.path != null) {
        print('path ${picture.path}');
        context
            .read<EditKitchenProfileCubit>()
            .onNewImageAdded(path: picture.path);
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.loginForm!.controller!
            .jumpTo(widget.loginForm!.controller!.position.maxScrollExtent);
        //});
      } else {
        Helper.showToast('No image selected.');
      }
    } catch (e) {
      Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    var picture = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);

    try {
      if (picture!.path != null) {
        print('path ${picture.path}');
        context
            .read<EditKitchenProfileCubit>()
            .onNewImageAdded(path: picture.path);
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.loginForm!.controller!
            .jumpTo(widget.loginForm!.controller!.position.maxScrollExtent);
        // });
        // widget.loginForm!.controller!.animateTo(context.read<EditKitchenProfileCubit>().state.pathFiles.length.toDouble(), duration: Duration(milliseconds: 100 ), curve: Curves.ease);

      } else {
        Helper.showToast('No image captured.');
      }
    } catch (e) {
      Helper.showToast('No image captured.');
    }
  }
}

class _LoginButton extends StatelessWidget {
  final _EditKitchenProfilePageState? loginForm;

  const _LoginButton({Key? key, this.loginForm}) : super(key: key);

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
                  Theme
                      .of(context)
                      .primaryColor,
                  Theme
                      .of(context)
                      .primaryColor,
                ]
                    : [
                  Theme
                      .of(context)
                      .primaryColorLight,
                  Theme
                      .of(context)
                      .primaryColorLight,
                ],
              )),
          child: MaterialButton(
              child: state.statusApi!.isSubmissionInProgress
                  ? const Center(
                child: CupertinoActivityIndicator(
                  color: Colors.white,
                ),
              )
                  : Text(
                'SUBMIT',
                style: GoogleFonts.gothicA1(
                    fontSize: config.AppConfig(context).appWidth(3.5),
                    color: Colors.white),
              ),
              minWidth: config.AppConfig(context).appWidth(100),
              height: 50.0,
              onPressed: () {
                //
                // navigatorKey.currentState!.popAndPushNamed('/OTPPage');
                // return;
                if (state.status!.isValidated) {
                  context.read<EditKitchenProfileCubit>().onKitchenEditUpload();
                }
              }),
        );
      },
    );
  }
}
