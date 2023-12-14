import 'package:flutter/material.dart';
import 'tree/tree_view.dart';
import 'tree/tree_overview.dart';
import 'tree/tree.dart';
import 'settings/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FutureBuilder<Tree>(
      future: loadExampleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return TreeTestApp(todoTree: snapshot.data ?? Tree());//TreeViewApp(tree: snapshot.data ?? Tree());
        } else {
          return const CircularProgressIndicator();
        }
      },
    ),
  );
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
              // add leading button
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
  Tree todoTree;
  TreeTestApp({super.key, required this.todoTree});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('TreeView Test'),
      ),
      body: TreeView(todoTree: todoTree),
    ));
  }
}
