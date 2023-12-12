import 'dart:io';

import 'package:chat_app/AppScreens/RegisterHomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePicAndAboutPage extends StatefulWidget {
  final uid;
  ProfilePicAndAboutPage({required this.uid});

  @override
  State<ProfilePicAndAboutPage> createState() => _ProfilePicAndAboutPageState();
}

class _ProfilePicAndAboutPageState extends State<ProfilePicAndAboutPage> {
  File? _image;
  final aboutController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadPostintoFirebase() async {
    if (_image == null) {
      // Handle no image selected
      return;
    }

    try {
      final Reference storageReference =
          FirebaseStorage.instance.ref().child('Users/${widget.uid}.jpg');
      await storageReference.putFile(_image!);

      final String imageUrl = await storageReference.getDownloadURL();

      // Fetch the existing document data
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.uid)
          .get();

      // Check if the document data exists and is a Map
      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> existingData =
            userDoc.data()! as Map<String, dynamic>;

        // Merge existing data with new data and update the document
        existingData['uid'] = widget.uid;
        existingData['ImageUrl'] = imageUrl;
        existingData['About'] = aboutController.text;

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.uid)
            .set(existingData);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RegisterHomeScreen(
                      uid: widget.uid,
                    )));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post uploaded successfully.'),
          ),
        );
      } else {
        // Handle if the document doesn't exist or data is not in the expected format
        print('Document does not exist or has unexpected data format');
      }
    } catch (error) {
      // Handle errors
      print('Error uploading post: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  foregroundColor: Colors.black,
                  radius: 80,
                  child: _image != null
                      ? ClipOval(
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            width: 160,
                            height: 160,
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.camera_alt),
                          iconSize: 50,
                          onPressed: _pickImage,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _image != null
                      ? CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _image = null;
                              });
                            },
                          ),
                        )
                      : SizedBox(),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: aboutController,
              decoration: InputDecoration(
                hintText: 'Enter the About',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: 300,
            child: ElevatedButton(
              onPressed: () async {
                await _uploadPostintoFirebase();
              },
              style: ElevatedButton.styleFrom(primary: Colors.white),
              child: Center(
                child: Text(
                  'Next',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
