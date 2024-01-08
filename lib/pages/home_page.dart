import 'package:flutter/material.dart';
import '../settings/settings.dart';
import '../tree/tree.dart';
import '../tree/tree_overview.dart';
import '../tree/tree_view.dart';

class TreePage extends StatelessWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tree>(
      future: loadExampleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return TreeTestApp(todoTree: snapshot.data ?? Tree());
        } else {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
      },
    );
  }
}

class TreeViewApp extends StatelessWidget {
  final Tree todoTree;

  const TreeViewApp({super.key, required this.todoTree});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TreeDoList',
        home: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: const Text('TreeDoList'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ),
            ),
            body: Center(child: TreeOverviewWidget(tree: todoTree))));
  }
}

class TreeTestApp extends StatelessWidget {
  final Tree todoTree;

  const TreeTestApp({super.key, required this.todoTree});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('TreeView Test'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ),
      ),
      body: TreeView(todoTree: todoTree),
    ));
  }
}
