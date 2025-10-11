// lib/screens/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If the user is not logged in, show a message.
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Orders'),
        ),
        body: const Center(
          child: Text('Please log in to see your orders.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      // Use a StreamBuilder to listen for real-time updates from Firestore.
      body: StreamBuilder<QuerySnapshot>(
        // Create a stream that fetches orders for the current user, ordered by the newest first.
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, orderSnapshot) {
          // Show a loading indicator while data is being fetched.
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show an error message if something went wrong.
          if (orderSnapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          final orderDocs = orderSnapshot.data?.docs;

          // Show a message if there are no orders.
          if (orderDocs == null || orderDocs.isEmpty) {
            return const Center(child: Text('You have no orders yet!'));
          }

          // If we have data, build the list of orders.
          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (ctx, i) {
              final orderData = orderDocs[i].data() as Map<String, dynamic>;
              final orderItems = orderData['items'] as List<dynamic>;
              final timestamp = orderData['timestamp'] as Timestamp?;
              final status = orderData['status'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text('₹${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}'),
                  subtitle: Text(
                    timestamp != null
                        ? DateFormat('dd/MM/yyyy hh:mm a').format(timestamp.toDate())
                        : 'No date',
                  ),
                  // Display the order status in a Chip.
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(status),
                  ),
                  // Build the list of items within the order.
                  children: orderItems.map((item) {
                    final product = item as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${product['quantity']}x'),
                      ),
                      title: Text(product['name'] ?? 'Unnamed Item'),
                      trailing: Text('₹${(product['price'] * product['quantity']).toStringAsFixed(2)}'),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to determine the color of the status Chip.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'cooking':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}