import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
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
  int id = Random().nextInt(100) + 1;

  List<Map<String, dynamic>> _alarms = [];

  Future<void> loadAlarms() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    if (!await localFile.exists()) {
      String assetJson = await rootBundle.loadString('assets/data.json');
      await localFile.writeAsString(assetJson);
    }

    String jsonString = await localFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    setState(() {
      _alarms = List<Map<String, dynamic>>.from(jsonData["alarms"]);
    });
  }

  Future<void> ensureJsonFileIsValid() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    if (!await localFile.exists()) {
      // If the file doesn't exist, restore from assets
      String assetJson = await rootBundle.loadString('assets/data.json');
      await localFile.writeAsString(assetJson);
    } else {
      // If file exists but is empty or corrupted, restore default structure
      String jsonString = await localFile.readAsString();
      if (jsonString.trim().isEmpty) {
        Map<String, dynamic> defaultJson = {
          "alarms": [],
          "folders": [],
        };
        await localFile.writeAsString(jsonEncode(defaultJson));
      }
    }
  }

  Future<void> deleteAlarmById(int alarmId) async {
    final directory = await getApplicationDocumentsDirectory();
    final localFile = File('${directory.path}/data.json');

    String jsonString = await localFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // Remove the alarm with the given ID
    jsonData["alarms"]
        .removeWhere((alarm) => alarm['settings']["id"] == alarmId);

    setState(() {
      _alarms.removeWhere((alarm) => alarm["settings"]["id"] == alarmId);
    });
    // Write back to file
    await localFile.writeAsString(jsonEncode(jsonData), flush: true);

    print("Alarm with ID $alarmId deleted successfully!");
  }

  void setAlarmTest(final alarmSettings, var alarmSettingsToSave) async {
    // await readAlarmData(file);
    try {
      // Get local file path
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
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // New alarm to add
      Map<String, dynamic> newAlarm = {"settings": alarmSettingsToSave};
      // Add alarm to the list
      jsonData["alarms"].add(newAlarm);

      // Add alarm inside "School" folder if it exists
      // for (var folder in jsonData["folders"]) {
      //   if (folder["name"] == "School") {
      //     folder["alarms"].add(newAlarm);
      //   }
      // }

      // Write updated JSON back to the local file
      await localFile.writeAsString(jsonEncode(jsonData), flush: true);
      setState(() {
        _alarms.add(newAlarm);
      });
      print("New alarm added successfully!");
    } catch (e) {
      print("Error modifying JSON: $e");
    }

    await Alarm.set(alarmSettings: alarmSettings);
  }

  void setAlarm(final alarmSettings) async {
    await Alarm.set(alarmSettings: alarmSettings);
  }

  void cancelAlarms() async {
    print("alarms canceled");

    await Alarm.stopAll();
  }

  //Gets alarms that are not inside a folder
  Future<List<Map>> readJsonFile() async {
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
    return List<Map>.from(jsonData['alarms']);
  }

  Future<List<Map>> findAlarmsById(int alarmId) async {
    List<Map> alarms = await readJsonFile();

    // Filter alarms by the given id
    List<Map> filteredAlarms = alarms.where((alarm) {
      return alarm["id"] == alarmId;
    }).toList();
    // print(filteredAlarms);
    return filteredAlarms;
  }

  Future<List<Map>> readJsonFileFolders() async {
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
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    return List<Map>.from(jsonData['folders']);
  }

  @override
  void initState() {
    // TODO: implement initState
    // ensureJsonFileIsValid();
    loadAlarms();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alarmSettingsTest = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
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
    Map<String, dynamic> alarmSettingsToSave = {
      "id": id,
      "dateTime": alarmTime.toString(),
      "assetAudioPath": 'assets/alarm.mp3',
      "loopAudio": true,
      "vibrate": true,
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

    double height = MediaQuery.sizeOf(context).height;

    return MaterialApp(
      home: Builder(builder: (context) {
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
                          id = Random().nextInt(100) + 1;
                          final now = DateTime.now();
                          alarmTime = DateTime(now.year, now.month, now.day,
                              selectedTime.hour, selectedTime.minute);
                          setAlarmTest(alarmSettingsTest, alarmSettingsToSave);
                        });
                      }
                      // setAlarmTest(alarmSettingsTest);
                    },
                    child: const Icon(Icons.alarm),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Test Alarm'),
                  SizedBox(width: 20),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () =>
                        setAlarmTest(alarmSettingsTest, alarmSettingsToSave),
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
            ],
          ),

          body: Column(
            children: [
              //Alarms that arent in folder
              FutureBuilder<List<Map>>(
                future: readJsonFile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available'));
                  } else {
                    //Get data from data.json - Alarms
                    var data = snapshot.data!;
                    // findAlarmsById(63);
                    print(data);
                    //Display for each alarm
                    return SizedBox(
                      height: height / 2,
                      child: ListView.builder(
                          itemCount: _alarms.length,
                          itemBuilder: (context, index) {
                            var alarmData = _alarms[index];
                            int id = alarmData["settings"]["id"];
                            // print(alarmData["settings"]["dateTime"]);
                            // Convert string back to datetime object to get hour/minute values
                            DateTime datetime = DateTime.parse(
                                alarmData["settings"]["dateTime"]);
                            if (datetime.hour > 12) {
                              timeOfDay = "pm";
                              hourValue = datetime.hour - 12;
                            } else {
                              timeOfDay = "am";
                              hourValue = datetime.hour;
                            }
                            return Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 2)),
                              child: Column(
                                children: [
                                  // Text("Test"),
                                  IconButton(
                                      onPressed: () => deleteAlarmById(id),
                                      icon: Icon(Icons.delete)),
                                  Text(
                                      style: TextStyle(fontSize: 60),
                                      // "${hourValue}:${alarmTimes[index].minute} ${timeOfDay}"
                                      "${hourValue}:${datetime.minute} ${timeOfDay}"),
                                  Text(
                                      // "${alarmTimes[index].weekday}"
                                      "${datetime.weekday}"),
                                ],
                              ),
                            );
                          }),
                    );
                  }
                },
              ),
              //Folders
              FutureBuilder<List<Map>>(
                future: readJsonFileFolders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available'));
                  } else {
                    var data = snapshot.data!;
                    //Display for each Folder
                    return SizedBox(
                      height: height / 2,
                      child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            var folder = data[index];
                            var alarmsListInFolder =
                                List<Map>.from(folder['alarms']);
                            var alarmInFolder = alarmsListInFolder[index];
                            //Convert string back to datetime object to get hour/minute values
                            DateTime datetime =
                                DateTime.parse(alarmInFolder["datetime"]);
                            if (datetime.hour > 12) {
                              timeOfDay = "pm";
                              hourValue = datetime.hour - 12;
                            } else {
                              timeOfDay = "am";
                              hourValue = datetime.hour;
                            }
                            return Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 2)),
                              child: Column(
                                children: [
                                  Text(
                                      style: TextStyle(fontSize: 60),
                                      folder["name"]),
                                  IconButton(
                                    icon: Icon(Icons.abc),
                                    onPressed: null,
                                  ),
                                ],
                              ),
                            );
                          }),
                    );
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
