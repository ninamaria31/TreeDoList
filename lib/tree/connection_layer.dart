import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree.dart';

import '../app_constants.dart';

class Connection {
  // small inconsistency since we want *start* to be the top of the
  // left node but *ends* to be the centers
  final double start;
  final List<double> ends;

  Connection(this.start, this.ends);
}

abstract class AbstractConnectionLayerPainter extends CustomPainter {
  final Connection connection;
  final double height;
  final ValueNotifier<List<double>> scrollOffset;
  double width;

  // the following two are the offsets necessary to center the whole thing
  // The issue is we have two kinds of connections.
  // 1. To the NodeListRegular
  //    where we center the set of nodes vertically
  //    (even number of nodes => no node at the exact center,
  //    odd number of nodes => node is exactly at the center).
  // 2. To the NodeListCarousel
  //    where we always have a node at the center
  //
  // => we make the class abstract and create subclasses which set the offset
  late double offsetStart;
  late double offsetEnd;


  // when offset changes the canvas is repainted
  AbstractConnectionLayerPainter(
      {required this.connection, required this.scrollOffset, required this.height, this.width = AppConstants.canvasWidth})
      : super(repaint: scrollOffset);

  AbstractConnectionLayerPainter.fromNode(TreeNode node, {double? height})
      : height = height ?? AppConstants.subTreeHeight(node.leafsInSubTree),
        scrollOffset = ValueNotifier<List<double>>([0,0]),
        connection = Connection(0, bezierEndsFromChild(node)),
        width = AppConstants.canvasWidth;

  @override
  void paint(Canvas canvas, Size size) {
    Path curve = Path();
    Offset endControl;
    Offset startControl;

    offsetStart = height / 2;
    offsetEnd = calculateBaseEndOffset();
    // now we add the offset we need to apply because of scrolling which is why we get it from the valueNotifier which will be changed in the setState() whenever scrolling takes place
    offsetStart += scrollOffset.value[0];
    offsetEnd += scrollOffset.value[1];

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = AppConstants.connectionLineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;


    endControl = Offset( width / 2, connection.start + offsetStart);
    for (var endpoint in connection.ends) {
      startControl = Offset( width / 2, endpoint + offsetEnd);
      curve.moveTo(0, connection.start + offsetStart);
      curve.cubicTo(endControl.dx, endControl.dy, startControl.dx,
          startControl.dy,  width, endpoint + offsetEnd);
      canvas.drawPath(curve, paint);
      //canvas.drawLine(Offset(0, bezierStartHeight),
      //Offset(AppConstants.canvasWidth, endPoint), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  static bezierEndsFromChild(TreeNode node) {
    List<double> res = [];
    double cumulativeHeight = 0;
    double tmp = 0;
    for (var child in node.children) {
      tmp = AppConstants.subTreeHeight(child.leafsInSubTree) / 2;
      cumulativeHeight += tmp;
      res.add(cumulativeHeight);
      cumulativeHeight += tmp;
    }
    return res;
  }

  double calculateBaseEndOffset();
}

class RegularConnectionLayerPainter extends AbstractConnectionLayerPainter {
  RegularConnectionLayerPainter({required super.connection, required super.scrollOffset, required super.height});

  @override
  double calculateBaseEndOffset() {
    return max(0, (height - connection.ends.length * AppConstants.paddedNodeHeight) / 2);
  }
}

class CarouselConnectionLayerPainter extends AbstractConnectionLayerPainter {
  CarouselConnectionLayerPainter({required super.connection, required super.scrollOffset, required super.height, super.width});

  @override
  double calculateBaseEndOffset() {
    return height / 2 - AppConstants.paddedNodeCenter;
  }
}

class OverviewConnectionLayerPainter extends AbstractConnectionLayerPainter {
  OverviewConnectionLayerPainter({required super.connection, required super.scrollOffset, required super.height});
  OverviewConnectionLayerPainter.fromNode(super.node, {super.height}): super.fromNode();

  @override
  double calculateBaseEndOffset() => 0;

}

/*class ConnectionLayerPainter extends CustomPainter {
  final double bezierStart;
  late final List<double> bezierEnds;
  double width;

  final double? startXOffset;

  ConnectionLayerPainter(
      {super.repaint,
      required this.bezierStart,
      required this.bezierEnds,
      this.width = AppConstants.canvasWidth,
      this.startXOffset});

  ConnectionLayerPainter.fromNode(TreeNode node,
      {this.startXOffset, this.width = AppConstants.canvasWidth, super.repaint})
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
      endControl = Offset(width / 2, bezierStart);
      startControl = Offset(width / 2, endPoint);
      curve.moveTo(0 + (startXOffset ?? 0), bezierStart);
      curve.cubicTo(endControl.dx, endControl.dy, startControl.dx,
          startControl.dy, width, endPoint);
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
}*/
