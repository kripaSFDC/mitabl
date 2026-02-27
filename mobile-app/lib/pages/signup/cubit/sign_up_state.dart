part of 'sign_up_cubit.dart';

class SignUpState extends Equatable {
  const SignUpState(
      {this.phone = const Phone.pure(),
      this.email = const Email.pure(),
      this.nameFirst = const Name.pure(),
      this.nameLast = const Name.pure(),
      this.address = const Name.pure(),
      this.status = FormzStatus.pure,
      this.statusApi = FormzStatus.pure,
      this.selectedRole = AppConstants.FOODI,
      this.password = const Password.pure(),
      this.confirmPassword = const ConfirmPassword.pure(),
      this.showPassword = true,
      this.serverMessage = '',
      this.showConfirmPassword = true});

  final Name? nameFirst;
  final Name? address;
  final Name? nameLast;
  final Email? email;
  final Phone phone;
  final FormzStatus? status;
  final FormzStatus? statusApi;
  final int selectedRole;
  final Password password;
  final ConfirmPassword confirmPassword;
  final bool showPassword;
  final bool showConfirmPassword;
  final String serverMessage;

  SignUpState copyWith(
      {int? selectedRole,
      bool? showPassword,
      bool? showConfirmPassword,
      Password? password,
      ConfirmPassword? confirmPassword,
      FormzStatus? status,
      FormzStatus? statusApi,
      Name? nameFirst,
      Name? address,
      Name? nameLast,
      Email? email,
      String? serverMessage,
      Phone? phone}) {
    return SignUpState(
        statusApi: statusApi ?? this.statusApi,
        showConfirmPassword: showConfirmPassword ?? this.showConfirmPassword,
        showPassword: showPassword ?? this.showPassword,
        password: password ?? this.password,
        serverMessage: serverMessage ?? this.serverMessage,
        confirmPassword: confirmPassword ?? this.confirmPassword,
        address: address ?? this.address,
        selectedRole: selectedRole ?? this.selectedRole,
        status: status ?? this.status,
        email: email ?? this.email,
        nameFirst: nameFirst ?? this.nameFirst,
        nameLast: nameLast ?? this.nameLast,
        phone: phone ?? this.phone);
  }

  @override
  List<Object?> get props => [
        statusApi,
        showPassword,
        showConfirmPassword,
        confirmPassword,
        password,
        selectedRole,
        address,
        status,
        nameLast,
        nameFirst,
        phone,
        email,
        serverMessage
      ];
}
