import 'package:flutter/material.dart';
import 'package:tree_do/auth.dart';
import 'package:tree_do/pages/home_page.dart';
import 'package:tree_do/pages/login_register_page.dart';


class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const TreePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
