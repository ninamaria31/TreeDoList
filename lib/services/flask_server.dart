import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth.dart';
import '../tree/tree.dart';

Future<Tree> getTreeFromDB() async {
  var url = Uri.parse('http://10.0.2.2:5000/tree/${Auth().currentUser!.uid}');
  var response = await http.get(url);
  var tree = Tree.jsonConstructor(jsonDecode(response.body));
  if (tree.removeExpiredCompletedTasks()) {
    updateTreeDB(tree.toJson());
  }
  return tree;
}

Future<Tree> updateTreeDB(tree) async {
  var userId = Auth().currentUser?.uid;
  var jsonTree = jsonDecode(tree);
  var url = Uri.parse('http://10.0.2.2:5000/tree');
  var request_body = jsonEncode({"userId": userId, "tree": tree, "modified": jsonTree["modified"]});
  var response = await http.post(url, body: request_body, headers: {"Content-Type": "application/json"});
  return Tree.jsonConstructor(jsonDecode(response.body));
}