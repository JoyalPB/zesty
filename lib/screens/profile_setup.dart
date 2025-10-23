import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zesty_app/screens/home_screen.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _collegeIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final newUsername = _usernameController.text.trim();
      final newCollegeId = _collegeIdController.text.trim();

      // Check for username uniqueness
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: newUsername)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('This username is already taken. Please choose another.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Check for college ID uniqueness
      final collegeIdQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('collegeId', isEqualTo: newCollegeId)
          .limit(1)
          .get();

      if (collegeIdQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('This College ID is already registered.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // If both are unique, proceed to create the profile
      final user = FirebaseAuth.instance.currentUser;
      print("ATTEMPTING TO WRITE TO FIRESTORE. Current User UID: ${user?.uid}");
      if (user == null) {
        throw Exception("No authenticated user found.");
      }

      final userProfileData = {
        'uid': user.uid,
        'fullName': _nameController.text.trim(),
        'username': newUsername,
        'collegeId': newCollegeId,
        'email': _emailController.text.trim(),
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save data to Firestore and update Auth display name
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userProfileData);
      await user.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Profile created successfully!'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Setup your profile',
                    style: GoogleFonts.urbanist(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please fill in the details to complete your profile.',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name.';
                      }
                      final alphanumeric = RegExp(r'^[a-zA-Z ]+$');
                      if (!alphanumeric.hasMatch(value)) {
                        return 'Full name  can only contain letters.';

                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a user name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // College ID Field
                  TextFormField(
                    controller: _collegeIdController,
                    decoration: InputDecoration(
                      labelText: 'College ID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your college id.';
                      }
                        // NEW: Regular expression to check for only letters and numbers.
                        final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
                        if (!alphanumeric.hasMatch(value)) {
                          return 'College ID can only contain letters and numbers.';

                        }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email.';
                      }

                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _submitProfile,
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        'Continue',
                        style: GoogleFonts.urbanist(fontSize: 18, color: Colors.white),
                      ),
                    ),
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