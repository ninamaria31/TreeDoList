import 'dart:collection';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  bool _completed = false;
  DateTime? dueDate;
  int _level;

  /// backlink to the Parent for ease of use
  TreeNode? parent;

  /// Name of the task our task group
  String name = '';

  /// Optional description of the task (group)
  String? description;

  /// the priority
  Priority priority;

  /// Timestamp since the last modification
  /// (in microseconds since January 1, 1970, 00:00:00 UTC)
  int modified;

  /// Timestamp since the deletion
  /// (in microseconds since January 1, 1970, 00:00:00 UTC)
  int? deleted;

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
    return (lhs.priority == rhs.priority) ? lhs.id.compareTo(rhs.id) : lhs.priority.index.compareTo(rhs.priority.index);
  };
  /// Constructor for TreeNodes
  ///
  /// takes a [name] and a [priority]
  /// a [description] can also be supplied
  TreeNode(this.name, this.priority, {this.description, this.dueDate})
      : modified = DateTime.now().microsecondsSinceEpoch,
        _children = SplayTreeSet(treeNodeComparator),
        id = const Uuid().v4(),
        leafsInSubTree = 1,
        _level = 0;

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
      this._completed,
      this.modified,
      this.deleted,
      this.dueDate,
      Iterable<TreeNode> childTasks)
      : _children = SplayTreeSet(treeNodeComparator),
        leafsInSubTree = 1,
        _level = 0{
    for (var child in childTasks) {
      addChild(child);
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
        json['completed'] as bool,
        json['modified'] as int,
        json['modified'] as int?,
        DateTime.tryParse(json['dueDate'] ?? ''),
        tmpChildren);
  }

  /// A constructor for creating nodes only used for comparisons
  /// against other nodes
  ///
  /// takes just the [id]
  TreeNode.comparisonNode(this.id)
      : priority = Priority.medium,
        modified = 0,
        _children = SplayTreeSet(treeNodeComparator),
        leafsInSubTree = 1,
        _level = 0;

  // Override == and hashCode in order to store this in a hash set
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNode && runtimeType == other.runtimeType && id == other.id;

  // just use the id's hash since we assume the uuids dont collide
  @override
  int get hashCode => id.hashCode;

  /// adds TreeNodes to this TreeNode's [_children] and set the [parent]
  ///
  /// takes a [child]
  /// also updates [leafsInSubTree] in its parent if necessary
  ///
  /// return true if successful
  bool addChild(TreeNode child) {
    // if we used to be a leaf we need to take that into account
    int leafIncrease =
        (_children.isEmpty) ? child.leafsInSubTree - 1 : child.leafsInSubTree;
    if (!_children.add(child)) {
      return false;
    }
    child.parent = this;
    child._level = _level + 1;

    // update our own leaf count
    if (leafIncrease != 0) {
      updateLeafCount(leafIncrease);
    }
    return true;
  }

  /// update [leafsInSubTree] in the higher levels of the tree
  void updateLeafCount(int incLeafCount) {
    leafsInSubTree += incLeafCount;
    parent?.updateLeafCount(incLeafCount);
  }

  int get numberOfChildren => _children.length;

  Iterable<TreeNode> get children => _children;

  /// return the children split into two balanced halves [BitonicSequence.top] is ascending
  /// and [BitonicSequence.bottom] is descending
  /// used by the regular tree view
  BitonicSequence? get bitonicSiblings => BitonicSequence.fromNode(this);
}

/// A list of TreeNodes split into three parts: a [center], a [top] and [bottom].
/// [top] UNION {[center]} UNION [bottom] form a bitonic (first ascending then descending) sequence
class BitonicSequence with ListMixin<TreeNode> {
  final List<TreeNode> _store = [];

  BitonicSequence([TreeNode? center]) {
    if (center != null) _store.add(center);
  }

  factory BitonicSequence.fromNode(TreeNode node) {
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
      (res._store.length % 2 == 1) ? res._store.insert(0, node) : res._store.add(node);
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
}

/// Class representing the TreeDo task tree start with one Node called 'Root'
class Tree {
  /// the root node
  TreeNode root;

  /// Set with all nodes for fast lookup of specific nodes
  final HashSet<TreeNode> _taskSet = HashSet();

  /// Map of the layers
  late final Map<int, List<TreeNode>> _layers;

  /// Constructor for a new Tree
  Tree() : root = TreeNode('Root', Priority.medium){
    _layers = {0: [root]};
    _taskSet.add(root);
  }

  /// Constructs new tree from a root TreeNode
  /// Tree needs to be valid (correct parent etc)
  Tree.fromRootNode(this.root) {
    _layers = {0: [root]};
    buildTaskSet(root);
    buildLevels(root);
  }

  factory Tree.jsonConstructor(dynamic json) {
    return Tree.fromRootNode(TreeNode.fromJson(json));
  }

  /// gets all Nodes on one level
  ///
  /// takes a [level]
  ///
  /// return an iterable containing TreeNodes
  Iterable<TreeNode> getLevel(int level) {
    return _layers[level] ?? [];
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
        !targetNode.addChild(child)) {
      // this means we didnt find anything or failed adding it the sets
      _taskSet.remove(child);
      return false;
    }

    if(_layers[targetNode._level] == null){
      _layers[targetNode._level] = [child];
    } else {
      _layers[targetNode._level]?.add(child);
    }
    return true;
  }

  void buildTaskSet(TreeNode subtree) {
    for (var child in subtree._children) {
      buildTaskSet(child);
    }
    _taskSet.add(subtree);
  }

  SplayTreeSet<TreeNode> getLayerFromNode(TreeNode node) {
    return SplayTreeSet.from(getLevel(node._level), TreeNode.treeNodeComparator);
  }

  void buildLevels(TreeNode root) {
    List<TreeNode> tmp = [];

    // Initialize the traversal Queue with the root's children
    Queue<TreeNode> traversalQueue = Queue.from(root._children);

    // Traverse all levels
    for (var currentLevel = 1; traversalQueue.isNotEmpty; currentLevel++) {
      // add all nodes of the next level to the temporary storage
      for (TreeNode currentNode in traversalQueue) {
        currentNode._level = currentLevel;
        tmp.addAll(currentNode._children);
      }
      // traversalQueue contains the current level
      _layers[currentLevel] = traversalQueue.toList();

      traversalQueue.clear();
      // add the nodes of the next level to the traversalQueue
      traversalQueue.addAll(tmp);
      // clear the temporary node storage
      tmp.clear();
    }
  }
}
