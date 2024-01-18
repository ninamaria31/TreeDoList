import 'package:flutter/material.dart';
import '../settings/settings.dart';
import '../tree/tree.dart';
import '../tree/tree_overview.dart';
import '../tree/tree_view_regular.dart';
import 'package:flutter/services.dart';

class TreePage extends StatelessWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []); // Hide status bar

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

class TreeTestApp extends StatefulWidget {
  final Tree todoTree;

  const TreeTestApp({super.key, required this.todoTree});

  @override
  _TreeTestAppState createState() => _TreeTestAppState();
}

class _TreeTestAppState extends State<TreeTestApp> {
  late TreeViewRegular treeView;
  late TreeOverview treeOverview;

  @override
  void initState() {
    super.initState();
    treeView =
        TreeViewRegular(key: PageStorageKey('treeView'), todoTree: widget.todoTree);
    treeOverview =
        TreeOverview(key: PageStorageKey('treeOverview'), todoTree: widget.todoTree);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
            appBar: orientation == Orientation.portrait
                ? AppBar(
                    title: const Text('TreeView Test'),
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsScreen()),
                          );
                        },
                      ),
                    ),
                  )
                : null, // No AppBar in landscape orientation
            body: orientation == Orientation.portrait
                ? treeView
                : treeOverview,
          );
        },
      ),
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
                          builder: (context) => SettingsScreen()),
                    );
                  },
                ),
              ),
            ),
            body: OrientationBuilder(
              builder: (context, orientation) {
                return orientation == Orientation.portrait
                    ? TreeOverview(todoTree: todoTree)
                    : TreeLandscape(todoTree: todoTree);
              },
            )));
  }
}

class TreeLandscape extends StatelessWidget {
  final Tree todoTree;

  const TreeLandscape({super.key, required this.todoTree});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Landscape view for tree: ${todoTree.root.name}'),
    );
  }
}
