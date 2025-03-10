import 'package:alarm/alarm.dart';

class Alarm {
  int id;
  AlarmSettings settings;
  int folderId;
  String folderName;

  Alarm(
    this.id,
    this.settings,
    this.folderId,
    this.folderName
  );
}
