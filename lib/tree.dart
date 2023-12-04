import 'dart:collection';
import 'package:uuid/uuid.dart';

enum Priority { low, medium, high }

/// A class representing a task (leaf) or task group (node)
///
/// Each node has a 128 bit [id], [name], a [_completed] state
class TreeNode {
  // 128 bit random number so we can ignore collisions
  String id;
  bool _completed = false;

  /// backlink to the Parent for faster lookup
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
  HashSet<TreeNode> children;

  /// Constructor for TreeNodes
  ///
  /// takes a [name] and a [priority]
  /// a [description] can also be supplied
  TreeNode(this.name, this.priority, [this.description])
      : modified = DateTime.now().microsecondsSinceEpoch,
        children = HashSet(),
        id = const Uuid().v4();

  /// Constructs TreeNode that have already existed before
  ///
  /// The immediate children are properly added using addChild
  /// but the grandchildren not
  TreeNode.existingNode(this.id, this.name, this.description, this.priority,
      this._completed, this.modified, this.deleted, Iterable<TreeNode> childTasks)
      : children = HashSet() {
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
      //children = json['children'].map((child) => TreeNode.fromJson(child)).toList();
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
        children = HashSet();

  // Override == and hashCode in order to store this in a hash set
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNode && runtimeType == other.runtimeType && id == other.id;

  // just use the id's hash since we assume the uuids dont collide
  @override
  int get hashCode => id.hashCode;

  /// adds TreeNodes to this TreeNode's [children] and set the [parent]
  ///
  /// takes a [child]
  ///
  /// return true if successful
  bool addChild(TreeNode child) {
    child.parent = this;
    return children.add(child);
  }

  static String? convertToNullableString(String input) {
    return (input == "Null") ? null : input;
  }

  static int? convertToNullableInt(String input) {
    return (input == "Null") ? null : int.parse(input);
  }
}

/// Class representing the TreeDo task tree start with one Node called 'Root'
class Tree {
  /// the root node
  TreeNode root;

  /// Set with all nodes for fast lookup of specific nodes
  HashSet<TreeNode> _taskSet = HashSet();

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
  /// return a hashset containing TreeNodes
  HashSet<TreeNode> getLevel(int level) {
    HashSet<TreeNode> tmp = HashSet();
    // level equals zero so we return the root
    if (level == 0) {
      tmp.add(root);
      return tmp;
    }

    // Initialize the traversal Queue with the root's children
    Queue<TreeNode> traversalQueue = Queue.from(root.children);

    // Traverse all levels below our target level
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      // add all nodes of the next level to the temporary storage
      for (TreeNode currentNode in traversalQueue) {
        tmp.addAll(currentNode.children);
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

    if (child.children.isNotEmpty) {
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
    for (var child in subtree.children) {
      buildTaskSet(child);
    }
    _taskSet.add(subtree);
  }
}
