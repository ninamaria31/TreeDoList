import 'package:flutter/material.dart';

import '../auth.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to the settings screen or show a settings dialog
        // You can use Navigator to push a new screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Auth().signOut();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
