class TimingModel {
  List<Days>? days;

  TimingModel({this.days});

  TimingModel.fromJson(Map<String, dynamic> json) {
    if (json['days'] != null) {
      days = <Days>[];
      json['days'].forEach((v) {
        days!.add(new Days.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.days != null) {
      data['days'] = this.days!.map((v) => v.toJson()).toList();
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
        json['timing'] != null ? new Timing.fromJson(json['timing']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['day'] = this.day;
    data['isOn'] = this.isOn;
    if (this.timing != null) {
      data['timing'] = this.timing!.toJson();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    return data;
  }
}
