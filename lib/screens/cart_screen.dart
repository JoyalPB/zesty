import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zesty_app/screens/placeholder_screens.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // This function shows our fake payment dialog
  void _showFakePaymentDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text('Pay a total of ₹${cart.totalAmount.toStringAsFixed(2)}?'),
        actions: <Widget>[
          // The "Cancel" button simulates a failed or cancelled payment
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Just close the dialog
            },
          ),
          // The "Pay Now" button simulates a successful payment
          ElevatedButton(
            child: const Text('Pay Now'),
            onPressed: () {
              // 1. Close the dialog first
              Navigator.of(ctx).pop();

              // 2. Run all the logic for a successful order
              _handleSuccessfulOrder(context);
            },
          )
        ],
      ),
    );
  }

  // This function contains the logic to run after a "successful" payment

  void _handleSuccessfulOrder(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orders = Provider.of<OrdersProvider>(context, listen: false);

    // --- THE FIX IS HERE ---
    // 1. Store cart data in local variables BEFORE clearing.
    final List<CartItem> orderedItems = cart.items.values.toList();
    final double total = cart.totalAmount;

    // 2. Add the order to your order history using the local variables.
    orders.addOrder(orderedItems, total);

    // 3. Navigate to the confirmation screen using the local variables.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PlaceholderScreen(
          orderedItems: orderedItems, // Pass the saved list
          totalAmount: total,        // Pass the saved total
        ),
      ),
    );

    // 4. NOW it's safe to clear the cart.
    cart.clearCart();

    // 5. Show a success message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order placed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    // When pressed, call our new dialog function
                    onPressed: (cart.totalAmount <= 0)
                        ? null
                        : () => _showFakePaymentDialog(context),
                    child: const Text('ORDER NOW'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final item = cart.items.values.toList()[i];
                final productId = cart.items.keys.toList()[i];
                // ... (The rest of your ListView.builder is the same)
                return Dismissible(
                  key: ValueKey(item.id),
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: const Icon(Icons.delete, color: Colors.white, size: 40),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    Provider.of<CartProvider>(context, listen: false).removeItem(productId);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: FittedBox(child: Text('₹${item.price}')),
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text('Total: ₹${(item.price * item.quantity).toStringAsFixed(2)}'),
                        trailing: Text('${item.quantity} x'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}