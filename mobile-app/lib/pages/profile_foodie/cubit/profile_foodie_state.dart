part of 'profile_foodie_cubit.dart';

class ProfileFoodieState extends Equatable {
  const ProfileFoodieState({
    this.firstName = const Name.pure(),
    this.lastName = const Name.pure(),
    this.description = const Name.pure(),
    this.phoneNo = const Phone.pure(),
    this.email = const Email.pure(),
    this.foodieProfile,
    this.status = FormzStatus.pure,
    this.statusUpload = FormzStatus.pure,
    this.avatarPath = '',
  });

  final Name? firstName;
  final Name? lastName;
  final Name? description;
  final Phone? phoneNo;
  final Email? email;
  final GetCookProfileModel? foodieProfile;
  final FormzStatus? status;
  final FormzStatus? statusUpload;
  final String? avatarPath;

  ProfileFoodieState copyWith({
    String? avatarPath,
    FormzStatus? statusUpload,
    Name? firstName,
    Name? lastName,
    Name? description,
    Phone? phoneNo,
    Email? email,
    FormzStatus? status,
    GetCookProfileModel? foodieProfile,
  }) {
    return ProfileFoodieState(
        statusUpload: statusUpload ?? this.statusUpload,
        avatarPath: avatarPath ?? this.avatarPath,
        status: status ?? this.status,
        email: email ?? this.email,
        description: description ?? this.description,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        foodieProfile: foodieProfile ?? this.foodieProfile,
        phoneNo: phoneNo ?? this.phoneNo);
  }

  @override
  List<Object?> get props => [
        statusUpload,
        avatarPath,
        status,
        email,
        phoneNo,
        firstName,
        lastName,
        description,
        foodieProfile
      ];
}
