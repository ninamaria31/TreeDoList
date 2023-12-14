
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_vis_elements.dart';
import 'tree.dart';
import 'package:snap_scroll_physics/snap_scroll_physics.dart';
import '../app_constants.dart';


class TreeView extends StatefulWidget {
  final Tree todoTree;
  const TreeView({super.key, required this.todoTree});

  @override
  TreeViewState createState() => TreeViewState(todoTree: todoTree);
}

class TreeViewState extends State<TreeView> {
  Tree todoTree;
  TreeNode center;
  // final ScrollController _scrollController = ScrollController();

  TreeViewState({required this.todoTree}) : center = todoTree.root;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    BitonicSequence bitonicSiblings = BitonicSequence.fromNode(center);
    BitonicSequence bitonicChildren = BitonicSequence.fromIterable(center.children);
    return LayoutBuilder(builder: (context, constraints) {
      BezierHeightGenerator bezierHeights = BezierHeightGenerator(bitonicSiblings.length, bitonicChildren.length, forceHeight: constraints.maxHeight);
      return Container(
        //decoration: BoxDecoration(
        //  border: Border.all(
        //    color: Colors.lightBlue, width: AppConstants.nodeLineWidth),
        //  borderRadius: BorderRadius.circular(8),
        //),
        height: MediaQuery.of(context).size.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // just assuming that this is not going to be null seems sketchy but every valid node has valid siblings (they include the center node as well)
            NodeList(bitonicSiblings, onHorDragEndCallback: onHorDragEndCallbackParent),
            CustomPaint(
              // this looks kind of cursed but it just calculates the common start of the berzier curves as well as the ends
              // TODO: create functions for start and endpoint generation also take into consideration,
              //  that the starting point is not always right in the middle
                painter: ConnectionLayerPainter(bezierHeights.leftBezierHeights[bitonicSiblings.indexOf(center)],
                  bezierHeights.rightBezierHeights
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.lightBlue, width: AppConstants.nodeLineWidth),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: AppConstants.canvasWidth,
                  height: bezierHeights.height,
                ),
            ),
            if(bitonicChildren.center != null)
            NodeList(bitonicChildren, onHorDragEndCallback: onHorDragEndCallbackChild)
          ],
        ),
      );
    });
  }

  static List<double> yPositionEqualDist(int numberOfChildren) {
    List<double> res = [];

    double pos = AppConstants.interNodeDistance / 2;
    for (int i = 0; i < numberOfChildren; i++){
      res.add(pos);
      pos += AppConstants.interNodeDistance;
    }

    return res;
  }

  void onHorDragEndCallbackChild(TreeNode node, DragEndDetails details) =>
    setState(() {
      // could check for primary velocity
      if (details.primaryVelocity != null) {
        center = node;
      }
    });

  void onHorDragEndCallbackParent(TreeNode node, DragEndDetails details) =>
      setState(() {
        if (details.primaryVelocity != null && node.parent!= null) {
          center = node.parent!;
        }
      });
}

/// Generates the heights where the bezier curves start end end
class BezierHeightGenerator {
  final double _leftCanvasHeight;
  final double _rightCanvasHeight;
  final int _numberOfChildrenLeft;
  final int _numberOfChildrenRight;

  late double height;
  late double _leftCanvasOffset;
  late double _rightCanvasOffset;

  BezierHeightGenerator(int numberOfNodesLeft, int numberOfNodesRight, {double? forceHeight}) :
        _numberOfChildrenLeft = numberOfNodesLeft,
        _numberOfChildrenRight = numberOfNodesRight,
        _leftCanvasHeight = AppConstants.interNodeDistance * numberOfNodesLeft,
        _rightCanvasHeight = AppConstants.interNodeDistance * numberOfNodesRight {
    height = forceHeight ?? max(_leftCanvasHeight, _rightCanvasHeight);
    _leftCanvasOffset = (_leftCanvasHeight - height).abs() / 2;
    _rightCanvasOffset = (_rightCanvasHeight - height).abs() / 2;
  }

  List<double> get leftBezierHeights {
    return _calcBezierHeights(_leftCanvasOffset, _numberOfChildrenLeft);
  }
  List<double> get rightBezierHeights {
    return _calcBezierHeights(_rightCanvasOffset, _numberOfChildrenRight);
  }
  
  List<double> _calcBezierHeights(double offset, int numberOfChildren) {
    if (numberOfChildren == 0) {
      return [];
    }
    List<double> result = [offset + AppConstants.verticalNodePadding + AppConstants.nodeHeight / 2];
    for(int i = 1; i < numberOfChildren; i++) {
      result.add(result.last + AppConstants.interNodeDistance);
    }
    return result;
  }
}

class NodeList extends StatelessWidget {
  final ScrollController _scrollController;
  final BitonicSequence _halves;
  final void Function(TreeNode, DragEndDetails)? onHorDragEndCallback;

  NodeList(this._halves, {super.key, this.onHorDragEndCallback})
      : _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    if (_halves.center == null) {
      return Container();
    }
    return Container(
      //decoration: BoxDecoration(
      //  border: Border.all(
      //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
      //  borderRadius: BorderRadius.circular(8),
      //),
      width: AppConstants.nodeWidth,
      height: (_halves.length)*(AppConstants.verticalNodePadding * 2 + AppConstants.nodeHeight),
      child: ListView(
        controller: _scrollController,
        physics: SnapScrollPhysics.builder(getSnaps),
        scrollDirection: Axis.vertical,
        children: List.from(
            _buildTreeNodesListItems(_halves.top))
            ..addAll(_buildTreeNodesListItems([_halves.center!]))
            ..addAll(_buildTreeNodesListItems(_halves.bottom))),
    );
  }

  List<Widget> _buildTreeNodesListItems(List<TreeNode> nodes) {
    return nodes.map((n) => NodeWidget(node: n, onHorDragEndCallback: onHorDragEndCallback,)).toList();
  }

  List<Snap> getSnaps() {
    List<Snap> res = [];
    for (int i = 0; i < _halves.top.length + 1 + _halves.bottom.length; i++) {
      res.add(Snap(AppConstants.interNodeDistance * i,
          distance: AppConstants.interNodeDistance / 2));
    }
    return res;
  }

  //void update(List<TreeNode> newNodes) {
  //  _nodes = newNodes;
  //}
}
