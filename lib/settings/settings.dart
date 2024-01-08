import 'dart:async';
import 'package:flutter/material.dart';
import '../auth.dart';
import '../services/nose_mode_service.dart';

// global variable for storing the duration of the nose mode
double noseModeDuration = 15.0;
double noseModeCountdown = 15.0;
TimerService _timerService = TimerService();

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to the settings screen or show a settings dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 20), // adds a padding between the appbar and the content
          Column(
            children: [
              Text(
                'Nose Mode Duration: ${noseModeDuration.toInt()} minutes',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: noseModeDuration,
                min: 0,
                max: 120,
                divisions: 24,
                label: noseModeDuration.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    noseModeDuration = value;
                    noseModeCountdown = value;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
          Switch(
            value: _timerService.isRunning(),
            onChanged: (value) {
              setState(() {
                if (value) {
                  _timerService.startTimer((int tick) {
                    print('Timer ticked! Count: $tick');
                    //noseModeCountdown = noseModeDuration - tick;
                    setState(() => noseModeCountdown = noseModeDuration - tick); // todo here is an issue with the screen not being mounted
                    if (tick == noseModeDuration.toInt()) { // todo add " * 60 "
                      _timerService.stopTimer();
                      setState(() => noseModeCountdown = noseModeDuration);
                    }
                  });
                } else {
                  _timerService.stopTimer();
                  noseModeCountdown = noseModeDuration;
                }
              });
            },
          ),
          Text(
            _timerService.isRunning() ? 'Nose Mode Timer: ${noseModeCountdown.toInt()} minutes remaining' : 'Nose Mode Off',
            style: TextStyle(fontSize: 18),
          ),
          //ElevatedButton(
          //  child:  !_noseModeActive ? Text("Start Nose Mode"): Text("Stop Nose Mode"),
          //  //    style: TextStyle(fontSize: 14)
          //
          //  onPressed: () {
          //    setState(() => _noseModeActive = !_noseModeActive);
          //    _startTimer();
          //  },
          //),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await Auth().signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Sign Out'),
          ),
          // Add more widgets as needed
        ],
      ),
    );
  }
}

