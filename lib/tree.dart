import 'dart:collection';
import 'package:uuid/uuid.dart';

enum Priority { low, medium, high }

/// A class representing a task (leaf) or task group (node)
///
/// Each node has a 128 bit [_id], [name], a [_completed] state
class TreeNode {
  // 128 bit random number so we can ignore collisions
  Uuid _id = const Uuid();
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
  HashSet<TreeNode> children = HashSet();

  /// Constructor for TreeNodes
  ///
  /// takes a [name] and a [priority]
  /// a [description] can also be supplied
  TreeNode(this.name, this.priority, [this.description])
      : modified = DateTime.now().microsecondsSinceEpoch;

  /// A constructor for creating nodes only used for comparisons
  /// against other nodes
  ///
  /// takes just the [_id]
  TreeNode.comparisonNode(this._id)
      : priority = Priority.medium,
        modified = 0;

  // Override == and hashCode in order to store this in a hash set
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNode && runtimeType == other.runtimeType && _id == other._id;

  // just use the id's hash since we assume the uuids dont collide
  @override
  int get hashCode => _id.hashCode;

  /// adds TreeNodes to this TreeNode's [children] and set the [parent]
  ///
  /// takes a [child]
  ///
  /// return true if successful
  bool addChild(TreeNode child) {
    child.parent = this;
    return children.add(child);
  }
}

/// Class representing the TreeDo task tree start with one Node called 'Root'
class Tree {
  /// the root node
  TreeNode root;
  /// Set with all nodes for fast lookup of specific nodes
  HashSet<TreeNode> _allNodes = HashSet();

  /// Constructor for a new Tree
  Tree() : root = TreeNode('Root', Priority.medium) {
    _allNodes.add(root);
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
        tmp.add(currentNode);
      }
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
  TreeNode? findNodeWithId(Uuid nodeId) => _allNodes.lookup(TreeNode.comparisonNode(nodeId));

  /// adds a child to a TreeNode
  ///
  /// takes [nodeId] which specifies to which TreeNode the child should be added
  /// takes the [child] which will be added
  ///
  /// returns true if the [child] has successfully been added to the TreeNode's
  /// children as well as to the [_allNodes] lookup hashset
  bool addChildToNode(Uuid nodeId, TreeNode child) {
    TreeNode? targetNode = findNodeWithId(nodeId);

    if (targetNode == null ||
        !_allNodes.add(child) ||
        !targetNode.addChild(child)) {
      // this means we didnt find anything or failed adding it the sets
      _allNodes.remove(child);
      return false;
    }

    return true;
  }
}
