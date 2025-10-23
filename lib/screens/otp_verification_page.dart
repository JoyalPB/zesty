import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:zesty_app/screens/home_screen.dart'; // <-- Add this import
import 'package:zesty_app/screens/profile_setup.dart';

class OtpVerificationPage extends StatefulWidget {
  final String mobileNumber;
  final String verificationId;

  const OtpVerificationPage({
    super.key,
    required this.mobileNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late String _verificationId;
  Timer? _timer;
  int _start = 60;
  bool _isResendButtonActive = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() => _isResendButtonActive = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isResendButtonActive = true;
          timer.cancel();
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  // --- MODIFIED FUNCTION ---
  void _verifyOtp(String otp) async {
    if (otp.length < 6) return;
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // If sign-in is successful, check if the user is new or existing
      if (userCredential.user != null) {
        _timer?.cancel(); // Stop timer on success

        // *** NEW LOGIC TO CHECK IF PROFILE EXISTS ***
        final user = userCredential.user!;
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();

        if (docSnapshot.exists) {
          // User profile already exists, go to HomePage
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.blue, content: Text('Welcome back!')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // New user, go to SetupProfilePage
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text('OTP Verified Successfully!')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SetupProfilePage()),
                (Route<dynamic> route) => false,
          );
        }
        // *** END OF NEW LOGIC ***
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP. Please try again.';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'The entered OTP is incorrect.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resendOtp() async {
    // ... (This function remains unchanged)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.blue, content: Text('Sending a new OTP...')),
    );
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.mobileNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to resend OTP: ${e.message}')),
        );
      },
      codeSent: (String newVerificationId, int? resendToken) {
        setState(() {
          _verificationId = newVerificationId;
          _start = 60;
        });
        startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('A new OTP has been sent.')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (The build method remains unchanged)
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the code sent to',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.mobileNumber,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Pinput(
                length: 6,
                controller: _otpController,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) => _verifyOtp(pin),
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () => _verifyOtp(_otpController.text),
                child: const Text('Verify OTP'),
              ),
              const SizedBox(height: 20),
              _isResendButtonActive
                  ? TextButton(
                onPressed: _resendOtp,
                child: const Text('Resend Code'),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Resend code in ", style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    "00:${_start.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}