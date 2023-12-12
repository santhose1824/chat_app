import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikesScreen extends StatefulWidget {
  final String currentUserUid;
  const LikesScreen({Key? key, required this.currentUserUid}) : super(key: key);

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> followRequestsStream;

  @override
  void initState() {
    super.initState();
    followRequestsStream = getFollowRequests();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFollowRequests() {
    return FirebaseFirestore.instance
        .collection('FollowRequests')
        .where('receiverId', isEqualTo: widget.currentUserUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  void acceptFollowRequest(String requestId, String senderId) {
    FirebaseFirestore.instance
        .collection('FollowRequests')
        .doc(requestId)
        .update({'status': 'accepted'}).then((value) {
      // Update sender's data (add receiver to the sender's following list)
      FirebaseFirestore.instance.collection('Users').doc(senderId).update({
        'Following': FieldValue.arrayUnion([widget.currentUserUid])
      });

      // Update receiver's data (add sender to the receiver's following list)
      FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUserUid)
          .update({
        'Following': FieldValue.arrayUnion([senderId])
      });

      print('Request accepted');
    }).catchError((error) {
      print('Error accepting request: $error');
    });
  }

  void declineFollowRequest(String requestId) {
    FirebaseFirestore.instance
        .collection('FollowRequests')
        .doc(requestId)
        .delete()
        .then((value) {
      print('Request declined');
    }).catchError((error) {
      print('Error declining request: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: followRequestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No follow requests',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var requestData = snapshot.data!.docs[index].data();
                String requestId = snapshot.data!.docs[index].id;
                String senderId = requestData['senderId']!;

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(senderId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Loading...'),
                      );
                    } else if (!userSnapshot.hasData) {
                      return ListTile(
                        title: Text('User not found'),
                      );
                    } else {
                      var senderData = userSnapshot.data!.data();
                      if (senderData != null &&
                          senderData is Map<String, dynamic>) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(senderData['ImageUrl'] ?? ''),
                          ),
                          title: Text(
                            senderData['Name'] ?? '',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'wants to follow you',
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  acceptFollowRequest(requestId, senderId);
                                },
                                child: Text('Accept'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  declineFollowRequest(requestId);
                                },
                                child: Text('Decline'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListTile(
                          title: Text('Sender data is null'),
                        );
                      }
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
