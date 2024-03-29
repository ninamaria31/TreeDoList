import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_constants.dart';

enum Priority implements Comparable<Priority> {
  high,
  medium,
  low;

  Color get color {
    switch (this) {
      case low:
        return Colors.lightGreen.shade200;
      case medium:
        return Colors.yellow.shade200;
      case high:
        return Colors.red.shade200;
    }
  }

  @override
  int compareTo(Priority other) => index.compareTo(other.index);
}

/// A class representing a task (leaf) or task group (node)
///
/// Can be created three ways:
///   - TreeNode constructor used for the creation of new leaves
///   - TreeNode.existingNode used for the recreation of a TreeNode
///   - TreeNode.comparisonNode creates invalid TreeNode only used for comparisons
class TreeNode {
  // 128 bit random number so we can ignore collisions
  String id;

  DateTime? dueDate;

  /// backlink to the Parent for ease of use
  TreeNode? parent;

  Tree? tree;

  /// Name of the task our task group
  String name = '';

  /// Optional description of the task (group)
  String? description;

  /// the priority
  Priority priority;

  /// Timestamp of the completion null means the tasks is not completed
  /// (in milliseconds since January 1, 1970, 00:00:00 UTC)
  int? completed;

  /// SplayTreeSet of the Trees children (ordering is used by the visualisation)
  SplayTreeSet<TreeNode> _children;

  /// number of leaves in the subtree (used by the visualization)
  int leafsInSubTree;

  static Comparator<TreeNode> treeNodeComparator = (lhs, rhs) {
    // probably more overhead :/
    // int res = (lhs.dueDate ?? DateTime(0)).compareTo(rhs.dueDate ?? DateTime(0));
    // return res == 0 ? lhs.id.compareTo(rhs.id) : res;

    // comparator for ordering based on dueDate
    //if (lhs.dueDate == null && rhs.dueDate == null) {
    //  return lhs.id.compareTo(rhs.id);
    //}
    //if (lhs.dueDate == null) {
    //  return -1;
    //}
    //if (rhs.dueDate == null) {
    //  return 1;
    //}
    //int ret = lhs.dueDate!.compareTo(rhs.dueDate!);
    //if (ret == 0) {
    //  return lhs.id.compareTo(rhs.id);
    //}
    //return ret;
    return (lhs.priority == rhs.priority)
        ? lhs.id.compareTo(rhs.id)
        : lhs.priority.index.compareTo(rhs.priority.index);
  };

  /// Constructor for TreeNodes
  ///
  /// takes a [name] and a [priority]
  /// a [description] can also be supplied
  TreeNode(this.name, this.priority, {this.description, this.dueDate})
      : _children = SplayTreeSet(treeNodeComparator),
        id = const Uuid().v4(),
        leafsInSubTree = 1;

  /// Constructs TreeNode that have already existed before
  ///
  /// The immediate children are properly added using addChild
  /// but the grandchildren not
  /// Children need to be valid
  TreeNode.existingNode(
      this.id,
      this.name,
      this.description,
      this.priority,
      this.completed,
      this.dueDate,
      Iterable<TreeNode> childTasks)
      : _children = SplayTreeSet(treeNodeComparator),
        leafsInSubTree = 1 {
    for (var child in childTasks) {
      _addChild(child);
    }
  }

  /// Json constructor creates TreeNodes recursively
  ///
  /// It uses a breadth first approach and creates a tree from the bottom up
  /// So it starts with the leafs adds them to their parents
  /// (by using the existingNode constructor), adds the parents to the next level
  /// and so on and so forth
  factory TreeNode.fromJson(dynamic json) {
    List<TreeNode> tmpChildren = [];
    if (json['children'] != null) {
      for (var child in json['children']) {
        tmpChildren.add(TreeNode.fromJson(child));
      }
    }
    return TreeNode.existingNode(
        json['uuid'] as String,
        json['name'] as String,
        json['description'] as String?,
        Priority.values[json['priority'] as int],
        json['completed'] as int?,
        DateTime.tryParse(json['dueDate'] ?? ''),
        tmpChildren);
  }

  /// Serialize to json
  ///
  /// returns a json string
  Map<String, dynamic> toJson() {
    return {
      "uuid": id,
      "name": name,
      "description": description,
      "completed": completed,
      "dueDate": dueDate?.toIso8601String(),
      "priority": priority.index,
      "children": _children.map((e) => e.toJson()).toList()
    };
  }

