import 'package:flutter/material.dart';
import 'tree.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TreeVisualizer extends StatelessWidget {
  final Tree tree;

  TreeVisualizer({required this.tree});

  Widget _buildTree(TreeNode node) {
    return Container(
      padding: EdgeInsets.only(left: 32, right: 32, top: 4, bottom: 4),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.lightBlueAccent, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold))
            ),
          ),
          if (node.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children.map((child) => _buildTree(child)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Text(node.name, style: TextStyle(fontWeight: FontWeight.bold)),
  // if (node.children.isNotEmpty)
  //   Padding(
  //     padding: const EdgeInsets.only(left: 16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: node.children.map((child) => _buildTree(child)).toList(),
  //     ),
  //   ),

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tree Visualization'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTree(tree.root),
      ),
    );
  }
}

Future<Tree> loadExampleJson() async {
  // try {
    WidgetsFlutterBinding.ensureInitialized();
    String jsonString = await rootBundle.loadString('assets/example_tree.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);
    return Tree.jsonConstructor(jsonData['root']);
  // } catch (e) {
  //   print('Error loading/parsing JSON: $e');
  //   return Tree();
  // }
}
