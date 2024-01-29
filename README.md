# TreeDo

TreeDo is a todo list manager flutter app that uses a tree structure to organize tasks.

For local testing, a flask server and a postgresql database were created. The app sends http requests to fetch/update the tree in the database. The corresponding repository can be found [here](https://github.com/ninamaria31/TreeDoServer).

Adding, deleting and editing are gesture based. 

Adding: Long tap on a node
Editing/deleting: short tap on a node

To navigate the tree, swipe the nodes to the left or right.

An overview mode is also available when rotating the phone. 