  /// A constructor for creating nodes only used for comparisons
  /// against other nodes
  ///
  /// takes just the [id]
  TreeNode.comparisonNode(this.id)
      : priority = Priority.medium,
        _children = SplayTreeSet(treeNodeComparator),
        leafsInSubTree = 1;

  // Override == and hashCode in order to store this in a hash set
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNode && runtimeType == other.runtimeType && id == other.id;

  // just use the id's hash since we assume the uuids dont collide
  @override
  int get hashCode => id.hashCode;

  /// adds TreeNodes to this TreeNode's [_children] and set the [parent] only for internal use
  ///
  /// takes a [child]
  /// also updates [leafsInSubTree] in its parent
  ///
  /// return true if successful
  bool _addChild(TreeNode child) {
    // if we used to be a leaf we need to take that into account
    int leafIncrease =
        (_children.isEmpty) ? child.leafsInSubTree - 1 : child.leafsInSubTree;
    if (!_children.add(child)) {
      return false;
    }
    child.parent = this;

    // update our own leaf count
    if (leafIncrease != 0) {
      updateLeafCount(leafIncrease);
    }
    return true;
  }

  /// adds a child to its children by calling addChildToNode in its parent tree
  ///
  /// takes a [newChild]
  ///
  /// return true if successful
  bool addChild(TreeNode newChild) => tree?.addChildToNode(id, newChild) ?? false;
  
  /// deleted a child form the Node's [_children] for internal use only
  /// 
  /// takes a [child]
  /// also updates [leafsInSubTree] in its parent
  /// 
  /// return true if successful
  bool _removeChild(TreeNode child) {
    if (!_children.remove(child)) {
      return false;
    }

    notifyModification();

    updateLeafCount((_children.isEmpty) ? -child.leafsInSubTree + 1: -child.leafsInSubTree);
    
    return true;
  }

  /// deletes this node from its parent
  ///
  /// return ture if successful and false otherwise
  /// returns false if this is the root
  bool removeSelf() {
    return tree?.removeChild(this) ?? false;
  }

  bool _complete(int timeStamp) {
    if (completed != null) {
      return false;
    }
    completed = timeStamp;
    for (var child in _children) {
      child._complete(timeStamp);
    }
    notifyModification();
    return true;
  }

  /// complete this task/node
  ///
  /// the completion timestamp will be now()
  bool complete() => _complete(DateTime.now().millisecondsSinceEpoch);

  bool _undoComplete(int timeStamp) {
    for (var child in _children) {
      child._undoComplete(timeStamp);
    }
    if (completed == timeStamp) {
      completed = null;
    }
    _markRecursivelyAsNotCompleted(parent);
    notifyModification();
    return true;
  }

  void _markRecursivelyAsNotCompleted(TreeNode? parent) {
    if (parent?.completed == null ?? false) {
      return;
    }
    parent!.completed = null;
    _markRecursivelyAsNotCompleted(parent.parent);

  }

  /// undo the completion for this node and every child in the subtree with the same completion timestamp
  bool undoComplete() => (completed == null) ? false : _undoComplete(completed!);

  /// update [leafsInSubTree] in the higher levels of the tree
  void updateLeafCount(int incLeafCount) {
    leafsInSubTree += incLeafCount;
    parent?.updateLeafCount(incLeafCount);
  }

  void notifyModification() => tree?.modify();

  int get numberOfChildren => _children.length;

  Iterable<TreeNode> get children => _children;

  /// return a BitonicSequence of the parents children if the node is the root it will be a BitonicSequence of the root
  BitonicSequence get bitonicSiblings => BitonicSequence.ofSiblings(this);
}

/// A sequence which ascends first and then descends
/// used in the visualization so the most important tasks are in the middle of the list
class BitonicSequence with ListMixin<TreeNode> {
  // can't use the add implementation provided by the ListMixin since it only works on nullable types
  final List<TreeNode> _store = [];

  BitonicSequence([TreeNode? center]) {
    if (center != null) _store.add(center);
  }

  factory BitonicSequence.ofSiblings(TreeNode node) {
    SplayTreeSet<TreeNode> siblings;
    if (node.parent == null) {
      return BitonicSequence(node);
    }
    siblings = node.parent!._children;
    return BitonicSequence.fromIterable(siblings);
  }

  factory BitonicSequence.fromIterable(Iterable<TreeNode> nodes) {
    BitonicSequence res = BitonicSequence();
    for (TreeNode node in nodes) {
      (res._store.length % 2 == 1)
          ? res._store.insert(0, node)
          : res._store.add(node);
    }
    return res;
  }

  @override
  int get length => _store.length;

  @override
  TreeNode operator [](int index) {
    return _store[index];
  }

