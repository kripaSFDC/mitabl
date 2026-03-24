import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import '../../../helper/helper.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';
import '../../profile_cook/cubit/profile_cook_cubit.dart';
import 'package:mitabl_user/helper/formz_compat.dart';

class EditProfileCookPage extends StatefulWidget {
  const EditProfileCookPage({super.key});

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(builder: (_) => const EditProfileCookPage());
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
    super.initState();
    context.read<ProfileCookCubit>().resetSubmissionStatus();
    firstName!.addListener(() {
      context.read<ProfileCookCubit>().onFirstNameChanged(
            value: firstName!.text,
          );
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
      context.read<ProfileCookCubit>().onDescriptionChanged(
            value: description!.text,
          );
    });

    firstName!.text = context.read<ProfileCookCubit>().state.firstName!.value;
    lastName!.text = context.read<ProfileCookCubit>().state.lastName!.value;
    description!.text =
        context.read<ProfileCookCubit>().state.description!.value;
    email!.text = context.read<ProfileCookCubit>().state.email!.value;
    phone!.text = context.read<ProfileCookCubit>().state.phoneNo!.value;
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
    final cubit = context.read<ProfileCookCubit>();
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
    final cubit = context.read<ProfileCookCubit>();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF7),
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: Column(
            children: [
              SizedBox(height: config.AppConfig(context).appHeight(5)),
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
                  SizedBox(width: config.AppConfig(context).appWidth(2)),
                  Text(
                    'Profile',
                    style: GoogleFonts.gothicA1(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: config.AppConfig(context).appWidth(6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: config.AppConfig(context).appHeight(4)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        MediaQuery.of(context).viewInsets.bottom +
                        config.AppConfig(context).appHeight(4),
                  ),
                  child: Column(
                    children: [
                      BlocBuilder<ProfileCookCubit, ProfileCookState>(
                        builder: (context, state) {
                          final avatarPath = state.avatarPath ?? '';
                          final remoteAvatar = state.cookProfile?.data?.avatar;
                          final imageUrl = remoteAvatar != null &&
                                  remoteAvatar.isNotEmpty
                              ? "${GlobalConfiguration().getValue<String>('base_url')}/$remoteAvatar"
                              : '';

                          return avatarPath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.file(
                                    File(avatarPath),
                                    fit: BoxFit.cover,
                                    height: config.AppConfig(
                                      context,
                                    ).appWidth(18),
                                    width: config.AppConfig(
                                      context,
                                    ).appWidth(18),
                                  ),
                                )
                              : imageUrl.isEmpty
                                  ? Container(
                                      height: config.AppConfig(context)
                                          .appWidth(18),
                                      width: config.AppConfig(context)
                                          .appWidth(18),
                                      padding: EdgeInsets.all(
                                        config.AppConfig(context).appWidth(3),
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: const Color(0xFFFFFBF7),
                                        size: config.AppConfig(context)
                                            .appWidth(8),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      progressIndicatorBuilder:
                                          (context, url, downloadProgress) =>
                                              CircularProgressIndicator(
                                        value: downloadProgress.progress,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        height: config.AppConfig(
                                          context,
                                        ).appWidth(18),
                                        width: config.AppConfig(
                                          context,
                                        ).appWidth(18),
                                        padding: EdgeInsets.all(
                                          config.AppConfig(context).appWidth(3),
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(
                                            context,
                                          ).primaryColorDark,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: const Color(0xFFFFFBF7),
                                          size: config.AppConfig(
                                            context,
                                          ).appWidth(8),
                                        ),
                                      ),
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        height: config.AppConfig(
                                          context,
                                        ).appWidth(18),
                                        width: config.AppConfig(
                                          context,
                                        ).appWidth(18),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                      ),
                                    );
                        },
                      ),
                      SizedBox(height: config.AppConfig(context).appHeight(1)),
                      InkWell(
                        onTap: () {
                          showDialog<bool>(
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  'Add image',
                                  style: GoogleFonts.gothicA1(
                                    color: Colors.black,
                                    fontSize: config.AppConfig(
                                      context,
                                    ).appWidth(5),
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
                        },
                        child: Text(
                          'Upload image',
                          style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColor,
                            fontSize: config.AppConfig(context).appHeight(2.2),
                          ),
                        ),
                      ),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _FirstName(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _LastName(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _Email(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _PhoneNo(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _Description(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                      _UpdateButton(editProfile: this),
                      SizedBox(height: config.AppConfig(context).appHeight(2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Email extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _Email({this.editProfile});

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
            style: const TextStyle(color: Colors.black),
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
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              hintText: 'Email Address',
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

class _FirstName extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _FirstName({this.editProfile});

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
            style: const TextStyle(color: Colors.black),
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
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              // labelText: 'Mobile Number',
              hintText: 'First Name',
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

class _LastName extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _LastName({this.editProfile});

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
            style: const TextStyle(color: Colors.black),
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
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              // labelText: 'Mobile Number',
              hintText: 'Last Name',
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

class _Description extends StatefulWidget {
  final _EditProfileCookPageState? editProfile;

  const _Description({this.editProfile});

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
            style: const TextStyle(color: Colors.black),
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
                fontSize: config.AppConfig(context).appWidth(4),
              ),
              // labelText: 'Mobile Number',
              hintText: 'Description',
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
  final _EditProfileCookPageState? editProfile;

  const _PhoneNo({this.editProfile});

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
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            onChanged: (text) {
              // context.read<ProfileCookCubit>().onPhoneChanged(value: text);
            },
            decoration: InputDecoration(
              counterText: '',
              errorText: state.phoneNo!.invalid
                  ? 'Please enter a valid phone no'
                  : null,

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

class _UpdateButton extends StatelessWidget {
  final _EditProfileCookPageState? editProfile;

  const _UpdateButton({this.editProfile});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCookCubit, ProfileCookState>(
      listener: (context, state) {
        if (state.statusUpload!.isSubmissionSuccess && context.mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        }
      },
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
            ),
          ),
          child: MaterialButton(
            minWidth: config.AppConfig(context).appWidth(100),
            height: 50.0,
            onPressed: () {
              if (state.status!.isValidated) {
                context.read<ProfileCookCubit>().updateCookProfile();
              }
            },
            child: state.statusUpload!.isSubmissionInProgress
                ? const Center(
                    child: CupertinoActivityIndicator(
                      color: Color(0xFFFFFBF7),
                    ),
                  )
                : Text(
                    'SAVE CHANGES',
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
