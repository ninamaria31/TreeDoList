import 'package:flutter/material.dart';
import 'tree.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../app_constants.dart';

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

  const TreeOverviewWidget({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      minScale: 0.1,
      maxScale: 10.0,
      child: _buildTree(tree.root)
    );
  }

  Widget _buildTree(TreeNode currentNode) {
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
              node: currentNode
          ),
          if (currentNode.numberChildren > 0) ...[
            SizedBox(
              width: AppConstants.canvasWidth,
              height: AppConstants.subTreeHeight(currentNode.leafsInSubTree),
              child: CustomPaint(
                painter: ConnectionLayerPainter(currentNode),
              ),
            ),
            Column(
              // center vertically
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: currentNode.children
                  .map((child) => _buildTree(child))
                  .toList(),
            )
          ]
        ],
      ),
    );
  }
}

class ConnectionLayerPainter extends CustomPainter {
  final TreeNode node;

  ConnectionLayerPainter(this.node);

  @override
  void paint(Canvas canvas, Size size) {
    double canvasHeight = AppConstants.subTreeHeight(node.leafsInSubTree);


    double bezierStartHeight = canvasHeight / 2;
    double cumulativeHeight = 0;
    double tmp = 0;
    List<double> bezierEndsHeights = [];

    Path curve = Path();
    Offset endControl;
    Offset startControl;

    for (var child in node.children) {
      tmp = AppConstants.subTreeHeight(child.leafsInSubTree) / 2;
      cumulativeHeight += tmp;
      bezierEndsHeights.add(cumulativeHeight);
      cumulativeHeight += tmp;
    }
    
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = AppConstants.connectionLineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;


    for (var endPoint in bezierEndsHeights) {
      endControl = Offset(AppConstants.canvasWidth / 2, bezierStartHeight);
      startControl = Offset(AppConstants.canvasWidth / 2, endPoint);
      curve.moveTo(0, bezierStartHeight);
      curve.cubicTo(endControl.dx, endControl.dy, startControl.dx, startControl.dy, AppConstants.canvasWidth, endPoint);
      canvas.drawPath(curve, paint);
      //canvas.drawLine(Offset(0, bezierStartHeight),
      //    Offset(AppConstants.canvasWidth, endPoint), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// widget used to draw a node
class NodeWidget extends StatelessWidget {
  final TreeNode node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context, node),
      child: Padding(
          padding: const EdgeInsets.only(
              top: AppConstants.verticalNodePadding,
              bottom: AppConstants.verticalNodePadding),
          child: Container(
              height: AppConstants.nodeHeight,
              width: AppConstants.nodeWidth,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black, width: AppConstants.nodeLineWidth),
                borderRadius:
                    BorderRadius.circular(AppConstants.nodeBorderRadius),
              ),
              child: Center(
                child: Text(node.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppConstants.nodeFontSize,
                        color: Colors.black,
                        decoration: TextDecoration.none),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              )
    )
    ),
    );
  }

  void _showDetails(BuildContext context, TreeNode node) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(node.name),
            content: Text(node.description ?? 'No Description'),
          );
        }
    );
  }
}
