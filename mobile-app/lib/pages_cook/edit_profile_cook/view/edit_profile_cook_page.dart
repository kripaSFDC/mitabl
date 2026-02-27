import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import '../../../helper/helper.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';
import '../../profile_cook/cubit/profile_cook_cubit.dart';
import 'package:formz/formz.dart';

class EditProfileCookPage extends StatefulWidget {
  const EditProfileCookPage({Key? key}) : super(key: key);

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => const EditProfileCookPage(),
    );
  }

  @override
  State<EditProfileCookPage> createState() => _EditProfileCookPageState();
}

class _EditProfileCookPageState extends State<EditProfileCookPage> {
  TextEditingController? firstName = TextEditingController();
  TextEditingController? lastName = TextEditingController();
  TextEditingController? email = TextEditingController();
  TextEditingController? phone = TextEditingController();
  TextEditingController? description = TextEditingController();

  @override
  void initState() {
    firstName!.addListener(() {
      context
          .read<ProfileCookCubit>()
          .onFirstNameChanged(value: firstName!.text);
    });
    lastName!.addListener(() {
      context.read<ProfileCookCubit>().onLastNameChanged(value: lastName!.text);
    });
    email!.addListener(() {
      context.read<ProfileCookCubit>().onEmailChanged(value: email!.text);
    });
    phone!.addListener(() {
      context.read<ProfileCookCubit>().onPhoneChanged(value: phone!.text);
    });
    description!.addListener(() {
      context
          .read<ProfileCookCubit>()
          .onDescriptionChanged(value: description!.text);
    });

    firstName!.text = context.read<ProfileCookCubit>().state.firstName!.value;
    lastName!.text = context.read<ProfileCookCubit>().state.lastName!.value;
    description!.text =
        context.read<ProfileCookCubit>().state.description!.value;
    email!.text = context.read<ProfileCookCubit>().state.email!.value;
    phone!.text = context.read<ProfileCookCubit>().state.phoneNo!.value;
  }

  void _openGallery(BuildContext context) async {
    var picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    try {
      if (picture!.path != null) {
        print('path ${picture.path}');
        context
            .read<ProfileCookCubit>()
            .onAvatarImageSelect(path: picture.path);
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
            .read<ProfileCookCubit>()
            .onAvatarImageSelect(path: picture.path);
      } else {
        Helper.showToast('No image captured.');
      }
    } catch (e) {
      Helper.showToast('No image captured.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: Column(
            children: [
              SizedBox(
                height: config.AppConfig(context).appHeight(5),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      navigatorKey.currentState!.pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: config.AppConfig(context).appWidth(5),
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: config.AppConfig(context).appWidth(2),
                  ),
                  Text(
                    'Profile',
                    style: GoogleFonts.gothicA1(
                        color: Theme.of(context).primaryColorDark,
                        fontSize: config.AppConfig(context).appWidth(6),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(
                height: config.AppConfig(context).appHeight(4),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      BlocBuilder<ProfileCookCubit, ProfileCookState>(
                        builder: (context, state) {
                          return state.avatarPath!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.file(
                              File(state.avatarPath!),
                              fit: BoxFit.cover,
                              height: config.AppConfig(context).appWidth(18),
                              width: config.AppConfig(context).appWidth(18),
                            ),
                          )
                              : CachedNetworkImage(
                            imageUrl:
                            "${GlobalConfiguration().getValue<String>('base_url')}/${state.cookProfile!.data!.avatar}",
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                            errorWidget: (context, url, error) => Container(
                                height: config.AppConfig(context).appWidth(18),
                                width: config.AppConfig(context).appWidth(18),
                                padding: EdgeInsets.all(
                                    config.AppConfig(context).appWidth(3)),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: config.AppConfig(context).appWidth(8),
                                )),
                            imageBuilder: (context, imageProvider) => Container(
                              height: config.AppConfig(context).appWidth(18),
                              width: config.AppConfig(context).appWidth(18),
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(100)),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(1),
                      ),
                      InkWell(
                        onTap: () {
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
                                        color: Theme.of(context).primaryColor,
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
                                        color: Theme.of(context).primaryColor,
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
                        },
                        child: Text(
                          'Upload image',
                          style: GoogleFonts.gothicA1(
                              color: Theme.of(context).primaryColor,
                              fontSize: config.AppConfig(context).appHeight(2.2)),
                        ),
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _FirstName(editProfile: this),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _LastName(
                        editProfile: this,
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _Email(
                        editProfile: this,
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _PhoneNo(
                        editProfile: this,
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _Description(
                        editProfile: this,
                      ),
                      SizedBox(
                        height: config.AppConfig(context).appHeight(2),
                      ),
                      _UpdateButton(
                        editProfile: this,
                      )
                    ],
                  ),
                ),
              )



            ],
          ),
        ),
      ),
    );
  }
}

class _Email extends StatefulWidget {
  _EditProfileCookPageState? editProfile;

