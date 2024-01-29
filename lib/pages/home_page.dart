import 'package:flutter/material.dart';
import '../services/flask_server.dart';
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
      future: getTreeFromDB(), // sends http request to server
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

  final PageStorageBucket bucket = PageStorageBucket();

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
                ? PageStorage(bucket: bucket, child: treeView)
                : treeOverview,
          );
        },
      ),
    );
  }
}
