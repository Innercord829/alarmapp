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
  void setAlarmTest(final alarmSettings) async {
    print("Alarm Set");
    //test
    await Alarm.checkAlarm();
    await Alarm.set(alarmSettings: alarmSettings);
  }

  void cancelAlarm(int id) async {
    List<AlarmSettings> alarms = await Alarm.getAlarms();
    for (var alarm in alarms) {
      print(alarm.id);
    }
    if (alarms.isEmpty) {
      print("No Alarms");
    } else {
      print("alarms exist");
    }
    await Alarm.stopAll();
  }

  bool toggled = false;

  @override
  Widget build(BuildContext context) {
    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: DateTime.now().add(const Duration(seconds: 15)),
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
      home: Scaffold(
        extendBody: true,
        //Main Button
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          type: ExpandableFabType.up,
          childrenAnimation: ExpandableFabAnimation.none,
          distance: 70,
          pos: ExpandableFabPos.center,
          overlayStyle: ExpandableFabOverlayStyle(color: Colors.white54),
          children: const [
            Row(
              children: [
                Text('Alarm'),
                SizedBox(width: 20),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: null,
                  child: Icon(Icons.alarm),
                ),
              ],
            ),
            Row(
              children: [
                Text('Folder'),
                SizedBox(width: 20),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: null,
                  child: Icon(Icons.folder),
                ),
              ],
            ),
            Row(
              children: [
                Text('Filter'),
                SizedBox(width: 20),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: null,
                  child: Icon(Icons.filter_alt_rounded),
                ),
              ],
            ),
          ],
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    setAlarmTest(alarmSettings);
                  },
                  child: Text("Set Alarm")),
              TextButton(
                  onPressed: () {
                    cancelAlarm(42);
                  },
                  child: Text("Cancel Alarm")),
            ],
          ),
        ),
      ),
    );
  }
}
