import 'tree.dart';
import '../app_constants.dart';
import 'package:flutter/material.dart';

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
  /// Function called when the node is tapped.
  final void Function(TreeNode, BuildContext)? onTapCallback;

  const NodeWidget({super.key, required this.node, this.onTapCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTapCallback?.call(node, context),
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

}