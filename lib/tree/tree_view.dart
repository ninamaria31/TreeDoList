import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_vis_elements.dart';
import 'tree.dart';
import 'package:snap_scroll_physics/snap_scroll_physics.dart';
import '../app_constants.dart';

class Constants {
  static const double inter_node_distance = 10.0;
}

class TreeView extends StatefulWidget {
  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  Tree todoTree = Tree();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; i++) {
      String name = 'A$i';
      todoTree.addChildToNode(todoTree.root.id, TreeNode(name, Priority.low));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NodeList(todoTree.root.children.toList());
  }


}

class NodeList extends StatelessWidget {
  final ScrollController _scrollController;
  List<TreeNode> _nodes;
  int selected;

  NodeList(this._nodes, {super.key})
      : _scrollController = ScrollController(),
        selected = _nodes.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: SnapScrollPhysics.builder(getSnaps),
      slivers: <Widget>[
        SliverList(delegate: SliverChildListDelegate(
            List.generate(_nodes.length, (index) => NodeWidget(node: _nodes[index]))
        ))
      ],
    );
  }

  List<Snap> getSnaps() {
    double interNodeDistance = AppConstants.verticalNodePadding * 2 + AppConstants.nodeHeight;
    List<Snap> res = [];
    for (int i = 0; i < _nodes.length; i++) {
      res.add(Snap(interNodeDistance*i, distance: interNodeDistance/2));
    }
    return res;
  }

  List<Widget> _listItems() {
    return _nodes.map((e) => NodeWidget(node: e)).toList();
  }

  void update(List<TreeNode> newNodes) {
    _nodes = newNodes;
  }
}
