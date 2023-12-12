import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:chat_app/OTP/OTPVerification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestNotificationPermissions();
  }

  Future<void> requestNotificationPermissions() async {
    bool result = await AwesomeNotifications().isNotificationAllowed();
    if (!result) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  String generateOTP() {
    final random = Random();
    final otpDigits = 6;
    String otp = '';

    for (var i = 0; i < otpDigits; i++) {
      otp += random.nextInt(9).toString();
    }

    return otp;
  }

  void _showNotification(String otp) async {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: "basic_channel",
        title: "OTP Received",
        body: "Your OTP is $otp",
      ),
    );
  }

  Future<String> addUserDetails(String name, String phone) async {
    DocumentReference documentReference = await FirebaseFirestore.instance
        .collection('Users')
        .add({'Name': name, 'Phone': phone});

    String uid = documentReference.id;
    print(uid);
    return uid;
  }

  void navigateToOTPVerification(String uid) {
    String otp = generateOTP();
    _showNotification(otp);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerification(otp: otp, uid: uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chat App',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 50,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black),
                color: Colors.white12,
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.account_circle,
                    color: Colors.black,
                  ),
                  hintText: 'Enter the Name',
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 50,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black),
                color: Colors.white12,
              ),
              child: TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.phone,
                    color: Colors.black,
                  ),
                  hintText: 'Enter the Phone Number',
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 300,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      phoneController.text.isNotEmpty) {
                    String uid = await addUserDetails(
                      nameController.text.toString(),
                      phoneController.text.toString(),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registered Successfully'),
                      ),
                    );

                    navigateToOTPVerification(uid);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to register Yourself.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(primary: Colors.white),
                child: Center(
                  child: Text(
                    'Register',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an Account",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.green, fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
