import 'dart:collection';

import 'package:test/test.dart';
import 'package:tree_do/tree.dart';
import 'package:collection/collection.dart';

void main () {

  /*
  Target tree:

    root
    ├── L1_1
    │   └── L2_1
    │       ├── L3_1
    │       └── L3_2
    └── L1_2
        ├── L2_2
        ├── L2_3
        └── L2_4
   */


  // level 1 Nodes
  TreeNode l1_1 = TreeNode("L1_1", Priority.medium);
  TreeNode l1_2 = TreeNode("L1_2", Priority.medium);
  HashSet<TreeNode> l1 = HashSet.of([l1_1, l1_2]);


  // level 2 nodes
  TreeNode l2_1 = TreeNode("L2_1", Priority.medium);
  TreeNode l2_2 = TreeNode("L2_2", Priority.medium);
  TreeNode l2_3 = TreeNode("L2_3", Priority.medium);
  TreeNode l2_4 = TreeNode("L2_4", Priority.medium);
  HashSet<TreeNode> l2 = HashSet.of([l2_1, l2_2, l2_3, l2_4]);

  // level 3 nodes
  TreeNode l3_1 = TreeNode("L3_1", Priority.medium);
  TreeNode l3_2 = TreeNode("L3_2", Priority.medium);
  HashSet<TreeNode> l3 = HashSet.of([l3_1, l3_2]);


  Tree testTree = Tree();

  if (
    !testTree.addChildToNode(testTree.root.id, l1_1) ||
    !testTree.addChildToNode(testTree.root.id, l1_2) ||
    !testTree.addChildToNode(l1_1.id, l2_1) ||
    !testTree.addChildToNode(l1_2.id, l2_2) ||
    !testTree.addChildToNode(l1_2.id, l2_3) ||
    !testTree.addChildToNode(l1_2.id, l2_4) ||
    !testTree.addChildToNode(l2_1.id, l3_1) ||
    !testTree.addChildToNode(l2_1.id, l3_2)
  ) {
    fail("Error adding Children!");
  }


  group('Tree Insertion test', () {
    test('Test root level', () {
      expect(testTree.getLevel(0), HashSet.of([testTree.root]));
    });
    test('Test level one', () {
      expect(testTree.getLevel(1), l1);
    });
    test('Test level two', () {
      var tmp = List<TreeNode>.from(testTree.getLevel(2));
      expect(testTree.getLevel(2), l2);
    });
    test('Test level three', () {
      var tmp = List<TreeNode>.from(testTree.getLevel(2));
      List<TreeNode>.from(testTree.getLevel(3));
      expect(testTree.getLevel(3), l3);
    });

  });


}

