import 'package:flutter/material.dart';
import 'tree.dart';

class Constants {
  static const double inter_node_distance = 10.0;
}

class TreeView extends StatefulWidget {
  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  Tree todoTree = Tree();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; i++) {
      String name = 'A$i';
      todoTree.addChildToNode(todoTree.root.id, TreeNode(name, Priority.low));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TreeView Test'),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _scrollController.animateTo
              (_scrollController.offset + (details.primaryDelta ?? 0),
                duration: const Duration(microseconds: 100),
                curve: Curves.linear);
          });
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: Container(
            width: 200,
            child: Column(
              children: drawLevel(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget>  drawLevel() {
    List<Widget> nodes = [];

    for (TreeNode node in todoTree.getLevel(1)) {
      nodes.add(
        Container(
          width: 80.0,
          height: 80.0,
          margin: const EdgeInsets.all(10.0),
          color: Colors.blue,
          child: Center(
            child: Text(
              node.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    return nodes;
  }
}