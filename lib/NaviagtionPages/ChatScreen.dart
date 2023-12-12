import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/AppScreens/ProfileScreen.dart';
import 'package:chat_app/NaviagtionPages/ChattingScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String uid;

  ChatScreen({required this.uid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ImageProvider<Object>? currentUserImageUrl;
  String senderId = '';
  var receiverId;
  final searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> searchResults = [];
  bool showSearchResults = false;
  List<Map<String, dynamic>> followedUsersList = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentUserImage();
    retrieveFollowedUsers();
  }

  Future<void> fetchCurrentUserImage() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Users')
          .doc(widget.uid)
          .get();

      final userData = snapshot.data();
      if (userData != null) {
        setState(() {
          currentUserImageUrl = userData['ImageUrl'] != null
              ? NetworkImage(userData['ImageUrl'])
              : AssetImage('assets/default_avatar.png')
                  as ImageProvider<Object>?;
        });
      }
    } catch (e) {
      print('Error fetching user image: $e');
    }
  }

  Future<void> searchUsers(String searchText) async {
    final trimmedText = searchText.trim();

    if (trimmedText.isEmpty) {
      setState(() {
        searchResults.clear();
        showSearchResults = false;
      });
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('Users')
        .where('Name', isGreaterThanOrEqualTo: trimmedText)
        .where('Name', isLessThan: trimmedText + 'z')
        .get();

    setState(() {
      searchResults = snapshot.docs;
      showSearchResults = true;
    });
  }

  // Inside _ChatScreenState class

  Future<void> retrieveFollowedUsers() async {
    try {
      var followedUsersSnapshot = await FirebaseFirestore.instance
          .collection('FollowRequests')
          .where('status', isEqualTo: 'accepted')
          .where('senderId', isEqualTo: widget.uid)
          .get();

      var followedByCurrentUserSnapshot = await FirebaseFirestore.instance
          .collection('FollowRequests')
          .where('status', isEqualTo: 'accepted')
          .where('receiverId', isEqualTo: widget.uid)
          .get();

      List<Map<String, dynamic>> usersDetails = [];
      // Variable to store senderId

      // Process users followed by the current user
      for (var doc in followedUsersSnapshot.docs) {
        senderId = doc['senderId'] as String; // Extract senderId here
        receiverId = doc['receiverId'] as String;
        var userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(receiverId)
            .get();

        var userData = userSnapshot.data();
        if (userData != null) {
          usersDetails.add({
            'userId': receiverId,
            'userData': userData,
            'relation': 'followedByCurrentUser',
          });
        }
      }

      // Process users following the current user
      for (var doc in followedByCurrentUserSnapshot.docs) {
        var senderId = doc['senderId'] as String;
        var userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(senderId)
            .get();

        var userData = userSnapshot.data();
        if (userData != null) {
          usersDetails.add({
            'userId': senderId,
            'userData': userData,
            'relation': 'followingCurrentUser',
          });
        }
      }

      setState(() {
        followedUsersList = usersDetails;
      });

      // Now you have the senderId stored in the variable 'senderId'
      print('Sender ID: $senderId');
    } catch (e) {
      print('Error retrieving followed users: $e');
    }
  }

  Future<void> sendFollowRequest(String senderId, String receiverId) async {
    try {
      var requestSnapshot = await FirebaseFirestore.instance
          .collection('FollowRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        await requestSnapshot.docs.first.reference
            .update({'status': 'accepted'});
      } else {
        await FirebaseFirestore.instance.collection('FollowRequests').add({
          'senderId': senderId,
          'receiverId': receiverId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow Request sent'),
        ),
      );
      print('Follow request sent!');
    } catch (e) {
      print('Error sending follow request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showSearchResults = false;
        });
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(201, 44, 50, 63),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Row(
                children: [
                  Text(
                    'Chats',
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                  SizedBox(width: 220),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: widget.uid),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: currentUserImageUrl ??
                          AssetImage('assets/default_avatar.png')
                              as ImageProvider<Object>?,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Column(
                  children: [
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
                        onChanged: (value) {
                          searchUsers(value);
                        },
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
                    if (showSearchResults && searchResults.isNotEmpty)
                      Container(
                        height: 200, // Set your desired height
                        width: 350,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.black),
                          color: Colors.white12,
                        ),
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            var userData = searchResults[index].data();
                            if (userData != null &&
                                userData is Map<String, dynamic>) {
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundImage:
                                      NetworkImage(userData['ImageUrl']),
                                ),
                                title: Text(
                                  userData['Name'] ?? '',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  userData['About'] ?? '',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultsScreen(
                                        userData: userData,
                                        followCallback: () {
                                          sendFollowRequest(widget.uid,
                                              searchResults[index].id);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return ListTile(
                                title: Text('User data is null'),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: followedUsersList.length,
                itemBuilder: (context, index) {
                  var userData = followedUsersList[index]['userData']
                      as Map<String, dynamic>;
                  var relation = followedUsersList[index]['relation'] as String;

                  var tappedUserId =
                      followedUsersList[index]['userId'] as String;

                  var userIdToPass = widget.uid == tappedUserId
                      ? followedUsersList[index]['receiverId'] as String
                      : tappedUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(userData['ImageUrl']),
                    ),
                    title: Text(
                      userData['Name'] ?? '',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      userData['About'] ?? '',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (relation == 'followingCurrentUser') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChattingScreen(
                              uid: widget.uid,
                              receiverId: userIdToPass,
                            ),
                          ),
                        );
                      } else if (relation != 'followingCurrentUser') {
                        // Handle this case accordingly
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChattingScreen(
                              uid: widget.uid,
                              receiverId: receiverId,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback followCallback;

  SearchResultsScreen({required this.userData, required this.followCallback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: userData['ImageUrl'] != null
                    ? NetworkImage(userData['ImageUrl'])
                    : AssetImage('assets/default_avatar.png')
                        as ImageProvider<Object>?,
              ),
              SizedBox(height: 20),
              Text(
                userData['Name'] ?? '',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                userData['Phone'] ?? '',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                userData['About'] ?? '',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: followCallback,
                child: Text('Follow'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
