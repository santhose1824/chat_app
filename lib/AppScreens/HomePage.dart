import 'package:chat_app/NaviagtionPages/ChatScreen.dart';
import 'package:chat_app/NaviagtionPages/GroupsScreen.dart';
import 'package:chat_app/NaviagtionPages/LikesPage.dart';
import 'package:chat_app/NaviagtionPages/StatusScreen.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final uid;
  HomePage({this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    print(widget.uid);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          ChatScreen(
            uid: widget.uid,
          ),
          LikesScreen(
            currentUserUid: widget.uid,
          ),
          StatusScreen(
            currentUserID: widget.uid,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color.fromARGB(201, 44, 50, 63),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Likes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.perm_identity),
            label: 'Status',
          ),
        ],
      ),
    );
  }
}
