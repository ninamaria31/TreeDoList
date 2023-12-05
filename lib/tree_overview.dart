import 'package:flutter/material.dart';
import 'tree.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'app_constants.dart';

// class TreeVisualizer extends StatelessWidget {
//   final Tree tree;
//
//   TreeVisualizer({required this.tree});
//
//   Widget _buildTree(TreeNode node) {
//     return Container(
//       padding: EdgeInsets.only(left: 32, right: 32, top: 4, bottom: 4),
//       margin: EdgeInsets.symmetric(vertical: 4.0),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.lightBlueAccent, width: 2.0),
//         borderRadius: BorderRadius.circular(8.0),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.black, width: 2.0),
//               borderRadius: BorderRadius.circular(8.0),
//             ),
//             child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(node.name,
//                     style: const TextStyle(fontWeight: FontWeight.bold))),
//           ),
//           if (node.children.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children:
//                     node.children.map((child) => _buildTree(child)).toList(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Text(node.name, style: TextStyle(fontWeight: FontWeight.bold)),
//   // if (node.children.isNotEmpty)
//   //   Padding(
//   //     padding: const EdgeInsets.only(left: 16.0),
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: node.children.map((child) => _buildTree(child)).toList(),
//   //     ),
//   //   ),
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Tree Visualization'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: _buildTree(tree.root),
//       ),
//     );
//   }
// }

Future<Tree> loadExampleJson() async {
  // try {
  WidgetsFlutterBinding.ensureInitialized();
  String jsonString =
      await rootBundle.loadString('assets/example_complex_tree.json');
  Map<String, dynamic> jsonData = json.decode(jsonString);
  return Tree.jsonConstructor(jsonData['root']);
  // } catch (e) {
  //   print('Error loading/parsing JSON: $e');
  //   return Tree();
  // }
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
              name: currentNode.name),
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
    int numberOfNodes = node.numberChildren;
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
  final String name;

  const NodeWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppConstants.nodeFontSize,
                      color: Colors.black,
                      decoration: TextDecoration.none),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            )));
  }
}
