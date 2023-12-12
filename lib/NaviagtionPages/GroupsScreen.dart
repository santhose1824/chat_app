import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Center(
        child: Text(
          'GroupsPage',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
