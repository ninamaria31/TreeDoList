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
      BezierHeights bezierHeights = BezierHeights(
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
              NodeList(
                  items: bitonicSiblings,
                  height: constraints.maxHeight,
                  controller: _controller,
                  onChangeCallback: onScrollChangeCallback,
                  onHorDragEndCallback: onHorDragEndCallbackParent),
              CustomPaint(
                painter: ConnectionLayerPainter(
                    bezierHeights
                        .lefttBezierCenter, //.leftBezierHeights[bitonicSiblings.indexOf(center)],
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
              if (bitonicChildren.isNotEmpty)
                NodeList(
                    items: bitonicChildren,
                    height: constraints.maxHeight,
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
    if (items.isEmpty) {
      return Container();
    }
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
          borderRadius: BorderRadius.circular(8),
        ),
        width: AppConstants.nodeWidth,
        height: controller != null
            ? height
            : items.length * AppConstants.interNodeDistance,
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
                items: List.from(_buildTreeNodesListItems(items.iter)))
            : ListView(
                controller: _scrollController,
                physics: SnapScrollPhysics.builder(getSnaps),
                scrollDirection: Axis.vertical,
                children: List.from(_buildTreeNodesListItems(items.iter, showLeafCount: true))
                  // TODO: can this be solved more elegantly? (EDIT: yes if the paddedSize is a multiple of the screen height minus the appbar)
                  // TLDR: Invisible SizeBox to make sure our scroll offset is a multiple of the paddedNodeHeight
                  // right now when the height of the screen (minus appbar) is less than the height of our nodes
                  // (or in other words if scrolling will be enabled) we add an invisible sizebox which
                  // is has the exact height to make the combined height of our list items (nodes + invisible sizebox)
                  // equal to the screen height. So even if we scroll all the way to the bottom the bezier curves and
                  // and the nodes still line up
                  ..addAll((items.length * AppConstants.interNodeDistance <= height)
                  ? []
                  : [Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: height % AppConstants.interNodeDistance)
                  ])));
  }

  List<Widget> _buildTreeNodesListItems(Iterable<TreeNode> nodes, {bool showLeafCount = false}) {
    return nodes
        .map((n) => NodeWidget(
              node: n,
              onHorDragEndCallback: onHorDragEndCallback,
              showLeafCount: showLeafCount,
            ))
        .toList();
  }

  List<Snap> getSnaps() {
    List<Snap> res = [];
    for (int i = 0; i < items.length + 1; i++) {
      res.add(Snap(AppConstants.interNodeDistance * i,
          distance: AppConstants.interNodeDistance / 2));
    }
    return res;
  }

  //void update(List<TreeNode> newNodes) {
  //  _nodes = newNodes;
  //}
}
