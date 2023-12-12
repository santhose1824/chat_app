import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StatusScreen extends StatefulWidget {
  final currentUserID;
  StatusScreen({this.currentUserID});

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  String currentUserID = '';

  @override
  void initState() {
    super.initState();
    currentUserID = widget.currentUserID; // Replace with actual user ID
  }

  String _selectedFilePath = '';
  Future<String?> openFilePicker() async {
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
      return result.files.first.path;
    }

    return null; // Return null if no file was selected
  }

  Future<void> uploadStatusVideo(File videoFile) async {
    try {
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('status_videos')
          .child('$currentUserID-${DateTime.now().millisecondsSinceEpoch}.mp4');

      final UploadTask uploadTask = storageReference.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;

      final String videoURL = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('StatusUpdates').add({
        'userID': currentUserID,
        'videoURL': videoURL,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error uploading status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStatusUpdates() async {
    try {
      List<String> followedUserIDs =
          []; // Retrieve the IDs of users the current user follows

      // Retrieve followed user IDs from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserID)
          .get();

      followedUserIDs = List<String>.from(userSnapshot.get('Following'));

      // Fetch status updates from followed users
      List<Map<String, dynamic>> statusUpdates = [];

      for (String followedUserID in followedUserIDs) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('StatusUpdates')
            .where('userID', isEqualTo: followedUserID)
            .orderBy('timestamp', descending: true)
            .get();

        querySnapshot.docs.forEach((doc) {
          statusUpdates.add({
            'userID': doc.get('userID'),
            'videoURL': doc.get('videoURL'),
            'timestamp': doc.get('timestamp'),
          });
        });
      }

      return statusUpdates;
    } catch (e) {
      print('Error fetching status updates: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchStatusUpdates(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No status updates available.'));
          } else {
            List<Map<String, dynamic>> statuses = snapshot.data!;

            return ListView.builder(
              itemCount: statuses.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> status = statuses[index];
                return ListTile(
                  title: Text('User ID: ${status['userID']}'),
                  subtitle: Text('Video URL: ${status['videoURL']}'),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? filePath = await openFilePicker();

          if (filePath != null) {
            File videoFile = File(filePath);

            await uploadStatusVideo(videoFile);
            setState(() {
              _selectedFilePath = ''; // Reset selected file path after upload
            });
          } else {
            print('No video file selected.');
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
