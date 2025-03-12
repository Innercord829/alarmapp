import 'package:alarm/alarm.dart';

class Alarm {
  late AlarmSettings? settings;

  Alarm(
    this.settings,
  );

  Alarm.fromJson(Map<String, dynamic> json) {
    settings = json['settings'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['settings'] = settings;
    return data;
  }
}
