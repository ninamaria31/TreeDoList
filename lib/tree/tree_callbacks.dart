import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree.dart';
import 'package:intl/intl.dart';
import '../services/flask_server.dart';

mixin TreeCallbacks<T extends StatefulWidget> on State<T> {
  void onTapCallback(TreeNode node, BuildContext context) =>
      showDetails(node, context);

  bool _rebuildBitonicChildren = false;

  void onLongPressCallback(TreeNode node, BuildContext context) =>
      addChild(node, context);

  void onDoubleTapCallback(TreeNode node) => toggleComplete(node);

//// TODO: create a sufficient details screen (edit and remove)
  void showDetails(TreeNode node, BuildContext context, {bool? edit}) {
    // remove: just call node.removeSelf() on the node which is supposed to be removed
    // if the node or tree was modified call node.notifyModification() or tree.modify() (the first just calls the latter)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            title: Text(node.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.description ?? 'No Description'),
                Text(
                    'Due ${node.dueDate != null ? DateFormat('d MMM').format(node.dueDate!) : 'No Due Date'}'),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF707070),
                        backgroundColor:
                            const Color(0xFFCCDBA8), // This is the text color
                      ),
                      child: const Text('edit'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showEditDialog(context, node);
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0), // Add space between the buttons
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF707070),
                        backgroundColor:
                            const Color(0xFFD98477), // This is the text color
                      ),
                      child: const Text('delete'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm'),
                              content: const Text(
                                  'Are you sure you want to remove the leaf?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('NO'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('yes'),
                                  onPressed: () {
                                    node.notifyModification();
                                    node.removeSelf();
                                    setState(() {
                                      _rebuildBitonicChildren = true;
                                    });
                                    updateTreeDB(node.tree?.toJson());
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: const Text(
                                              'The leaf has been deleted'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('ok!'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showEditDialog(BuildContext context, TreeNode node) {
    var updName = node.name;
    var updDescription = node.description;
    var updDuedate = node.dueDate;
    final dueDateController =
        TextEditingController(text: formatDate(node.dueDate));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width *
                0.05, // 5% from left and right
            vertical: MediaQuery.of(context).size.height *
                0.05, // 10% from top and bottom
          ),
          child: AlertDialog(
            contentPadding: EdgeInsets.zero,
            // Remove padding inside the dialog
            insetPadding: EdgeInsets.zero,
            // Remove padding around the dialog
            clipBehavior: Clip.none,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const Text('Edit Node'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.9, // 90% of screen width
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      initialValue: node.name,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      onChanged: (value) {
                        updName = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      initialValue: node.description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      onChanged: (value) {
                        updDescription = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      readOnly: true,
                      // make this field read-only
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                      ),
                      controller: dueDateController,
                      // use the TextEditingController
                      onTap: () async {
                        // show the date picker when the due date field is tapped
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: node.dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (selectedDate != null) {
                          updDuedate = selectedDate;
                          // Update the text of the TextFormField
                          dueDateController.text = formatDate(selectedDate);
                        }
                      },
                    ),
                  ),
                  // Add more fields for other properties
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  // Save the changes here
                  node.notifyModification();
                  node.name = updName;
                  node.description = updDescription;
                  node.dueDate = updDuedate;
                  updateTreeDB(node.tree?.toJson());
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void toggleComplete(TreeNode node) async {
    (node.completed == null) ? node.complete() : node.undoComplete();
    Tree? updatedTree = await updateTreeDB(node.tree?.toJson()); // updates the tree in the database
    setState(() {
      node;
    });
  }

  void addChild(TreeNode node, BuildContext context) async {
    TreeNode newNode = TreeNode("", Priority.medium);
    showAddNodeDialog(context, node, newNode);
  }

  void showAddNodeDialog(BuildContext context, TreeNode node, TreeNode newNode) {
    var name;
    var description;
    var dueDate;

    final dueDateController =
    TextEditingController(text: formatDate(node.dueDate));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width *
                0.05, // 5% from left and right
            vertical: MediaQuery.of(context).size.height *
                0.05, // 10% from top and bottom
          ),
          child: AlertDialog(
            contentPadding: EdgeInsets.zero,
            // Remove padding inside the dialog
            insetPadding: EdgeInsets.zero,
            // Remove padding around the dialog
            clipBehavior: Clip.none,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    newNode.removeSelf();
                    setState(() {
                      _rebuildBitonicChildren = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                const Text(
                  "Add a new task",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.9, // 90% of screen width
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      onChanged: (value) {
                        name = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    // Add padding around the TextFormField
                    child: TextFormField(
                      readOnly: true,
                      // make this field read-only
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                      ),
                      controller: dueDateController,
                      // use the TextEditingController
                      onTap: () async {
                        // show the date picker when the due date field is tapped
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: null ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (selectedDate != null) {
                          dueDate = selectedDate;
                          // Update the text of the TextFormField
                          dueDateController.text = formatDate(selectedDate);
                        }
                      },
                    ),
                  ),
                  // Add more fields for other properties
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  // Save the changes here
                  newNode.name = name;
                  newNode.description = description;
                  newNode.dueDate = dueDate;
                  newNode.notifyModification();
                  setState(() {
                    node.addChild(newNode);
                    _rebuildBitonicChildren = true;
                  });
                  updateTreeDB(newNode.tree?.toJson());
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  bool get rebuildBitonicChildren {
    bool tmp = _rebuildBitonicChildren;
    _rebuildBitonicChildren = !_rebuildBitonicChildren;
    return tmp;
  }

  String formatDate(DateTime? date) {
    var dayFormat = NumberFormat('#', 'en_US');
    if (date == null) {
      return 'No Due Date';
    } else {
      var dayString = dayFormat.format(date?.day);
      var day = int.parse(dayString);
      var suffix = 'th';

      if (!(day >= 11 && day <= 13)) {
        var lastDigit = day % 10;
        if (lastDigit == 1) {
          suffix = 'st';
        } else if (lastDigit == 2) {
          suffix = 'nd';
        } else if (lastDigit == 3) {
          suffix = 'rd';
        }
      }

      var formatter = DateFormat('d\'$suffix\' MMMM yyyy');
      return formatter.format(date!);
    }
  }
}
