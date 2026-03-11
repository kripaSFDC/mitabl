class TimingModel {
  List<Days>? days;

  TimingModel({this.days});

  TimingModel.fromJson(Map<String, dynamic> json) {
    if (json['days'] != null) {
      days = <Days>[];
      json['days'].forEach((v) {
        days!.add(Days.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (days != null) {
      data['days'] = days!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Days {
  String? day;
  bool? isOn;
  Timing? timing;

  Days copyWith({
    String? day,
    bool? isOn,
    Timing? timing,
  }) {
    return Days(
        timing: timing ?? this.timing,
        isOn: isOn ?? this.isOn,
        day: day ?? this.day);
  }

  Days({this.day, this.isOn, this.timing});

  Days.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    isOn = json['isOn'];
    timing =
        json['timing'] != null ? Timing.fromJson(json['timing']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    data['isOn'] = isOn;
    if (timing != null) {
      data['timing'] = timing!.toJson();
    }
    return data;
  }
}

class Timing {
  String? startTime;
  String? endTime;

  Timing({this.startTime, this.endTime});

  Timing copyWith({String? startTime, String? endTime}) {
    return Timing(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime);
  }

  Timing.fromJson(Map<String, dynamic> json) {
    startTime = json['start_time'];
    endTime = json['end_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    return data;
  }
}
