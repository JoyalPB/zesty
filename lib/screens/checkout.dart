// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import 'placeholder_screens.dart';

// --- CHANGED: Converted to a StatefulWidget to manage loading state ---
class CheckoutScreen extends StatefulWidget {
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- NEW: State variable to track loading status ---
  bool _isLoading = false;

  /// Handles the final order confirmation logic async.
  Future<void> _confirmOrder(BuildContext context) async {
    // Show a loading indicator and disable the button
    setState(() {
      _isLoading = true;
    });

    try {
      // --- NEW: Simulate a network request (e.g., saving to a database) ---
      await Future.delayed(const Duration(seconds: 2));

      // Uncomment the line below to test the error handling
      // throw Exception('Network error! Please try again.');

      final cart = Provider.of<CartProvider>(context, listen: false);
      final List<CartItem> cartItems = cart.items.values.toList();
      final double finalAmount = widget.totalAmount;

      // Navigate to the placeholder screen with the details
      if (!mounted) return; // Safety check for async operations
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) =>
              PlaceholderScreen(
                orderedItems: cartItems,
                totalAmount: finalAmount,
              ),
        ),
      );

      // Now it's safe to clear the cart
      cart.clearCart();
    } catch (error) {
      // --- NEW: Show an error message if something goes wrong ---
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // --- NEW: Always turn off the loading indicator at the end ---
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Access cart here to display items ---
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Order Summary', style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // --- NEW: Display the list of items in the cart ---
                    if (cartItems.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (ctx, i) =>
                            ListTile(
                              dense: true,
                              title: Text(cartItems[i].name),
                              leading: CircleAvatar(child: Text(
                                  '${cartItems[i].quantity}x')),
                              trailing: Text('₹${(cartItems[i].price *
                                  cartItems[i].quantity).toStringAsFixed(2)}'),
                            ),
                      ),

                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: _isLoading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              )
                  : const Text(
                  'Confirm Order & Pay', style: TextStyle(fontSize: 18)),
              // --- CHANGED: Disable button while loading ---
              onPressed: _isLoading ? null : () => _confirmOrder(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
