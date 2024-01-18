import 'tree.dart';
import '../app_constants.dart';
import 'package:flutter/material.dart';

/// widget used to draw a node
class NodeWidget extends StatelessWidget {
  final TreeNode node;
  final bool showLeafCount;

  /// Function called when the node is tapped.
  final void Function(TreeNode, DragEndDetails)? onHorDragEndCallback;
  final void Function(TreeNode, BuildContext)? onTapCallback;
  final void Function(TreeNode, BuildContext)? onLongPressCallback;
  final void Function(TreeNode)? onDoubleTapCallback;

  const NodeWidget(
      {super.key,
      required this.node,
      this.showLeafCount = false,
      this.onTapCallback,
      this.onHorDragEndCallback,
      this.onLongPressCallback,
      this.onDoubleTapCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTapCallback?.call(node, context),
      onDoubleTap: () => onDoubleTapCallback?.call(node),
      onLongPress: () => onLongPressCallback?.call(node, context),
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
                  right:
                      AppConstants.endPadding - AppConstants.nodeBadeSize / 2,
                  top: AppConstants.verticalNodePadding -
                      AppConstants.nodeBadeSize / 2,
                  width: AppConstants.nodeBadeSize,
                  height: AppConstants.nodeBadeSize,
                  child: Container(
                      decoration: BoxDecoration(
                          color: (node.completed == null) ? node.priority.color : Colors.grey,
                          border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: AppConstants.nodeLineWidth),
                          borderRadius: BorderRadius.circular(
                              AppConstants.nodeBadeSize / 2)),
                      child: Center(
                          child: Text(
                        node.leafsInSubTree.toString(),
                        style: AppConstants.nodeTextStyle,
                      ))),
                )
            ]),
    );
  }

  Widget _buildNode() {
    return Container(
        height: AppConstants.nodeHeight,
        width: AppConstants.nodeWidth,
        decoration: BoxDecoration(
          color: (node.completed == null) ? node.priority.color : Colors.grey,
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
