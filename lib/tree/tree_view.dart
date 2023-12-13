import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_vis_elements.dart';
import 'tree.dart';
import 'package:snap_scroll_physics/snap_scroll_physics.dart';
import '../app_constants.dart';


class TreeView extends StatefulWidget {
  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  Tree todoTree = Tree();
  ScrollController _scrollController = ScrollController();
  late TreeNodeLayerHalves halves;

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; i++) {
      String name = 'A$i';
      todoTree.addChildToNode(todoTree.root.id, TreeNode(name, Priority.low));
    }
    halves = todoTree.root.halves;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
          borderRadius: BorderRadius.circular(8),
        ),
        height: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NodeList(TreeNodeLayerHalves()..center = todoTree.root),
            CustomPaint(
                painter: ConnectionLayerPainter(constraints.maxHeight / 2,
                    yPositionEqualDist(todoTree.root.numberChildren)
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: AppConstants.canvasWidth,
                  height: constraints.maxHeight,
                ),
            ),
            NodeList(halves)
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
}

class NodeList extends StatelessWidget {
  final ScrollController _scrollController;
  final TreeNodeLayerHalves _halves;

  NodeList(this._halves, {super.key})
      : _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    if (_halves.center == null) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
        borderRadius: BorderRadius.circular(8),
      ),
      width: AppConstants.nodeWidth,
      height: (_halves.top.length + 1 + _halves.bottom.length)*(AppConstants.verticalNodePadding * 2 + AppConstants.nodeHeight),
      child: Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          physics: SnapScrollPhysics.builder(getSnaps),
          scrollDirection: Axis.vertical,
          children: List.from(
              _buildTreeNodesListItems(_halves.top))
              ..addAll(_buildTreeNodesListItems([_halves.center!]))
              ..addAll(_buildTreeNodesListItems(_halves.bottom))),
      ),
    );
  }

  static List<Widget> _buildTreeNodesListItems(List<TreeNode> nodes) {
    return nodes.map((n) => NodeWidget(node: n)).toList();
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
