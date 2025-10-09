// lib/screens/placeholder.dart

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart'; // Assuming CartItem is defined here

class PlaceholderScreen extends StatelessWidget {
  final List<CartItem> orderedItems;
  final double totalAmount;

  const PlaceholderScreen({
    super.key,
    required this.orderedItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        // Prevent the user from going back to the checkout screen
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your order has been confirmed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Items Ordered:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            // Use Expanded to make the list scrollable if it's long
            Expanded(
              child: ListView.builder(
                itemCount: orderedItems.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: CircleAvatar(
                    child: Text('${orderedItems[i].quantity}x'),
                  ),
                  title: Text(orderedItems[i].name),
                  trailing: Text('₹${(orderedItems[i].price * orderedItems[i].quantity).toStringAsFixed(2)}'),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
}