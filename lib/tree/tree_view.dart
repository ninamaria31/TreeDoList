import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_vis_elements.dart';
import 'tree.dart';
import 'package:snap_scroll_physics/snap_scroll_physics.dart';
import '../app_constants.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  CarouselController _controller = CarouselController();
  BitonicSequence bitonicSiblings;
  BitonicSequence bitonicChildren;

  TreeViewState({required this.todoTree})
      : center = todoTree.root,
        bitonicSiblings = BitonicSequence(todoTree.root),
        bitonicChildren = BitonicSequence.fromIterable(todoTree.root.children);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      BezierHeightGenerator bezierHeights = BezierHeightGenerator(
          bitonicSiblings.length, bitonicChildren.length,
          forceHeight: constraints.maxHeight);
      return Container(
        //decoration: BoxDecoration(
        //  border: Border.all(
        //    color: Colors.lightBlue, width: AppConstants.nodeLineWidth),
        //  borderRadius: BorderRadius.circular(8),
        //),
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // just assuming that this is not going to be null seems sketchy but every valid node has valid siblings (they include the center node as well)
              NodeList(
                  items: bitonicSiblings,
                  height: bezierHeights.height,
                  controller: _controller,
                  onChangeCallback: onScrollChangeCallback,
                  onHorDragEndCallback: onHorDragEndCallbackParent),
              CustomPaint(
                painter: ConnectionLayerPainter(
                    bezierHeights
                        .rightBezierCenter, //.leftBezierHeights[bitonicSiblings.indexOf(center)],
                    bezierHeights.rightBezierHeights),
                child: Container(
                  //decoration: BoxDecoration(
                  //  border: Border.all(
                  //      color: Colors.lightBlue,
                  //      width: AppConstants.nodeLineWidth),
                  //  borderRadius: BorderRadius.circular(8),
                  //),
                  width: AppConstants.canvasWidth,
                  height: bezierHeights.height,
                ),
              ),
              if (bitonicChildren.center != null)
                NodeList(
                    items: bitonicChildren,
                    height: bezierHeights.height,
                    onHorDragEndCallback: onHorDragEndCallbackChild),
            ],
          ),
        ),
      );
    });
  }

  static List<double> yPositionEqualDist(int numberOfChildren) {
    List<double> res = [];

    double pos = AppConstants.interNodeDistance / 2;
    for (int i = 0; i < numberOfChildren; i++) {
      res.add(pos);
      pos += AppConstants.interNodeDistance;
    }

    return res;
  }

  void onHorDragEndCallbackChild(TreeNode node, DragEndDetails details) =>
      setState(() {
        // could check for primary velocity
        if (details.primaryVelocity != null) {
          newCenter(center = node);
        }
      });

  void onHorDragEndCallbackParent(TreeNode node, DragEndDetails details) =>
      setState(() {
        if (details.primaryVelocity != null && node.parent != null) {
          newCenter(node.parent!);
        }
      });
  void onScrollChangeCallback(int index, CarouselPageChangedReason reason) =>
      setState(() {
        if (reason == CarouselPageChangedReason.manual) {
          shiftCenter(bitonicSiblings.elementAt(index));
        }
      });

  void newCenter(TreeNode newCenter) {
    center = newCenter;
    bitonicSiblings = BitonicSequence.fromNode(center);
    bitonicChildren = BitonicSequence.fromIterable(center.children);
    var index = bitonicSiblings.indexOf(center);
    _controller.jumpToPage(index);
  }

  void shiftCenter(TreeNode sCenter) {
    center = sCenter;
    bitonicChildren = BitonicSequence.fromIterable(center.children);
  }
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

  BezierHeightGenerator(int numberOfNodesLeft, int numberOfNodesRight,
      {double? forceHeight})
      : _numberOfChildrenLeft = numberOfNodesLeft,
        _numberOfChildrenRight = numberOfNodesRight,
        _leftCanvasHeight = AppConstants.interNodeDistance * numberOfNodesLeft,
        _rightCanvasHeight =
            AppConstants.interNodeDistance * numberOfNodesRight {
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

  double get rightBezierCenter => height / 2;

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

class NodeList extends StatelessWidget {
  final ScrollController _scrollController;
  final BitonicSequence items;
  final void Function(TreeNode, DragEndDetails)? onHorDragEndCallback;
  final double height;
  final CarouselController? controller;
  final Function(int, CarouselPageChangedReason)? onChangeCallback;

  NodeList(
      {required this.items,
      required this.height,
      this.controller,
      this.onChangeCallback,
      super.key,
      this.onHorDragEndCallback})
      : _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    if (items.center == null) {
      return Container();
    }
    return Container(
        //decoration: BoxDecoration(
        //  border: Border.all(
        //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
        //  borderRadius: BorderRadius.circular(8),
        //),
        width: AppConstants.nodeWidth,
        height: controller != null
            ? height
            : items.length *
                (AppConstants.nodeHeight +
                    2 * AppConstants.verticalNodePadding),
        child: controller != null
            ? CarouselSlider(
                options: CarouselOptions(
                    height: height,
                    enlargeCenterPage: false,
                    enableInfiniteScroll: false,
                    scrollDirection: Axis.vertical,
                    viewportFraction: AppConstants.interNodeDistance / height,
                    onPageChanged: onChangeCallback
                ),
                carouselController: controller,
                items: List.from(_buildTreeNodesListItems(items.top))
                  ..addAll(_buildTreeNodesListItems([items.center!]))
                  ..addAll(_buildTreeNodesListItems(items.bottom)))
            : ListView(
                controller: _scrollController,
                physics: SnapScrollPhysics.builder(getSnaps),
                scrollDirection: Axis.vertical,
                children: List.from(_buildTreeNodesListItems(items.top))
                  ..addAll(_buildTreeNodesListItems([items.center!]))
                  ..addAll(_buildTreeNodesListItems(items.bottom))));
  }

  List<Widget> _buildTreeNodesListItems(List<TreeNode> nodes) {
    return nodes
        .map((n) => NodeWidget(
              node: n,
              onHorDragEndCallback: onHorDragEndCallback,
            ))
        .toList();
  }

  List<Snap> getSnaps() {
    List<Snap> res = [];
    for (int i = 0; i < items.top.length + 1 + items.bottom.length; i++) {
      res.add(Snap(AppConstants.interNodeDistance * i,
          distance: AppConstants.interNodeDistance / 2));
    }
    return res;
  }

  //void update(List<TreeNode> newNodes) {
  //  _nodes = newNodes;
  //}
}
