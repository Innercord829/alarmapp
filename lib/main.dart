import 'dart:math';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
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
  List<int> alarmIds = [];
  String timeOfDay = "am";
  int? hourValue;

  DateTime alarmTime = DateTime.now();
  int id = Random().nextInt(100) + 1;

  void getAlarms() async {
    List<AlarmSettings> alarms = await Alarm.getAlarms();
    for (var alarm in alarms) {
      setState(() {
        alarmTimes.add(alarm.dateTime);
        alarmIds.add(alarm.id);
      });
    }
    // print(alarmTimes[0]);
  }

  void setAlarmTest(final alarmSettings) async {
    print("Alarm Set");
    //test
    // await Alarm.checkAlarm();
    await Alarm.set(alarmSettings: alarmSettings);
    getAlarms();
  }

  void setAlarm(final alarmSettings) async {
    print("Alarm Set");

    await Alarm.set(alarmSettings: alarmSettings);
    getAlarms();
  }

  void cancelAlarms() async {
    print("alarms canceld");
    setState(() {
      alarmTimes.clear();
    });
    await Alarm.stopAll();
  }

  @override
  void initState() {
    // TODO: implement initState

    getAlarms();
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
                          alarmTime = new DateTime(now.year, now.month, now.day,
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

          body: Center(
              child: ListView.builder(
                  itemCount: alarmTimes.length,
                  itemBuilder: (context, index) {
                    if (alarmTimes[index].hour > 12) {
                      timeOfDay = "pm";
                      hourValue = alarmTimes[index].hour - 12;
                    } else {
                      timeOfDay = "am";
                      hourValue = alarmTimes[index].hour;
                    }
                    return Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2)),
                      child: Column(
                        children: [
                          Text(
                              style: TextStyle(fontSize: 60),
                              "${hourValue}:${alarmTimes[index].minute} ${timeOfDay}"),
                          Text("${alarmTimes[index].weekday}")
                        ],
                      ),
                    );
                    // Text("${alarmTimes[index].hour}:${alarmTimes[index].second} ${timeOfDay}");
                  })),
        );
      }),
    );
  }
}
