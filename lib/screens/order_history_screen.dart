import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // 1. Change from a Future to a Stream
  late Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream
    _ordersStream = _listenToOrders();
  }

  // 2. Change the method to return a Stream using .snapshots() instead of .get()
  Stream<QuerySnapshot> _listenToOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Return a stream that emits an error
      return Stream.error('You must be logged in to view your orders.');
    }

    // .snapshots() listens for live updates
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots(); // <-- The key change is here!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      // 3. Change FutureBuilder to StreamBuilder
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream, // Use the stream here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no past orders.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              // ... Your list item code remains exactly the same
              final orderData = orders[index].data() as Map<String, dynamic>;
              final double totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
              final String orderStatus = orderData['status'] ?? 'Unknown';
              final Timestamp timestamp = orderData['timestamp'] ?? Timestamp.now();
              final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());

              return Card( /* ... */ );
            },
          );
        },
      ),
    );
  }
}