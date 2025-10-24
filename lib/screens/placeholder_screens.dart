import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

// <-- 1. DEFINE AN ENUM FOR THE ORDER TYPE -->
enum OrderPlacementType {
  allInOne,
  separateItems,
}

class OrderConfirmationScreen extends StatefulWidget {
  final List<CartItem> orderedItems;
  final double totalAmount;
  final OrderPlacementType orderType; // <-- 2. ADD THE NEW PARAMETER -->

  const OrderConfirmationScreen({
    super.key,
    required this.orderedItems,
    required this.totalAmount,
    required this.orderType, // <-- 3. ADD TO CONSTRUCTOR -->
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _orderId; // Will only be set for 'allInOne' orders

  @override
  void initState() {
    super.initState();
    _placeOrder();
  }

  String _generateRandomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  // <-- 4. HELPER FUNCTION TO FIND A UNIQUE 4-DIGIT ID -->
  Future<String> _findUniqueOrderId() async {
    String generatedId;
    bool idExists;
    DocumentReference orderDocRef;
    do {
      generatedId = _generateRandomId(4);
      orderDocRef = FirebaseFirestore.instance.collection('orders').doc(generatedId);
      final docSnapshot = await orderDocRef.get();
      idExists = docSnapshot.exists;
    } while (idExists); // Loop until we find one that doesn't exist
    return generatedId;
  }

  // <-- 5. HEAVILY MODIFIED _placeOrder METHOD -->
  Future<void> _placeOrder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to place an order.');
      }

      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // Make sure 'fullName' matches the field name in your Firestore 'users' collection
      final fullName = userData.data()?['fullName'] ?? 'Guest';

      // --- LOGIC FOR 'ALL IN ONE' ORDER ---
      if (widget.orderType == OrderPlacementType.allInOne) {
        final orderData = {
          'userId': user.uid,
          'fullName': fullName,
          'totalAmount': widget.totalAmount, // The total for ALL items
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'items': widget.orderedItems.map((item) => item.toJson()).toList(), // List of ALL items
        };

        // Find a unique ID for this single order
        final generatedId = await _findUniqueOrderId();
        await FirebaseFirestore.instance.collection('orders').doc(generatedId).set(orderData);

        // Save the single ID to show in the UI
        _orderId = generatedId;

        // --- LOGIC FOR 'SEPARATE' ORDERS ---
      } else if (widget.orderType == OrderPlacementType.separateItems) {

        // Use a batch write to send all orders at once. It's faster
        // and fails together, so you don't get partial orders.
        final batch = FirebaseFirestore.instance.batch();

        for (final item in widget.orderedItems) {
          final orderData = {
            'userId': user.uid,
            'fullName': fullName,
            'totalAmount': item.price * item.quantity, // Total for THIS item only
            'status': 'Pending',
            'timestamp': FieldValue.serverTimestamp(),
            'items': [item.toJson()], // A list containing ONLY this one item
          };

          // Find a unique ID for EACH order
          final generatedId = await _findUniqueOrderId();
          final orderDocRef = FirebaseFirestore.instance.collection('orders').doc(generatedId);

          // Add this new order to the batch
          batch.set(orderDocRef, orderData);
        }

        // Commit all the new orders to Firestore
        await batch.commit();
        // _orderId remains null, because there are multiple orders
      }

      // Clear the cart (this runs for both cases)
      if (mounted) {
        // This line ONLY removes the items you selected for checkout
        Provider.of<CartProvider>(context, listen: false).removeSelectedItems();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to place order(s). Please try again. \nError: $e';
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
            Text('Placing your order(s)...', style: TextStyle(fontSize: 16)),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
      // <-- 6. RENAMED AND UPDATED THE BODY BUILDER -->
          : _buildConfirmationBody(),
    );
  }

  /// Builds the UI based on the order type.
  Widget _buildConfirmationBody() {
    // --- 7. UI FOR 'SEPARATE' ORDERS ---
    if (widget.orderType == OrderPlacementType.separateItems) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Your orders have been placed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.orderedItems.length} separate orders were successfully created.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
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
        ),
      );
    }

    // --- 8. UI FOR 'ALL IN ONE' ORDER (Your existing logic) ---
    if (_orderId == null) {
      // This case should ideally not be hit if 'allInOne' was successful,
      // but it's good practice to keep it.
      return const Center(child: Text('Could not load order details.'));
    }

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
                'Your order has been placed! (ID: $_orderId)',
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
                      color: currentStatus == 'Pending' ? Colors.orange : (currentStatus == 'Cooking' ? Colors.blue : Colors.green)),
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