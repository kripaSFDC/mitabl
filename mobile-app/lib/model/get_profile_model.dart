class GetCookProfileModel {
  int? status;
  bool? isSuccess;
  String? message;
  Data? data;

  GetCookProfileModel({this.status, this.isSuccess, this.message, this.data});

  GetCookProfileModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  int? emailVerified;
  int? roleId;
  String? avatar;
  String? description;
  dynamic phone;
  String? address;
  String? role;
  Kitchen? kitchen;
  RoleMembership? cookRoleMembership;
  RoleMembership? foodieRoleMembership;
  List<AvailableRoleMembership> availableRoles;

  Data(
      {this.id,
      this.firstName,
      this.lastName,
      this.email,
      this.emailVerified,
      this.roleId,
      this.avatar,
      this.description,
      this.phone,
      this.address,
      this.role,
      this.kitchen,
      this.cookRoleMembership,
      this.foodieRoleMembership,
      this.availableRoles = const []});

  Data.fromJson(Map<String, dynamic> json) : availableRoles = const [] {
    id = _asInt(json['id']);
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    emailVerified = _asInt(json['email_verified']);
    roleId = _asInt(json['role_id']);
    avatar = json['avatar'];
    description = json['description'];
    phone = json['phone'];
    address = json['address'];
    role = json['role'];
    kitchen =
        json['kitchen'] != null ? Kitchen.fromJson(json['kitchen']) : null;

    final availableRolesJson = json['available_roles'];
    if (availableRolesJson is List) {
      availableRoles = availableRolesJson
          .whereType<Map<String, dynamic>>()
          .map(AvailableRoleMembership.fromJson)
          .toList();
    } else {
      availableRoles = const [];
    }

    cookRoleMembership = RoleMembership.fromProfileJson(
      json,
      roleAliases: const [
        'micook',
        'mikitchn',
        'cook',
        'restaurant',
        'vendor',
        '2',
      ],
    );
    foodieRoleMembership = RoleMembership.fromProfileJson(
      json,
      roleAliases: const ['mifoodi', 'foodi', 'foodie', '3'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['email_verified'] = emailVerified;
    data['role_id'] = roleId;
    data['avatar'] = avatar;
    data['description'] = description;
    data['phone'] = phone;
    data['address'] = address;
    data['role'] = role;
    if (kitchen != null) {
      data['kitchen'] = kitchen!.toJson();
    }
    if (cookRoleMembership != null) {
      data['cook_role_membership'] = cookRoleMembership!.toJson();
    }
    if (foodieRoleMembership != null) {
      data['foodie_role_membership'] = foodieRoleMembership!.toJson();
    }
    data['available_roles'] =
        availableRoles.map((role) => role.toJson()).toList();
    return data;
  }
}

class RoleMembership {
  final bool exists;
  final bool active;
  final bool onboardingRequired;
  final String? nextRequiredStep;
  final String? status;

  const RoleMembership({
    required this.exists,
    required this.active,
    required this.onboardingRequired,
    this.nextRequiredStep,
    this.status,
  });

  bool get isDisabled => status?.toLowerCase() == 'disabled';

  factory RoleMembership.fromJson(Map<String, dynamic> json) {
    final onboardingRequired = _asBool(
      json['onboarding_required'] ??
          json['is_onboarding'] ??
          json['onboarding'],
    );

    final active = _asBool(json['active'] ?? json['is_active']) ||
        (json['status']?.toString().toLowerCase() == 'active');

    final exists = _asBool(
          json['exists'] ?? json['has_membership'] ?? json['registered'],
        ) ||
        active ||
        onboardingRequired;

    return RoleMembership(
      exists: exists,
      active: active,
      onboardingRequired: onboardingRequired,
      nextRequiredStep: json['next_required_step']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'active': active,
      'onboarding_required': onboardingRequired,
      'next_required_step': nextRequiredStep,
      'status': status,
    };
  }

  static RoleMembership? fromProfileJson(
    Map<String, dynamic> profileJson, {
    required List<String> roleAliases,
  }) {
    final normalizedAliases = roleAliases.map((e) => e.toLowerCase()).toSet();
    final containers = [
      profileJson['role_statuses'],
      profileJson['role_memberships'],
      profileJson['roles'],
      profileJson['memberships'],
    ];

    for (final container in containers) {
      if (container is! Map<String, dynamic>) continue;
      for (final entry in container.entries) {
        if (!normalizedAliases.contains(entry.key.toLowerCase())) continue;
        final membership = entry.value;
        if (membership is Map<String, dynamic>) {
          return RoleMembership.fromJson(membership);
        }
      }
    }


    final availableRoles = profileJson['available_roles'];
    if (availableRoles is List) {
      for (final item in availableRoles) {
        if (item is! Map<String, dynamic>) continue;
        final roleValue = item['role']?.toString().toLowerCase();
        final roleId = item['role_id']?.toString().toLowerCase();
        if (normalizedAliases.contains(roleValue) ||
            (roleId != null && normalizedAliases.contains(roleId))) {
          return RoleMembership.fromJson(item);
        }
      }
    }

    for (final alias in normalizedAliases) {
      final directMembership = profileJson['${alias}_membership'] ??
          profileJson['${alias}_role_membership'];
      if (directMembership is Map<String, dynamic>) {
        return RoleMembership.fromJson(directMembership);
      }
    }

    return null;
  }
}


class AvailableRoleMembership {
  final int? roleId;
  final String? role;
  final String? status;
  final bool onboarding;

  const AvailableRoleMembership({
    this.roleId,
    this.role,
    this.status,
    this.onboarding = false,
  });

  bool get isDisabled => status?.toLowerCase() == 'disabled';
  bool get isActive => status?.toLowerCase() == 'active';

  factory AvailableRoleMembership.fromJson(Map<String, dynamic> json) {
    return AvailableRoleMembership(
      roleId: _asInt(json['role_id']),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      onboarding: _asBool(json['onboarding'] ?? json['onboarding_required']),
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

class Kitchen {
  int? id;
  int? userId;
  int? open;
  String? name;
  String? address;
  String? phone;
  int? noOfSeats;
  String? timings;
  int? dineIn;
  int? takeAway;
  String? description;
  String? abn;
  String? certificateNo;
  dynamic certificateDoc;
  String? status;
  int? available;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;
  List<ReviewsData>? reviewsData;
  double? ratingCount;
  List<ImagesCook>? images;
  List<DineInSlotTemplate>? dineInSlots;

  Kitchen(
      {this.id,
      this.userId,
      this.open,
      this.name,
      this.address,
      this.phone,
      this.noOfSeats,
      this.timings,
      this.dineIn,
      this.takeAway,
      this.description,
      this.abn,
      this.certificateNo,
      this.certificateDoc,
      this.status,
      this.available,
      this.latitude,
      this.longitude,
      this.createdAt,
      this.updatedAt,
      this.reviewsData,
      this.ratingCount,
      this.images,
      this.dineInSlots});

  Kitchen.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    userId = _asInt(json['user_id']);
    open = _asInt(json['open']);
    name = json['name'];
    address = json['address'];
    phone = json['phone'];
    noOfSeats = _asInt(json['no_of_seats']);
    timings = json['timings'];
    dineIn = _asInt(json['dine_in']);
    takeAway = _asInt(json['take_away']);
    description = json['description'];
    abn = json['abn'];
    certificateNo = json['certificate_no'];
    certificateDoc = json['certificate_doc'];
    status = json['status'];
    available = _asInt(json['available']);
    latitude = _asDouble(json['latitude']);
    longitude = _asDouble(json['longitude']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['reviewsData'] != null) {
      reviewsData = <ReviewsData>[];
      json['reviewsData'].forEach((v) {
        reviewsData!.add(ReviewsData.fromJson(v));
      });
    }
    ratingCount = _asDouble(json['rating_count']);
    if (json['images'] != null) {
      images = <ImagesCook>[];
      json['images'].forEach((v) {
        images!.add(ImagesCook.fromJson(v));
      });
    }
    if (json['dine_in_slots'] != null) {
      dineInSlots = <DineInSlotTemplate>[];
      json['dine_in_slots'].forEach((v) {
        dineInSlots!.add(DineInSlotTemplate.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['open'] = open;
    data['name'] = name;
    data['address'] = address;
    data['phone'] = phone;
    data['no_of_seats'] = noOfSeats;
    data['timings'] = timings;
    data['dine_in'] = dineIn;
    data['take_away'] = takeAway;
    data['description'] = description;
    data['abn'] = abn;
    data['certificate_no'] = certificateNo;
    data['certificate_doc'] = certificateDoc;
    data['status'] = status;
    data['available'] = available;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (reviewsData != null) {
      data['reviewsData'] = reviewsData!.map((v) => v.toJson()).toList();
    }
    data['rating_count'] = ratingCount;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (dineInSlots != null) {
      data['dine_in_slots'] = dineInSlots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DineInSlotTemplate {
  int? id;
  int? dayOfWeek;
  String? dayName;
  String? startTime;
  String? endTime;
  int? seatCapacity;
  int? status;

  DineInSlotTemplate({
    this.id,
    this.dayOfWeek,
    this.dayName,
    this.startTime,
    this.endTime,
    this.seatCapacity,
    this.status,
  });

  DineInSlotTemplate copyWith({
    int? id,
    int? dayOfWeek,
    String? dayName,
    String? startTime,
    String? endTime,
    int? seatCapacity,
    int? status,
  }) {
    return DineInSlotTemplate(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayName: dayName ?? this.dayName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      status: status ?? this.status,
    );
  }

  DineInSlotTemplate.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    dayOfWeek = _asInt(json['day_of_week']);
    dayName = json['day_name']?.toString();
    startTime = json['start_time']?.toString();
    endTime = json['end_time']?.toString();
    seatCapacity = _asInt(json['seat_capacity']);
    status = _asInt(json['status']) ?? 1;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'day_of_week': dayOfWeek,
      'day_name': dayName,
      'start_time': startTime,
      'end_time': endTime,
      'seat_capacity': seatCapacity,
      'status': status ?? 1,
    };
  }
}

class ReviewsData {
  int? id;
  double? rating;
  String? review;
  String? reviewTag;
  User? user;

  ReviewsData({this.id, this.rating, this.review, this.reviewTag, this.user});

  ReviewsData.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    rating = _asDouble(json['rating']) ?? 0.0;
    review = json['review'];
    reviewTag = json['review_tag'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['rating'] = rating;
    data['review'] = review;
    data['review_tag'] = reviewTag;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? avatar;

  User({this.id, this.name, this.avatar});

  User.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    name = json['name'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['avatar'] = avatar;
    return data;
  }
}

class ImagesCook {
  int? id;
  int? refId;
  String? modelName;
  String? path;
  String? createdAt;
  String? updatedAt;

  ImagesCook(
      {this.id,
      this.refId,
      this.modelName,
      this.path,
      this.createdAt,
      this.updatedAt});

  ImagesCook.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    refId = _asInt(json['ref_id']);
    modelName = json['model_name'];
    path = json['path'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ref_id'] = refId;
    data['model_name'] = modelName;
    data['path'] = path;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is bool) return value ? 1 : 0;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is bool) return value ? 1.0 : 0.0;
  if (value is String) return double.tryParse(value);
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}