  _Email({Key? key, this.editProfile}) : super(key: key);

  @override
  State<_Email> createState() => _EmailState();
}

class _EmailState extends State<_Email> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
        builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.editProfile!.email,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 55,
          onChanged: (text) {
            // context.read<ProfileCookCubit>().onEmailChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText:
                state.email!.invalid ? 'Please enter a valid email id' : null,

            // suffixIcon: state.email!.valid
            //     ? Icon(
            //         Icons.check_circle_outline,
            //         color: Theme.of(context).primaryColor,
            //       )
            //     : SizedBox(),
            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            hintText: 'Email Address',
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

class _FirstName extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _FirstName({Key? key, this.editProfile}) : super(key: key);

  @override
  State<_FirstName> createState() => _FirstNameState();
}

class _FirstNameState extends State<_FirstName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
        builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.editProfile!.firstName,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 15,
          onChanged: (text) {
            // context.read<ProfileCookCubit>().onFirstNameChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: state.firstName!.invalid
                ? 'Please enter a valid first name'
                : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'First Name',
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

class _LastName extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _LastName({Key? key, this.editProfile}) : super(key: key);

  @override
  State<_LastName> createState() => _LastNameState();
}

class _LastNameState extends State<_LastName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
        builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.editProfile!.lastName,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 15,
          onChanged: (text) {
            // context.read<ProfileCookCubit>().onLastNameChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: state.lastName!.invalid
                ? 'Please enter a valid last name'
                : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'Last Name',
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

class _Description extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _Description({Key? key, this.editProfile}) : super(key: key);

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
        builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.editProfile!.description,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 300,
          maxLines: 5,
          onChanged: (text) {
            // context.read<ProfileCookCubit>().onFirstNameChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: state.description!.invalid
                ? 'Please enter a valid description'
                : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'Description',
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
  final _EditProfileCookPageState? editProfile;

  const _PhoneNo({Key? key, this.editProfile}) : super(key: key);

  @override
  State<_PhoneNo> createState() => _PhoneNoState();
}

class _PhoneNoState extends State<_PhoneNo> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCookCubit, ProfileCookState>(
        builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.editProfile!.phone,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          maxLength: 15,
          onChanged: (text) {
            // context.read<ProfileCookCubit>().onPhoneChanged(value: text);
          },
          decoration: InputDecoration(
            counterText: '',
            errorText:
                state.phoneNo!.invalid ? 'Please enter a valid phone no' : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
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

class _UpdateButton extends StatelessWidget {
  final _EditProfileCookPageState? editProfile;

  const _UpdateButton({Key? key, this.editProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCookCubit, ProfileCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        return /*state.status!.isSubmissionInProgress
            ? const CircularProgressIndicator()
            :*/
            Container(
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
              )),
          child: MaterialButton(
              child: state.statusUpload!.isSubmissionInProgress
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'SAVE CHANGES',
                      style: GoogleFonts.gothicA1(
                          fontSize: config.AppConfig(context).appWidth(3.5),
                          color: Colors.white),
                    ),
              minWidth: config.AppConfig(context).appWidth(100),
              height: 50.0,
              onPressed: () {
                if (state.status!.isValidated) {
                  context.read<ProfileCookCubit>().updateCookProfile();
                }
              }),
        );
      },
    );
  }
}
