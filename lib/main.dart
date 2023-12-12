import 'dart:math';

import 'package:chat_app/AppScreens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat_app/Login%20or%20Register/RegisterPage.dart';
import 'package:chat_app/OTP/OTPVerification(Login).dart';

void main() async {
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: "basic_channel",
        channelName: "Basic Notifications",
        channelDescription: "Notification channel for basic tests",
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromARGB(201, 44, 50, 63),
      ),
      home: FutureBuilder<bool>(
        future: checkLoggedInStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasData && snapshot.data!) {
              return HomePage(); // Navigate to HomePage if logged in
            } else {
              return WelcomePage(); // Show WelcomePage if not logged in
            }
          }
        },
      ),
    );
  }

  Future<bool> checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? uid = prefs.getString('uid');

    if (isLoggedIn && uid != null && uid.isNotEmpty) {
      print("Logged in UID: $uid");
      return true; // User is logged in
    } else {
      print("User not logged in");
      return false; // User is not logged in
    }
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late String userId;
  final phoneNumberController = TextEditingController();
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');

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

  Future<void> checkPhoneNumberAndGenerateOTP() async {
    String enteredPhoneNumber = phoneNumberController.text;

    QuerySnapshot<Object?> querySnapshot =
        await users.where('Phone', isEqualTo: enteredPhoneNumber).get();

    if (querySnapshot.docs.isNotEmpty) {
      userId = querySnapshot.docs.first.id;
      print(userId);
      String otp = generateOTP();
      _showNotification(otp);
      String? receivedOtp = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationLogin(
            otp: otp,
            uid: userId,
          ),
        ),
      );

      if (receivedOtp != null && receivedOtp == otp) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // Set login status to true
        await prefs.setString('uid', userId); // Store UID in shared preferences
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        print('OTP verification failed.');
      }
    } else {
      print('Phone number not found in the database.');
    }
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
            SizedBox(height: 20),
            Container(
              height: 50,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black),
                color: Colors.white12,
              ),
              child: TextField(
                controller: phoneNumberController,
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
            SizedBox(height: 20),
            Container(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  checkPhoneNumberAndGenerateOTP();
                },
                style: ElevatedButton.styleFrom(primary: Colors.white),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "If you don't have an Account",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Create A new Account',
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
