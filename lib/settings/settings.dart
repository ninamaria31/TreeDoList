import 'package:flutter/material.dart';

import '../auth.dart';

// global variable for storing the duration of the nose mode
double noseModeDuration = 15.0;

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to the settings screen or show a settings dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  //double _duration = 15.0; // Initial duration value in minutes

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
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
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
