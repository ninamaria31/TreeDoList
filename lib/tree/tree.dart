import 'dart:collection';
import 'package:uuid/uuid.dart';

enum Priority { low, medium, high }

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

  /// Hashset of the Trees children
  HashSet<TreeNode> _children;
  /// number of leaves in the subtree (used by the visualization)
  int leafsInSubTree;

  /// Constructor for TreeNodes
  ///
  /// takes a [name] and a [priority]
  /// a [description] can also be supplied
  TreeNode(this.name, this.priority, [this.description])
      : modified = DateTime.now().microsecondsSinceEpoch,
        _children = HashSet(),
        id = const Uuid().v4(),
        leafsInSubTree = 1;

  /// Constructs TreeNode that have already existed before
  ///
  /// The immediate children are properly added using addChild
  /// but the grandchildren not
  /// Children need to be valid
  TreeNode.existingNode(this.id, this.name, this.description, this.priority,
      this._completed, this.modified, this.deleted, Iterable<TreeNode> childTasks)
      : _children = HashSet(),
        leafsInSubTree = 1 {
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
    List<TreeNode> children = [];
    if (json['children'] != null) {
      for (var child in json['children']) {
        children.add(TreeNode.fromJson(child));
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
      children
    );
  }

  /// A constructor for creating nodes only used for comparisons
  /// against other nodes
  ///
  /// takes just the [id]
  TreeNode.comparisonNode(this.id)
      : priority = Priority.medium,
        modified = 0,
        _children = HashSet(),
        leafsInSubTree = 1;

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
    int leafIncrease = (_children.isEmpty) ? child.leafsInSubTree - 1 : child.leafsInSubTree;
    if(!_children.add(child)) {
      return false;
    }
    child.parent = this;

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

  int get numberChildren => _children.length;

  Iterable<TreeNode> get children => _children;
}

/// Class representing the TreeDo task tree start with one Node called 'Root'
class Tree {
  /// the root node
  TreeNode root;

  /// Set with all nodes for fast lookup of specific nodes
  final HashSet<TreeNode> _taskSet = HashSet();

  /// Constructor for a new Tree
  Tree() : root = TreeNode('Root', Priority.medium) {
    _taskSet.add(root);
  }

  /// Constructs new tree from a root TreeNode
  /// Tree needs to be valid (correct parent etc)
  Tree.fromRootNode(this.root) {
    buildTaskSet(root);
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
    HashSet<TreeNode> tmp = HashSet();
    // level equals zero so we return the root
    if (level == 0) {
      tmp.add(root);
      return tmp;
    }

    // Initialize the traversal Queue with the root's children
    Queue<TreeNode> traversalQueue = Queue.from(root._children);

    // Traverse all levels below our target level
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      // add all nodes of the next level to the temporary storage
      for (TreeNode currentNode in traversalQueue) {
        tmp.addAll(currentNode._children);
      }
      traversalQueue.clear();
      // add the nodes of the next level to the traversalQueue
      traversalQueue.addAll(tmp);
      // clear the temporary node storage
      tmp.clear();
    }
    // now the traversalQueue contains the the nodes of the target level
    tmp.addAll(traversalQueue);
    return tmp;
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
    return true;
  }

  void buildTaskSet(TreeNode subtree) {
    for (var child in subtree._children) {
      buildTaskSet(child);
    }
    _taskSet.add(subtree);
  }
}
