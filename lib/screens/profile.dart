// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zesty_app/screens/signup_page.dart';
import 'edit_profile.dart'; // Make sure this path is correct

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variables to hold user data and loading status
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch user data when the screen is first loaded
    _fetchUserData();
  }

  /// Fetches the current user's data from Firestore.
  Future<void> _fetchUserData() async {
    // Reset state before fetching
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Get the user document from the 'users' collection using their UID
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        // If the document exists, store its data in our state variable
        setState(() {
          _userData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        // Handle case where user is authenticated but has no profile document
        throw Exception("Profile data not found. Please complete setup.");
      }
    } catch (e) {
      // Handle any errors during the fetch process
      setState(() {
        _errorMessage = "Failed to load profile: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  /// Signs the user out and navigates to the signup screen.
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Ensure the widget is still mounted before navigating
      if (!mounted) return;

      // Navigate to the signup page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignupPage()),
            (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('You have been successfully logged out.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to log out: ${e.toString()}'),
        ),
      );
    }
  }

  /// Navigates to the Edit Profile screen and refreshes data on return.
  void _navigateToEditProfile() async {
    if (_userData == null) return;

    // Navigate and wait for a result.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userData!['fullName'],
          currentEmail: _userData!['email'],
        ),
      ),
    );

    // If the edit screen returns 'true', it means the profile was updated.
    // So, we refresh the data on this screen.
    if (result == true) {
      _fetchUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: _isLoading || _userData == null ? null : _navigateToEditProfile,
          ),
        ],
      ),
      // Display a loading indicator, an error, or the profile content
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _buildProfileContent(),
    );
  }

  /// Builds the main profile content once data is loaded.
  Widget _buildProfileContent() {
    // Safely access data with fallback values
    final String fullName = _userData?['fullName'] ?? 'No Name Found';
    final String email = _userData?['email'] ?? 'No Email Found';
    final String username = _userData?['username'] ?? 'No Username';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch button to full width
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal.shade100,
                // Display the first letter of the user's name
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.teal),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@$username',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // Profile Details
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.teal),
            title: const Text('Email'),
            subtitle: Text(email, style: const TextStyle(fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: Colors.teal),
            title: const Text('Phone Number'),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Not Provided',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          const Spacer(), // Pushes the logout button to the bottom

          // Logout Button
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}