import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_view.dart';
import '../auth.dart';
import '../services/nose_mode_service.dart';

// global variable for storing the duration of the nose mode
int noseModeDuration = 15;


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
          SizedBox(height: 60), // adds a padding between the appbar and the content
          Column(
            children: [
              Text(
                'Nose Mode Duration: $noseModeDuration minutes',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: noseModeDuration.toDouble(),
                min: 0,
                max: 120,
                divisions: 24,
                label: noseModeDuration.round().toString(),
                onChanged: timerService.isRunning.value ? null : (double value) {
                  setState(() {
                    noseModeDuration = value.toInt();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Email: ${Auth().currentUser?.email}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
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

