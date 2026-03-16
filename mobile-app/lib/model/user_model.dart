class UserModel {
  int? responseCode;
  bool? isSuccess;
  String? message;
  Data? data;

  UserModel({this.responseCode, this.isSuccess, this.message, this.data});

  UserModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'] ?? 0;
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? accessToken;
  String? tokenType;
  User? user;

  Data({this.accessToken, this.tokenType, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'] ?? '';
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? role;
  int? roleId;
  List<AvailableRole> availableRoles;

  User({
    this.id,
    this.name,
    this.role,
    this.roleId,
    this.availableRoles = const [],
  });

  User.fromJson(Map<String, dynamic> json) : availableRoles = const [] {
    id = json['id'];
    name = json['name'];
    role = json['role'];
    final roleIdValue = json['role_id'];
    if (roleIdValue is int) {
      roleId = roleIdValue;
    } else if (roleIdValue is String) {
      roleId = int.tryParse(roleIdValue);
    }

    final rolesJson = json['available_roles'];
    if (rolesJson is List) {
      availableRoles = rolesJson
          .whereType<Map<String, dynamic>>()
          .map(AvailableRole.fromJson)
          .toList();
    } else {
      availableRoles = const [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['role'] = role;
    data['role_id'] = roleId;
    data['available_roles'] = availableRoles.map((role) => role.toJson()).toList();
    return data;
  }
}

class AvailableRole {
  int? roleId;
  String? role;
  String? status;
  bool onboarding;

  AvailableRole({
    this.roleId,
    this.role,
    this.status,
    this.onboarding = false,
  });

  factory AvailableRole.fromJson(Map<String, dynamic> json) {
    final roleIdValue = json['role_id'];
    int? parsedRoleId;
    if (roleIdValue is int) {
      parsedRoleId = roleIdValue;
    } else if (roleIdValue is String) {
      parsedRoleId = int.tryParse(roleIdValue);
    }

    final onboardingValue = json['onboarding'] ?? json['onboarding_required'];
    final onboarding = onboardingValue is bool
        ? onboardingValue
        : onboardingValue is num
        ? onboardingValue != 0
        : onboardingValue is String
        ? ['true', '1', 'yes'].contains(onboardingValue.trim().toLowerCase())
        : false;

    return AvailableRole(
      roleId: parsedRoleId,
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      onboarding: onboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role': role,
      'status': status,
      'onboarding': onboarding,
    };
  }
}
