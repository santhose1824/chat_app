import 'package:chat_app/AppStartingScreens/ProfilePic%20and%20About.dart';
import 'package:flutter/material.dart';

class OTPVerification extends StatefulWidget {
  final otp;
  final uid;
  OTPVerification({required this.otp, required this.uid});
  @override
  State<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends State<OTPVerification> {
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String getEnteredOTP() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _validateOTP() {
    String enteredOTP = getEnteredOTP();

    if (enteredOTP == widget.otp) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePicAndAboutPage(
                    uid: widget.uid,
                  )));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP Verified Successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP Verified failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(201, 44, 50, 63),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 48.0,
                child: TextFormField(
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  focusNode: _focusNodes[index],
                  controller: _controllers[index],
                  decoration: InputDecoration(
                    counterText: '',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 5) {
                        _focusNodes[index].unfocus();
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        _focusNodes[index].unfocus();
                      }
                    }
                  },
                ),
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
                _validateOTP();
              },
              style: ElevatedButton.styleFrom(primary: Colors.white),
              child: Center(
                child: Text(
                  'Verify',
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
