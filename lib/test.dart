import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.lightGreen,
        ),
      debugShowCheckedModeBanner: false, // remove debug banner
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Your App Title'),
        ),
        body: YourMainScreenContent(),
        floatingActionButton: SettingsButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat
      ),
    );
  }
}

class YourMainScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Your main screen content goes here
    return Container(
      // Your main screen content
    );
  }
}

class SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to the settings screen or show a settings dialog
        // You can use Navigator to push a new screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('Your settings screen content goes here.'),
      ),
    );
  }
}
