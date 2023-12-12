import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class ChattingScreen extends StatefulWidget {
  final String uid;
  final String receiverId;

  ChattingScreen({required this.uid, required this.receiverId});

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String _selectedFilePath = '';
  var userData;
  @override
  void initState() {
    getCurrentUserProfilePic();
    // TODO: implement initState
    super.initState();
  }

  // Function to send a message
  void sendMessage(String message, String fileType, String filePath) async {
    // Create message data
    Map<String, dynamic> messageData = {
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': widget.uid, // Include sender's ID in message data
    };

    // Upload file if fileType is not 'file' and filePath is not empty
    if (fileType != 'file' && filePath.isNotEmpty) {
      // Upload file to Firebase Storage
      firebase_storage.Reference storageReference =
          firebase_storage.FirebaseStorage.instance.ref().child(
                'uploads/${DateTime.now().millisecondsSinceEpoch}',
              );
      firebase_storage.UploadTask uploadTask =
          storageReference.putFile(File(filePath));

      // Wait for file upload completion
      await uploadTask.whenComplete(() async {
        String fileUrl = await storageReference.getDownloadURL();
        messageData.addAll({'fileType': fileType, 'fileUrl': fileUrl});
      });
    }

    // Add message data to Firestore
    FirebaseFirestore.instance
        .collection('Chat')
        .doc(widget.uid)
        .collection(widget.receiverId)
        .add(messageData);

    // Send a notification to the receiver
    if (fileType != 'file') {
      String notificationMessage = message.isNotEmpty ? message : 'Sent a file';
      sendNotification(widget.receiverId, notificationMessage);
    }
  }

  // Function to send a notification
  void sendNotification(String receiverId, String notificationMessage) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'basic_channel',
        title: 'New Message!',
        body: notificationMessage,
      ),
    );
  }

  // Function to open file picker
  void openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'ppt',
        'pptx',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx'
      ],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFilePath = result.files.first.path ?? '';
      });
    }
  }

  // Define a variable to store the current user's profile picture URL
  String currentUserProfilePic = '';

// Function to retrieve the current user's profile picture
  void getCurrentUserProfilePic() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.uid)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        currentUserProfilePic = userData['ImageUrl'] ?? '';
        // Update the variable with the profile picture URL
        setState(() {
          currentUserProfilePic = currentUserProfilePic;
        });
      }
    } catch (e) {
      print('Error fetching user profile pic: $e');
    }
  }

// Call this function to fetch the current user's profile picture

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromARGB(201, 44, 50, 63),
        body: Column(
          children: [
            // StreamBuilder to display receiver's information
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(widget.receiverId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                userData = snapshot.data!.data() as Map<String, dynamic>;

                return Center(
                  child: Container(
                    color: Colors.white12,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(userData['ImageUrl'] ?? ''),
                      ),
                      title: Text(
                        userData['Name'] ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chat')
                    .doc(widget.uid)
                    .collection(widget.receiverId)
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  List<DocumentSnapshot> senderMessages = snapshot.data!.docs;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Chat')
                        .doc(widget.receiverId)
                        .collection(widget.uid)
                        .orderBy('timestamp')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> receiverSnapshot) {
                      if (receiverSnapshot.hasError) {
                        return Text('Error: ${receiverSnapshot.error}');
                      }

                      if (receiverSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      List<DocumentSnapshot> receiverMessages =
                          receiverSnapshot.data!.docs;

                      // Combine sender and receiver messages into a single list
                      List<DocumentSnapshot> allMessages = [];
                      allMessages.addAll(senderMessages);
                      allMessages.addAll(receiverMessages);

                      // Filter out messages with null timestamps
                      allMessages = allMessages
                          .where((message) => message['timestamp'] != null)
                          .toList();

                      // Sort combined messages by timestamp
                      allMessages.sort((a, b) {
                        Timestamp aTimestamp = a['timestamp'] as Timestamp;
                        Timestamp bTimestamp = b['timestamp'] as Timestamp;

                        if (aTimestamp != null && bTimestamp != null) {
                          return aTimestamp.compareTo(bTimestamp);
                        } else {
                          return 0;
                        }
                      });

                      return ListView.builder(
                        itemCount: allMessages.length,
                        reverse:
                            true, // Set reverse to true to display messages in reverse order
                        itemBuilder: (BuildContext context, int index) {
                          Map<String, dynamic> data =
                              allMessages[allMessages.length - index - 1].data()
                                  as Map<String, dynamic>;
                          bool isSentByCurrentUser =
                              data['senderId'] == widget.uid;

                          Widget messageWidget = Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
                            child: Row(
                                mainAxisAlignment: isSentByCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isSentByCurrentUser)
                                    CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(userData['ImageUrl']),
                                    ),
                                  SizedBox(width: 5.0),
                                  Container(
                                    padding: EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: isSentByCurrentUser
                                          ? Colors.blue
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      data['message'],
                                      style: TextStyle(
                                        color: isSentByCurrentUser
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  if (isSentByCurrentUser)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        currentUserProfilePic,
                                      ),
                                    ),
                                ]),
                          );

                          return Align(
                            alignment: isSentByCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: messageWidget,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        fillColor: Colors.white12,
                        filled: true,
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.attach_file),
                          onPressed: openFilePicker,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (_selectedFilePath.isNotEmpty) {
                          sendMessage('', 'file', _selectedFilePath);
                          setState(() {
                            _selectedFilePath = '';
                          });
                        } else {
                          sendMessage(_textEditingController.text, 'text', '');
                          _textEditingController.clear();
                        }
                      },
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
