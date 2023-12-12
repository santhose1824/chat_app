import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Replace with your welcome page path

class ProfileScreen extends StatefulWidget {
  final uid;
  ProfileScreen({this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? imageUrl;
  String? about;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Users')
          .doc(widget.uid)
          .get();

      final userData = snapshot.data();
      if (userData != null) {
        setState(() {
          name = userData['Name'];
          imageUrl = userData['ImageUrl'];
          about = userData['About'];
          phoneNumber = userData['Phone'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid'); // Clear stored uid
    // Navigate to WelcomePage after logout
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 100,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!) as ImageProvider<Object>
                    : AssetImage('assets/default_avatar.png'),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Name: ${name ?? ''}',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Phone: ${phoneNumber ?? ''}',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'About: ${about ?? ''}',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: Container(
                width: 300,
                child: ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(primary: Colors.white),
                  child: Center(
                    child: Text(
                      'Logout',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