  @override
  void operator []=(int index, TreeNode value) {
    throw UnsupportedError("The bitonicSequence is read only!");
  }

  @override
  set length(int newLength) {
    throw UnsupportedError("The bitonicSequence is read only!");
  }

  @override
  bool get isEmpty => _store.isEmpty;

  @override
  bool get isNotEmpty => _store.isNotEmpty;

  Iterable<TreeNode> get iter => _store;

  @override
  int indexOf(Object? element, [int start = 0]) =>
      (element is TreeNode) ? _store.indexOf(element, start) : -1;

  // override add and addAll because the mixin default implementation
  // is not very efficient, so just forward it to the _store
  @override
  void add(TreeNode element) {
    _store.add(element);
  }

  @override
  void addAll(Iterable<TreeNode> iterable) {
    _store.addAll(iterable);
  }

  /// return a list of heights we the center of the nodes are starting at the height of the center of the first node
  List<double> get equallyDistributedHeights => [
        for (int i = length - 1; i >= 0; i--)
          AppConstants.paddedNodeCenter + AppConstants.paddedNodeHeight * i
      ];

  double get height => length * AppConstants.paddedNodeHeight;
}

/// Class representing the TreeDo task tree start with one Node called 'Root'
class Tree {
  /// the root node
  TreeNode root;

  int modified;

  /// Set with all nodes for fast lookup of specific nodes
  final HashSet<TreeNode> _taskSet = HashSet();

  /// Constructor for a new Tree
  Tree()
      : root = TreeNode('Root', Priority.medium),
        modified = DateTime.now().millisecondsSinceEpoch {
    _taskSet.add(root);
  }

  /// Constructs new tree from a root TreeNode
  /// Tree needs to be valid (correct parent etc)
  Tree.fromRootNode(this.root, this.modified) {
    _buildTaskSet(root);
  }

  factory Tree.jsonConstructor(dynamic json) {
    return Tree.fromRootNode(TreeNode.fromJson(json["root"]), json["modified"] as int);
  }

  String toJson() {
    Map<String, dynamic> jsonTree = {
      "modified": modified,
      "root": root.toJson()
    };

    return const JsonEncoder.withIndent("    ").convert(jsonTree);
  }

  /// find the node with the [nodeId]
  TreeNode? findNodeWithId(String nodeId) =>
      _taskSet.lookup(TreeNode.comparisonNode(nodeId));

  /// adds a valid child to a TreeNode
  ///
  /// Only works if the child is valid and has no children;
  ///
  /// takes [nodeId] which specifies to which TreeNode the child should be added
  /// takes the [child] which will be added
  ///
  /// returns true if the [child] has successfully been added to the TreeNode's
  /// children as well as to the [_taskSet] lookup hashset
  bool addChildToNode(String nodeId, TreeNode child) {
    TreeNode? targetNode = findNodeWithId(nodeId);

    if (child._children.isNotEmpty) {
      return false;
    }

    // addChild() sets the parent
    if (targetNode == null ||
        !_taskSet.add(child) ||
        !targetNode._addChild(child)) {
      // this means we didnt find anything or failed adding it the sets
      _taskSet.remove(child);
      return false;
    }
    child.tree = this;
    modify();
    return true;
  }
  
  /// removes the child from the tree
  ///
  /// takes a [node] which will be removed
  ///
  /// return true if successful
  bool removeChild(TreeNode node) {
    // if the node is the root you cant delete that.
    if (node.parent == null || !_taskSet.contains(node)) {
      return false;
    }
    modify();
    return node.parent!._removeChild(node) && _taskSet.remove(node);
  }

  void _buildTaskSet(TreeNode subtree) {
    for (var child in subtree._children) {
      _buildTaskSet(child);
    }
    _taskSet.add(subtree);
    subtree.tree = this;
  }

  void modify() => modified = DateTime.now().millisecondsSinceEpoch;

  bool removeExpiredCompletedTasks() {
    bool changed = false;
    int yesterdayTimestamp = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    List<TreeNode> deletionCandidates = _collectDeletionCandidates(root, yesterdayTimestamp);
    for (var element in deletionCandidates) {
      changed |= removeChild(element);
    }
    return changed;
  }

  List<TreeNode> _collectDeletionCandidates(TreeNode node, int yesterdayTimestamp) {
    if (node.completed != null && node.completed! <= yesterdayTimestamp) {
      return [node];
    }
    List<TreeNode> res = [];
    for (var child in node.children) {
      res.addAll(_collectDeletionCandidates(child, yesterdayTimestamp));
    }
    return res;
  }
}
