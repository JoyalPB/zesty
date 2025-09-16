import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_verification_page.dart'; // Your OTP page

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- Firebase Phone Authentication Logic ---
  void _submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing.
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    final String phoneNumber = '+91${_phoneController.text.trim()}';

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // (Optional) Called when auto-retrieval is successful on Android
      verificationCompleted: (PhoneAuthCredential credential) async {
        // You can auto-sign in the user here if you want
        // await _auth.signInWithCredential(credential);
        // print("Auto verification completed");
      },
      // Called when there is an error
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        // Show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send OTP: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      },
      // Called when the OTP is sent to the device
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        // Navigate to the OTP verification page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              // Pass both the verificationId and mobile number
              verificationId: verificationId,
              mobileNumber: phoneNumber,
            ),
          ),
        );
      },
      // Called when auto-retrieval has timed out
      codeAutoRetrievalTimeout: (String verificationId) {
        // You can handle timeout logic here if needed
      },
      timeout: const Duration(seconds: 60), // Set a timeout duration
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Enter Your Mobile Number',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will send you a confirmation code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Mobile Number',
                      prefixText: '+91 ',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      } else if (value.length != 10) {
                        return 'Please enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    // Disable button when loading
                    onPressed: _isLoading ? null : _submitPhoneNumber,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                        : const Text('Get OTP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}