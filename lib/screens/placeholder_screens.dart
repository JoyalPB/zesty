import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // <-- 1. IMPORT DART:MATH FOR THE RANDOM GENERATOR

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final List<CartItem> orderedItems;
  final double totalAmount;

  const OrderConfirmationScreen({
    super.key,
    required this.orderedItems,
    required this.totalAmount,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _placeOrder();
  }

  // <-- 2. ADD A HELPER FUNCTION TO GENERATE THE ID
  String _generateRandomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  Future<void> _placeOrder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to place an order.');
      }

      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // <-- 3. FETCH 'fullname' INSTEAD OF 'username'
      final fullName = userData.data()?['fullName'] ?? 'Guest';

      final orderData = {
        'userId': user.uid,
        'fullName': fullName, // <-- USE 'fullname' HERE
        'totalAmount': widget.totalAmount,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'items': widget.orderedItems.map((item) => item.toJson()).toList(),
      };

      // <-- 4. LOGIC TO GENERATE A UNIQUE 4-DIGIT ID
      String generatedId;
      bool idExists;
      DocumentReference orderDocRef;

      do {
        // Generate a random 4-character ID
        generatedId = _generateRandomId(4);
        orderDocRef = FirebaseFirestore.instance.collection('orders').doc(generatedId);

        // Check if a document with this ID already exists
        final docSnapshot = await orderDocRef.get();
        idExists = docSnapshot.exists;

      } while (idExists); // Loop until we find an ID that doesn't exist

      // We found a unique ID, now create the document using .set()
      await orderDocRef.set(orderData);

      _orderId = generatedId; // Save the custom ID to be used by the StreamBuilder

      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clearCart();
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to place order. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Placing your order...', style: TextStyle(fontSize: 16)),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
      )
          : _buildLiveOrderDetails(),
    );
  }

  /// Builds the UI that listens for live updates to the order.
  Widget _buildLiveOrderDetails() {
    if (_orderId == null) {
      return const Center(child: Text('Could not load order details.'));
    }

    // This StreamBuilder now correctly listens to the custom 4-digit ID
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(_orderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Order details not found.'));
        }

        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final String currentStatus = orderData['status'] ?? 'Unknown';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your order has been placed! (ID: $_orderId)', // Added the ID here
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.teal),
                title: const Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  currentStatus,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentStatus == 'Pending' ? Colors.orange : (currentStatus == 'Cooking' ? Colors.blue : Colors.green)
                  ),
                ),
              ),
              const Divider(),
              const Text(
                'Items Ordered:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.orderedItems.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: CircleAvatar(
                      child: Text('${widget.orderedItems[i].quantity}x'),
                    ),
                    title: Text(widget.orderedItems[i].name),
                    trailing: Text('₹${(widget.orderedItems[i].price * widget.orderedItems[i].quantity).toStringAsFixed(2)}'),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Back to Home'),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}