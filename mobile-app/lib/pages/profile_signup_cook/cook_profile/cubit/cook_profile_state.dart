part of 'cook_profile_cubit.dart';

class CookProfileState extends Equatable {
  const CookProfileState({
    this.phone = const InternationalPhone.pure(),
    this.countryCode = '+61',
    this.nameKitchn = const Name.pure(),
    this.address = const Name.pure(),
    this.bio = const Name.pure(),
    this.status = FormzStatus.pure,
    this.statusApi = FormzStatus.pure,
    this.serverMessage = '',
    this.noOfSeats = const Phone.pure(),
    this.pathFiles = const [],
    this.days = const [],
    this.daysTiming = const [],
    this.daysTimingOriginal = const [],
    this.dineIn = true,
    this.takeAway = true,
    this.dineInSlots = const [],
    this.selectedPage = 0,
  });

  final Name? nameKitchn;
  final Name? address;
  final Name bio;
  final InternationalPhone phone;
  final String countryCode;
  final Phone noOfSeats;
  final FormzStatus? status;
  final FormzStatus? statusApi;
  final String? serverMessage;
  final List<String> pathFiles;
  final List<String>? days;
  final List<Days> daysTiming;
  final List<Days> daysTimingOriginal;
  final bool dineIn;
  final bool takeAway;
  final List<DineInSlotTemplate> dineInSlots;

  final int? selectedPage;

  CookProfileState copyWith({
    int? selectedPage,
    List<Days>? daysTiming,
    List<Days>? daysTimingOriginal,
    List<String>? days,
    bool? dineIn,
    bool? takeAway,
    List<DineInSlotTemplate>? dineInSlots,
    FormzStatus? status,
    List<String>? pathFiles,
    FormzStatus? statusApi,
    Name? nameKitchn,
    Name? address,
    Name? bio,
    Phone? noOfSeats,
    String? serverMessage,
    InternationalPhone? phone,
    String? countryCode,
  }) {
    return CookProfileState(
      daysTimingOriginal: daysTimingOriginal ?? this.daysTimingOriginal,
      selectedPage: selectedPage ?? this.selectedPage,
      daysTiming: daysTiming ?? this.daysTiming,
      dineIn: dineIn ?? this.dineIn,
      takeAway: takeAway ?? this.takeAway,
      dineInSlots: dineInSlots ?? this.dineInSlots,
      pathFiles: pathFiles ?? this.pathFiles,
      statusApi: statusApi ?? this.statusApi,
      status: status ?? this.status,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      nameKitchn: nameKitchn ?? this.nameKitchn,
      noOfSeats: noOfSeats ?? this.noOfSeats,
      serverMessage: serverMessage ?? this.serverMessage,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props => [
    selectedPage,
    daysTimingOriginal,
    daysTiming,
    dineIn,
    takeAway,
    dineInSlots,
    pathFiles,
    noOfSeats,
    statusApi,
    address,
    bio,
    status,
    nameKitchn,
    phone,
    countryCode,
    serverMessage,
  ];
}
