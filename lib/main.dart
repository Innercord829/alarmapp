import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

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
  List<DateTime> alarmTimes = [];
  // List<int> alarmIds = [];
  String timeOfDay = "am";
  int? hourValue;

  late Future<List<Map>> jsonData;

  DateTime alarmTime = DateTime.now();
  int id = Random().nextInt(100) + 1;

  void setAlarmTest(final alarmSettings) async {
    print("Alarm Set");
    //test
    // await Alarm.checkAlarm();
    await Alarm.set(alarmSettings: alarmSettings);
  }

  void setAlarm(final alarmSettings) async {
    print("Alarm Set");

    await Alarm.set(alarmSettings: alarmSettings);
  }

  void cancelAlarms() async {
    print("alarms canceled");
    setState(() {
      alarmTimes.clear();
    });
    await Alarm.stopAll();
  }

  Future<List<Map>> readJsonFile(String assetPath) async {
    var input = await rootBundle.loadString(assetPath);
    var map = jsonDecode(input);
    
    return List<Map>.from(map['alarms']);
  }

  @override
  void initState() {
    // TODO: implement initState
    // jsonData = readJsonFile("assets/data.json");

    
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
                          setAlarm(alarmSettingsTest);
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
                    onPressed: () => setAlarmTest(alarmSettingsTest),
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

          body: FutureBuilder<List<Map>>(
            future: readJsonFile("assets/data.json"),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data available'));
              } else {
                //readJsonFile has to return List<Map>.from(map['alarms']);
                //Get data from data.json - Alarms
                var data = snapshot.data!;
                var item = data[0]; //data[index];
                // print(item["id"]);

                //readJsonFile has to return List<Map>.from(map['folders']);
                //Get data from data.json - Folders - Alarms
                // var data = snapshot.data!;
                // var item = data[0]; //data[index];
                // item["alarms"];
                // var alarmsList = List<Map>.from(item["alarms"]);
                // var alarmItem = alarmsList[0];
                // print(alarmItem["id"]);

                // return Placeholder();
                return Center(
                    child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          var item = data[index];
                          //Convert string back to datetime object to get hour/minute values
                          DateTime datetime = DateTime.parse(item["datetime"]);
                          if (datetime.hour > 12) {
                            timeOfDay = "pm";
                            hourValue = datetime.hour - 12;
                          } else {
                            timeOfDay = "am";
                            hourValue = datetime.hour;
                          }
                          return Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 2)),
                            child: Column(
                              children: [
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
                        }));
              }
            },
          ),
        );
      }),
    );
  }
}
