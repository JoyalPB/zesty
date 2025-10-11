import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _orderId; // <-- 1. ADD A VARIABLE TO HOLD THE ORDER ID

  @override
  void initState() {
    super.initState();
    _placeOrder();
  }

  Future<void> _placeOrder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to place an order.');
      }

      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userData.data()?['username'] ?? 'Guest';

      final orderData = {
        'userId': user.uid,
        'username': username,
        'totalAmount': widget.totalAmount,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'items': widget.orderedItems.map((item) => item.toJson()).toList(), // Assuming a toJson method
      };

      // 2. SAVE THE DOCUMENT REFERENCE AND GET ITS ID
      final newOrderDoc = await FirebaseFirestore.instance.collection('orders').add(orderData);
      _orderId = newOrderDoc.id;

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
      // 3. BUILD THE BODY USING THE ORDER ID
          : _buildLiveOrderDetails(),
    );
  }

  /// Builds the UI that listens for live updates to the order.
  Widget _buildLiveOrderDetails() {
    if (_orderId == null) {
      return const Center(child: Text('Could not load order details.'));
    }

    // 4. USE A STREAMBUILDER TO LISTEN TO THE SPECIFIC ORDER DOCUMENT
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
              const Text(
                'Your order has been placed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.teal),
                title: const Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  currentStatus, // <-- This now comes from the live data
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