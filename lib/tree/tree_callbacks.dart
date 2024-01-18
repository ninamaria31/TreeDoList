import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree.dart';

mixin TreeCallbacks<T extends StatefulWidget> on State<T> {
  void onTapCallback(TreeNode node, BuildContext context) => showDetails;
  void onLongPressCallback(TreeNode node, BuildContext context) => addChild(node, context);
  void onDoubleTapCallback(TreeNode node) => toggleComplete(node);


//// TODO: create a sufficient details screen (edit and remove)
  void showDetails(TreeNode node, BuildContext context, {bool? edit}) {
    // remove: call removeChild(TreeNode child) in the Tree *not* in the TreeNode directly

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(node.name),
            content: Text(
                '${node.description ?? 'No Description'} due on ${node.dueDate?.toString()}'),
          );
        });
  }

  void toggleComplete(TreeNode node) {
    setState(() {
      (node.completed == null) ? node.complete() : node.undoComplete();
    });
    // completion: call complete() and undoComplete() in the TreeNode directly
  }

  void addChild(TreeNode node, BuildContext context) {
    setState(() {
      TreeNode newNode = TreeNode("", Priority.medium);
      node.addNodeToParentTree(newNode);
      showDetails(newNode, context, edit: true);
    });
  }
}
