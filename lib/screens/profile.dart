// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zesty_app/screens/signup_page.dart';
import 'edit_profile.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // ... (Your existing _fetchUserData code remains unchanged)
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        throw Exception("Profile data not found. Please complete setup.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load profile: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // ... (Your existing _logout code remains unchanged)
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
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

  void _navigateToEditProfile() async {
    // ... (Your existing _navigateToEditProfile code remains unchanged)
    if (_userData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userData!['fullName'],
          currentEmail: _userData!['email'],
        ),
      ),
    );
    if (result == true) {
      _fetchUserData();
    }
  }

  // --- ADD THIS NEW NAVIGATION METHOD ---
  /// Navigates to the Order History screen.
  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }
  // ------------------------------------

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final String fullName = _userData?['fullName'] ?? 'No Name Found';
    final String email = _userData?['email'] ?? 'No Email Found';
    final String username = _userData?['username'] ?? 'No Username';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... (Your existing Row with CircleAvatar and user details)
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal.shade100,
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

          // --- ADD THIS NEW LISTTILE FOR ORDER HISTORY ---
          ListTile(
            leading: const Icon(Icons.history, color: Colors.teal),
            title: const Text('Order History'),
            onTap: _navigateToOrderHistory,
            trailing: const Icon(Icons.chevron_right),
          ),
          // ---------------------------------------------

          const Spacer(),

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