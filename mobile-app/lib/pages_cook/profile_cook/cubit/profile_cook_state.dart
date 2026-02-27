part of 'profile_cook_cubit.dart';

class ProfileCookState extends Equatable {
  const ProfileCookState(
      {this.firstName = const Name.pure(),
      this.lastName = const Name.pure(),
      this.description = const Name.pure(),
      this.phoneNo = const Phone.pure(),
      this.email = const Email.pure(),
      this.cookProfile,
      this.status = FormzStatus.pure,
      this.statusUpload = FormzStatus.pure,
      this.avatarPath = '',
      this.tabIndex = 0,
      this.kitchenProfile,
      this.pathFiles = const [],
      this.daysTiming = const [],
      this.daysTimingOriginal = const [],
      this.selectedPage = 0});

  final int? tabIndex;
  final Name? firstName;
  final Name? lastName;
  final Name? description;
  final Phone? phoneNo;
  final Email? email;
  final GetCookProfileModel? cookProfile;
  final FormzStatus? status;
  final FormzStatus? statusUpload;
  final String? avatarPath;
  final KitchenProfile? kitchenProfile;
  final List<ImagesCook> pathFiles;
  final int? selectedPage;
  final List<Days> daysTiming;
  final List<Days>? daysTimingOriginal;

  ProfileCookState copyWith({
    List<Days>? daysTiming,
    List<Days>? daysTimingOriginal,
    int? selectedPage,
    List<ImagesCook>? pathFiles,
    KitchenProfile? kitchenProfile,
    int? tabIndex,
    String? avatarPath,
    FormzStatus? statusUpload,
    Name? firstName,
    Name? lastName,
    Name? description,
    Phone? phoneNo,
    Email? email,
    FormzStatus? status,
    GetCookProfileModel? cookProfile,
  }) {
    return ProfileCookState(
        daysTimingOriginal: daysTimingOriginal ?? this.daysTimingOriginal,
        daysTiming: daysTiming ?? this.daysTiming,
        selectedPage: selectedPage ?? this.selectedPage,
        pathFiles: pathFiles ?? this.pathFiles,
        kitchenProfile: kitchenProfile ?? this.kitchenProfile,
        tabIndex: tabIndex ?? this.tabIndex,
        statusUpload: statusUpload ?? this.statusUpload,
        avatarPath: avatarPath ?? this.avatarPath,
        status: status ?? this.status,
        email: email ?? this.email,
        description: description ?? this.description,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        cookProfile: cookProfile ?? this.cookProfile,
        phoneNo: phoneNo ?? this.phoneNo);
  }

  @override
  List<Object?> get props => [
        daysTimingOriginal,
        daysTiming,
        selectedPage,
        pathFiles,
        kitchenProfile,
        tabIndex,
        statusUpload,
        avatarPath,
        status,
        email,
        phoneNo,
        firstName,
        lastName,
        description,
        cookProfile
      ];
}
