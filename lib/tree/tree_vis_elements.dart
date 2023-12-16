import 'dart:math';

import 'tree.dart';
import '../app_constants.dart';
import 'package:flutter/material.dart';

class ConnectionLayerPainter extends CustomPainter {
  late TreeNode node;
  final double bezierStart;
  late final List<double> bezierEnds;

  ConnectionLayerPainter(this.bezierStart, this.bezierEnds);

  ConnectionLayerPainter.fromNode(this.node)
      : bezierStart = AppConstants.subTreeHeight(node.leafsInSubTree) / 2,
        bezierEnds = yPositionOfChildren(node);

  @override
  void paint(Canvas canvas, Size size) {
    Path curve = Path();
    Offset endControl;
    Offset startControl;

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = AppConstants.connectionLineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    for (var endPoint in bezierEnds) {
      endControl = Offset(AppConstants.canvasWidth / 2, bezierStart);
      startControl = Offset(AppConstants.canvasWidth / 2, endPoint);
      curve.moveTo(0, bezierStart);
      curve.cubicTo(endControl.dx, endControl.dy, startControl.dx,
          startControl.dy, AppConstants.canvasWidth, endPoint);
      canvas.drawPath(curve, paint);
      //canvas.drawLine(Offset(0, bezierStartHeight),
      //    Offset(AppConstants.canvasWidth, endPoint), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  /// generated a list of heights where the nodes are
  /// for drawing the whole tree. So it won't be evenly spaced
  static List<double> yPositionOfChildren(TreeNode n) {
    List<double> res = [];
    double cumulativeHeight = 0;
    double tmp = 0;
    for (var child in n.children) {
      tmp = AppConstants.subTreeHeight(child.leafsInSubTree) / 2;
      cumulativeHeight += tmp;
      res.add(cumulativeHeight);
      cumulativeHeight += tmp;
    }
    return res;
  }
}

/// widget used to draw a node
class NodeWidget extends StatelessWidget {
  final TreeNode node;
  final bool showLeafCount;

  /// Function called when the node is tapped.
  final void Function(TreeNode, BuildContext)? onTapCallback;
  final void Function(TreeNode, DragEndDetails)? onHorDragEndCallback;

  const NodeWidget(
      {super.key,
      required this.node,
      this.showLeafCount = false,
      this.onTapCallback,
      this.onHorDragEndCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTapCallback?.call(node, context),
      onHorizontalDragEnd: (details) =>
          onHorDragEndCallback?.call(node, details),
      child: (!showLeafCount)
          ? Padding(
              padding: const EdgeInsets.only(
                  top: AppConstants.verticalNodePadding,
                  bottom: AppConstants.verticalNodePadding),
              child: _buildNode())
          : Stack(children: [
              Padding(
                  padding: const EdgeInsets.only(
                      top: AppConstants.verticalNodePadding,
                      bottom: AppConstants.verticalNodePadding,
                      right: AppConstants.endPadding),
                  child: _buildNode()),
              if (node.numberOfChildren != 0)
              Positioned(
                right: AppConstants.endPadding - AppConstants.nodeBadeSize / 2,
                top: AppConstants.verticalNodePadding - AppConstants.nodeBadeSize / 2,
                width: AppConstants.nodeBadeSize,
                height: AppConstants.nodeBadeSize,
                child: Container(
                    decoration: BoxDecoration(
                        color: node.priority.color,
                        border: Border.all(
                            color: Colors.black,
                            width: AppConstants.nodeLineWidth),
                        borderRadius: BorderRadius.circular(AppConstants.nodeBadeSize / 2)),
                    child: Center(child: Text(node.leafsInSubTree.toString(), style: AppConstants.nodeTextStyle,))),
              )
            ]),
    );
  }

  Widget _buildNode() {
    return Container(
        height: AppConstants.nodeHeight,
        width: AppConstants.nodeWidth,
        decoration: BoxDecoration(
          color: node.priority.color,
          border: Border.all(
              color: Colors.black, width: AppConstants.nodeLineWidth),
          borderRadius: BorderRadius.circular(AppConstants.nodeBorderRadius),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              node.name,
              style: AppConstants.nodeTextStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ));
  }
}

/// Generates the heights where the bezier curves start end end
class BezierHeights {
  final double _leftCanvasHeight;
  final double _rightCanvasHeight;
  final int _numberOfChildrenLeft;
  final int _numberOfChildrenRight;

  late double height;
  late double _leftCanvasOffset;
  late double _rightCanvasOffset;

  BezierHeights(int numberOfNodesLeft, int numberOfNodesRight,
      {double? forceHeight})
      : _numberOfChildrenLeft = numberOfNodesLeft,
        _numberOfChildrenRight = numberOfNodesRight,
        _leftCanvasHeight = AppConstants.interNodeDistance * numberOfNodesLeft,
        _rightCanvasHeight =
            AppConstants.interNodeDistance * numberOfNodesRight {
    height = max(forceHeight ?? 0, max(_leftCanvasHeight, _rightCanvasHeight));
    _leftCanvasOffset = (_leftCanvasHeight - height).abs() / 2;
    _rightCanvasOffset = (_rightCanvasHeight - height).abs() / 2;
  }

  List<double> get leftBezierHeights {
    return _calcBezierHeights(_leftCanvasOffset, _numberOfChildrenLeft);
  }

  List<double> get rightBezierHeights {
    return _calcBezierHeights(_rightCanvasOffset, _numberOfChildrenRight);
  }

  double get lefttBezierCenter => height / 2;

  List<double> _calcBezierHeights(double offset, int numberOfChildren) {
    if (numberOfChildren == 0) {
      return [];
    }
    List<double> result = [
      offset + AppConstants.verticalNodePadding + AppConstants.nodeHeight / 2
    ];
    for (int i = 1; i < numberOfChildren; i++) {
      result.add(result.last + AppConstants.interNodeDistance);
    }
    return result;
  }
}