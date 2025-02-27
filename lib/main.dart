import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

void main() {
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
    await Alarm.set(alarmSettings: alarmSettings);
  }

  void cancelAlarm(int id) async {
    List<AlarmSettings> alarms = await Alarm.getAlarms();
    alarms.forEach((alarm) {
      print(alarm.id);
    });
    if (alarms.length <= 0) {
      print("No Alarms");
    }
    await Alarm.stop(id);
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
      // warningNotificationOnKill: Platform.isIOS,
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
        //Main Button
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            verticalDirection: VerticalDirection.up,
            children: [
              FloatingActionButton(
                  shape: CircleBorder(),
                  backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
                  tooltip: 'Stuff',
                  onPressed: () {
                    setState(() {
                      toggled = !toggled;
                    });
                  },
                  child: Icon(Icons.add)),
              Visibility(
                visible: toggled,
                child: FloatingActionButton(
                    shape: CircleBorder(),
                    backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
                    tooltip: 'Stuff',
                    onPressed: () {
                      // toggled ? toggled : !toggled;
                    },
                    child: Icon(Icons.abc)),
              )
            ],
          ),
        ),

        //Maybe Temporary
        bottomNavigationBar: BottomAppBar(
          height: 60,
          color: const Color.fromRGBO(82, 170, 94, 1.0),
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.home, color: Colors.orange)),
              IconButton(
                  onPressed: null,
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.pink,
                  ))
            ],
          ),
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
