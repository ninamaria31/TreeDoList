import 'package:flutter/material.dart';
import 'connection_layer.dart';
import 'tree.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../app_constants.dart';
import 'tree_vis_elements.dart';

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
            Container(
              //decoration: BoxDecoration(
              //  border: Border.all(
              //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
              //  borderRadius: BorderRadius.circular(8),
              //),
              width: AppConstants.canvasWidth,
              height: AppConstants.subTreeHeight(currentNode.leafsInSubTree),
              child: CustomPaint(
                painter: OverviewConnectionLayerPainter.fromNode(currentNode),
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

  //// TODO: create a sufficient details screen
  void _showDetails(TreeNode node, BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(node.name),
            content: Text(
                '${node.description ?? 'No Description'} due on ${node.dueDate?.toString()}'),
          );
        });
  }
}
