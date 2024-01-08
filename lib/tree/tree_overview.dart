import 'package:flutter/material.dart';
import 'connection_layer.dart';
import 'tree.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../app_constants.dart';
import 'tree_vis_elements.dart';
import 'package:intl/intl.dart';

Future<Tree> loadExampleJson() async {
  try {
    String jsonString =
        await rootBundle.loadString('assets/example_complex_tree.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);
    return Tree.jsonConstructor(jsonData['root']);
  } catch (e) {
    print('Error loading/parsing JSON: $e');
    return Tree();
  }
}

class TreeOverviewWidget extends StatelessWidget {
  final Tree tree;
  final TransformationController _controller = TransformationController();

  TreeOverviewWidget({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    _controller.value = Matrix4.identity()..scale(0.5);

    return InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        maxScale: 10.0,
        transformationController: _controller,
        child: _buildTree(tree.root, context));
  }

  Widget _buildTree(TreeNode currentNode, BuildContext context) {
    return Container(
      // THIS SLIGHTLY INCREASES THE CONTAINER HEIGHT!
      //decoration: BoxDecoration(
      //  border: Border.all(
      //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
      //  borderRadius: BorderRadius.circular(8),
      //),
      child: Row(
        // center vertically
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NodeWidget(
            node: currentNode,
            onTapCallback: _showDetails,
          ),
          if (currentNode.numberOfChildren > 0) ...[
            SizedBox(
              width: AppConstants.canvasWidth,
              height: AppConstants.subTreeHeight(currentNode.leafsInSubTree),
              child: CustomPaint(
                painter: RegularConnectionLayerPainter.fromNode(currentNode),
              ),
            ),
            Column(
              // center vertically
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: currentNode.children
                  .map((child) => _buildTree(child, context))
                  .toList(),
            )
          ]
        ],
      ),
    );
  }

  void _showDetails(TreeNode node, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            node.name,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (node.description != null) ...[
                Text(
                  'Description:',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  node.description!,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
              ],
              Text(
                'Due Date:',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                node.dueDate != null
                    ? DateFormat('dd/MM/yy').format(node.dueDate!)
                    : 'No Due Date',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
