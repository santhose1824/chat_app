import 'package:chat_app/AppScreens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterHomeScreen extends StatefulWidget {
  final uid;
  RegisterHomeScreen({required this.uid});

  @override
  State<RegisterHomeScreen> createState() => _RegisterHomeScreenState();
}

class _RegisterHomeScreenState extends State<RegisterHomeScreen> {
  final searchController = TextEditingController();
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');
  Map<String, bool> followingStatus = {};

  void sendFollowRequest(String senderId, String receiverId) async {
    try {
      await FirebaseFirestore.instance.collection('FollowRequests').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending', // Initial status can be 'pending'
        'timestamp':
            FieldValue.serverTimestamp(), // Optionally, include a timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow Request sent'),
        ),
      );
      print('Follow request sent!');
    } catch (e) {
      print('Error sending follow request: $e');
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 250),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage(
                                    uid: widget.uid,
                                  )),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 50,
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.black),
                      color: Colors.white12,
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                        hintText: 'Search....',
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: users.snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      return Column(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          return buildUserCard(data);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserCard(Map<String, dynamic> userData) {
    if (userData['uid'] == widget.uid) {
      return SizedBox();
    }

    bool isFollowing = followingStatus.containsKey(userData['uid'])
        ? followingStatus[userData['uid']]!
        : false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(userData['ImageUrl'] ?? ''),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['Name'] ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        SizedBox(height: 5),
                        Text(
                          userData['About'] ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isFollowing
                        ? null
                        : () {
                            setState(() {
                              followingStatus[userData['uid']] = true;
                            });
                            sendFollowRequest(
                              widget.uid, // Sender's ID
                              userData['uid'], // Receiver's ID
                            );
                          },
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
