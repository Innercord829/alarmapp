import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:mdi/mdi.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String timeOfDay = "am";
  int? hourValue;
  DateTime alarmTime = DateTime.now();
  int alarmId = 1000;
  bool vibrate = true;
  List<Map<String, dynamic>> repeatIds = [];
  AlarmSettings? alarmSettingsTest;
  Map<String, dynamic>? alarmSettingsToSave;
  Map<String, dynamic>? alarmSettingsToSavePreChange = {};

  List<Map<String, dynamic>> _alarms = [];
  List<Map<String, dynamic>> _folders = [];
  List<bool> repeatAlarm = List.filled(7, false);

  Future<void> ensureJsonFileIsValid() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    if (await localFile.exists()) {
      // If the file doesn't exist, restore from assets
      String assetJson = await rootBundle.loadString('assets/data.json');
      await localFile.writeAsString(assetJson);
    }
  }

  Future<void> loadData() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    if (!await localFile.exists()) {
      String assetJson = await rootBundle.loadString('assets/data.json');
      await localFile.writeAsString(assetJson);
    }

    String jsonString = await localFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    print(jsonData);

    // var alarms = await Alarm.getAlarms();
    // print(alarms.length);
    // for (var alarm in alarms) {
    //   print(alarm);
    // }

    setState(() {
      _alarms = List<Map<String, dynamic>>.from(jsonData["alarms"]);
      _folders = List<Map<String, dynamic>>.from(jsonData["folders"]);
    });
  }

  Future<void> deleteAlarmById(int alarmId) async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    String jsonString = await localFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    for (var alarm in _alarms) {
      if (alarm.containsKey("repeatAlarmIds")) {
        List<Map<String, dynamic>> repeatAlarms =
            List<Map<String, dynamic>>.from(alarm["repeatAlarmIds"]);
        List<int> repeatIds =
            repeatAlarms.map((item) => item["id"] as int).toList();
        repeatIds.forEach((id) => cancelAlarmById(id));
      }
    }
    // Remove the alarm with the given ID
    jsonData["alarms"]
        .removeWhere((alarm) => alarm['settings']["id"] == alarmId);

    setState(() {
      _alarms.removeWhere((alarm) => alarm["settings"]["id"] == alarmId);
    });
    cancelAlarmById(alarmId);

    // Write back to file
    await localFile.writeAsString(jsonEncode(jsonData), flush: true);

    print("Alarm with ID $alarmId deleted successfully!");
  }

  void setRepeats(var alarmSettings) async {
    DateTime now = DateTime.now();

    int selectedWeekDay = alarmTime.weekday; // 1 = Monday, 7 = Sunday
    for (int i = 0; i < repeatAlarm.length; i++) {
      if (repeatAlarm[i]) {
        int daysToAdd = ((i + 1) - selectedWeekDay + 7) % 7;
        if (daysToAdd == 0 &&
            (alarmTime.hour < now.hour ||
                (alarmTime.hour == now.hour &&
                    alarmTime.minute <= now.minute))) {
          // If today is the target day but the time has passed, schedule for next week
          daysToAdd = 7;
        }
        setState(() {
          alarmId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          alarmTime = alarmTime.add(Duration(days: daysToAdd));
          repeatIds.add({"id": alarmId});
        });
        await Future.delayed(Duration(seconds: 1));
        setAlarm(alarmSettings);
      }
    }
    repeatAlarm = List.filled(7, false);
  }

  void updateTime(var selectedTime) {
    if (selectedTime != null) {
      final now = DateTime.now();
      if (selectedTime.isBefore(TimeOfDay.now())) {
        setState(() {
          alarmId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          alarmTime = DateTime(alarmTime.year, alarmTime.month,
              alarmTime.day + 1, selectedTime.hour, selectedTime.minute);
        });
      } else {
        setState(() {
          alarmId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          alarmTime = DateTime(now.year, now.month, now.day, selectedTime.hour,
              selectedTime.minute);
        });
      }
    }
  }

  // Add alarm inside "School" folder if it exists
  // for (var folder in jsonData["folders"]) {
  //   if (folder["name"] == "School") {
  //     folder["alarms"].add(newAlarm);
  //   }
  // }

  void writeToJson(String collection, String document, String document2,
      var value, var value2) async {
    // Get local file path
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    // Read JSON from the local file
    String jsonString = await localFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // New alarm to add
    Map<String, dynamic> newItem = {document: value, document2: value2};

    // Add alarm to the list
    jsonData[collection].add(newItem);

    if (document == "settings") {
      setState(() {
        _alarms.add(newItem);
      });
    }
    // print("Data: $jsonData");
    // Write updated JSON back to the local file
    await localFile.writeAsString(jsonEncode(jsonData), flush: true);
  }

  //Set a single alarm
  void setAlarm(var alarmSettings) async {
    try {
      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      print("Error setting alarm: $e");
    }
  }

  void cancelAlarms() async {
    print("alarms canceled");
    // deleteAlarmById(52);
    await Alarm.stopAll();
  }

  void updateSaveData() {
    setState(() {
      alarmSettingsToSavePreChange = alarmSettingsToSave;
    });
  }

  void cancelAlarmById(int id) async {
    await Alarm.stop(id);
  }

  //Gets alarms that are not inside a folder
  Future<List<Map>> readJsonFile(String document) async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');
    // Check if the file exists locally
    if (!await localFile.exists()) {
      // If not, copy it from assets
      String assetJson = await rootBundle.loadString('assets/data.json');
      await localFile.writeAsString(assetJson);
    }
    // Read JSON from the local file
    String jsonString = await localFile.readAsString();
    Map<dynamic, dynamic> jsonData = jsonDecode(jsonString);
    return List<Map>.from(jsonData[document]);
  }

  Future<List<Map>> findAlarmsById(int alarmId) async {
    List<Map> alarms = await readJsonFile("alarms");

    // Filter alarms by the given id
    List<Map> filteredAlarms = alarms.where((alarm) {
      return alarm["id"] == alarmId;
    }).toList();
    // print(filteredAlarms);
    return filteredAlarms;
  }

  @override
  void initState() {
    // TODO: implement initState
    ensureJsonFileIsValid();
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;

    return MaterialApp(
      home: Builder(builder: (context) {
        alarmSettingsTest = AlarmSettings(
          id: alarmId,
          dateTime: alarmTime,
          assetAudioPath: 'assets/alarm.mp3',
          loopAudio: true,
          vibrate: vibrate,
          volume: 0.2,
          fadeDuration: 3.0,
          androidFullScreenIntent: true,
          notificationSettings: const NotificationSettings(
            title: 'This is the title',
            body: 'This is the body',
            stopButton: 'Stop the alarm',
            // icon: 'notification_icon',
          ),
        );
        alarmSettingsToSave = {
          "id": alarmId,
          "dateTime": alarmTime.toString(),
          "assetAudioPath": 'assets/alarm.mp3',
          "loopAudio": true,
          "vibrate": vibrate,
          "volume": 0.2,
          "fadeDuration": 3.0,
          "androidFullScreenIntent": true,
          "notificationSettings": const NotificationSettings(
            title: 'This is the title',
            body: 'This is the body',
            stopButton: 'Stop the alarm',
            // icon: 'notification_icon',
          ),
        };

        return Scaffold(
          extendBody: true,
          //Main Button
          //Add Button
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: ExpandableFab(
            type: ExpandableFabType.up,
            childrenAnimation: ExpandableFabAnimation.none,
            distance: 70,
            pos: ExpandableFabPos.center,
            overlayStyle: ExpandableFabOverlayStyle(color: Colors.white54),
            children: [
              Row(
                children: [
                  const Text('Alarm'),
                  const SizedBox(width: 20),
                  FloatingActionButton.small(
                    onPressed: () async {
                      final TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        setState(() {
                          final now = DateTime.now();
                          alarmTime = DateTime(now.year, now.month, now.day,
                              selectedTime.hour, selectedTime.minute);
                          alarmId = DateTime.now()
                              .millisecondsSinceEpoch
                              .remainder(100000);
                          setAlarm(alarmSettingsTest);
                        });
                      }
                    },
                    child: const Icon(Icons.alarm_add),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Test Alarm'),
                  SizedBox(width: 20),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () => setAlarm(alarmSettingsTest),
                    child: Icon(Icons.folder),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Cancel Alarms'),
                  SizedBox(width: 20),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () => cancelAlarms(),
                    child: Icon(Icons.filter_alt_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Test Dialog'),
                  SizedBox(width: 20),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              child: SizedBox(
                                height: 300.0,
                                width: 300.0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    //Time Selection
                                    Row(
                                      children: [
                                        Text(
                                            style: TextStyle(fontSize: 18),
                                            "Select Time: "),
                                        IconButton(
                                            onPressed: () async {
                                              TimeOfDay? selectedTime =
                                                  await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.now(),
                                              );
                                              updateTime(selectedTime);
                                            },
                                            icon: Icon(Icons.alarm)),
                                      ],
                                    ),
                                    //Day Selection
                                    SizedBox(
                                      height: 100,
                                      width: 300,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  repeatAlarm[6] =
                                                      !repeatAlarm[6];
                                                });
                                                // repeatAlarm[6] =
                                                //     !repeatAlarm[6];
                                              },
                                              icon: repeatAlarm[6]
                                                  ? Icon(Mdi.alphaSCircle)
                                                  : Icon(Mdi
                                                      .alphaSCircleOutline)), //6 - Sunday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});
                                                repeatAlarm[0] =
                                                    !repeatAlarm[0];
                                              },
                                              icon: repeatAlarm[0]
                                                  ? Icon(Mdi.alphaMCircle)
                                                  : Icon(Mdi
                                                      .alphaMCircleOutline)), //0 Monday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});

                                                repeatAlarm[1] =
                                                    !repeatAlarm[1];
                                              },
                                              icon: repeatAlarm[1]
                                                  ? Icon(Mdi.alphaTCircle)
                                                  : Icon(Mdi
                                                      .alphaTCircleOutline)), //1 Tuesday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});

                                                repeatAlarm[2] =
                                                    !repeatAlarm[2];
                                              },
                                              icon: repeatAlarm[2]
                                                  ? Icon(Mdi.alphaWCircle)
                                                  : Icon(Mdi
                                                      .alphaWCircleOutline)), //2 Wednesday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});

                                                repeatAlarm[3] =
                                                    !repeatAlarm[3];
                                              },
                                              icon: repeatAlarm[3]
                                                  ? Icon(Mdi.alphaTCircle)
                                                  : Icon(Mdi
                                                      .alphaTCircleOutline)), //3 Thursday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});

                                                repeatAlarm[4] =
                                                    !repeatAlarm[4];
                                              },
                                              icon: repeatAlarm[4]
                                                  ? Icon(Mdi.alphaFCircle)
                                                  : Icon(Mdi
                                                      .alphaFCircleOutline)), //4 Friday
                                          IconButton(
                                              onPressed: () {
                                                setState(() {});
                                                repeatAlarm[5] =
                                                    !repeatAlarm[5];
                                              },
                                              icon: repeatAlarm[5]
                                                  ? Icon(Mdi.alphaSCircle)
                                                  : Icon(Mdi
                                                      .alphaSCircleOutline)), //5 Saturadye
                                        ],
                                      ),
                                    ),

                                    //Folder Selection
                                    DropdownMenu(
                                      enableFilter: true,
                                      requestFocusOnTap: true,
                                      leadingIcon: const Icon(Icons.search),
                                      label: const Text('Folders'),
                                      inputDecorationTheme:
                                          const InputDecorationTheme(
                                        filled: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 5.0),
                                      ),
                                      onSelected: (String? selectedFolder) {
                                        if (selectedFolder != null) {
                                          print("Folder $selectedFolder");

                                          //Place alarm in folder on select and not in the alarms within the json
                                        } else {
                                          print("No Folder Selected");
                                          //Place alarm in the alarms section of the json and set the alarm
                                        }
                                      },
                                      dropdownMenuEntries: _folders
                                          .map<DropdownMenuEntry<String>>(
                                              (folder) {
                                        return DropdownMenuEntry<String>(
                                          value: folder["folderName"],
                                          label: folder["folderName"],
                                        );
                                      }).toList(),
                                    ),

                                    //Buttons
                                    Row(
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              repeatAlarm =
                                                  List.filled(7, false);
                                              Navigator.pop(context);
                                            },
                                            child: Text("Cancel")),
                                        TextButton(
                                            onPressed: () async {
                                              if (repeatAlarm.contains(true)) {
                                                setAlarm(alarmSettingsTest);
                                                await Future.delayed(
                                                    Duration(seconds: 1));
                                                setRepeats(alarmSettingsTest);
                                                writeToJson(
                                                    "alarms",
                                                    "settings",
                                                    "repeatAlarmIds",
                                                    alarmSettingsToSavePreChange,
                                                    repeatIds);
                                              } else {
                                                setAlarm(alarmSettingsTest);
                                                writeToJson(
                                                    "alarms",
                                                    "settings",
                                                    "repeatAlarmIds",
                                                    alarmSettingsToSave,
                                                    repeatIds);
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: Text("Confirm"))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        }),
                    child: Icon(Icons.folder),
                  ),
                ],
              ),
            ],
          ),
          //Alarms
          body: Column(
            children: [
              SizedBox(
                height: height / 2,
                child: ListView.builder(
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      var alarmData = _alarms[index];
                      int id = alarmData["settings"]["id"];
                      // Convert string back to datetime object to get hour/minute values
                      DateTime datetime =
                          DateTime.parse(alarmData["settings"]["dateTime"]);
                      // if (datetime.hour > 12) {
                      //   timeOfDay = "pm";
                      //   hourValue = datetime.hour - 12;
                      // } else {
                      //   timeOfDay = "am";
                      //   hourValue = datetime.hour;
                      // }
                      return Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2)),
                        child: Column(
                          children: [
                            // Text("Test"),
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () => deleteAlarmById(id),
                                    icon: Icon(Icons.delete)),
                                Text(
                                    style: TextStyle(fontSize: 60),
                                    // "${hourValue}:${alarmTimes[index].minute} ${timeOfDay}"
                                    "${datetime.hour}:${datetime.minute} ${timeOfDay}"),
                              ],
                            ),
                            Row(
                              children: [
                                Text("$datetime"),
                                Spacer(),
                                Text("$id")
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
              ),
              //Alarms that arent in folder

              //Folders
              SizedBox(
                height: height / 2,
                child: ListView.builder(
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      var folder = _folders[index];
                      var alarmSettings = folder['settings'];
                      // print(alarmSettings["id"]);

                      //Convert string back to datetime object to get hour/minute values
                      DateTime datetime = new DateTime.now();
                      // DateTime.parse(alarmInFolder["datetime"]);
                      if (datetime.hour > 12) {
                        timeOfDay = "pm";
                        hourValue = datetime.hour - 12;
                      } else {
                        timeOfDay = "am";
                        hourValue = datetime.hour;
                      }
                      return Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2)),
                        child: Column(
                          children: [
                            Text(
                                style: TextStyle(fontSize: 60),
                                folder["folderName"]),
                            IconButton(
                              icon: Icon(Icons.abc),
                              onPressed: null,
                            ),
                          ],
                        ),
                      );
                    }),
              )
            ],
          ),
        );
      }),
    );
  }
}
