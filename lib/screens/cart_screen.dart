import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import '../screens/payment_screen.dart'; // Import the PaymentScreen
import '../screens/placeholder_screens.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // This function shows a confirmation dialog before clearing the cart.
  void _showClearCartConfirmationDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content:
        const Text('Are you sure you want to remove all items from your cart?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(ctx).pop();
              cart.clearCart();
            },
          )
        ],
      ),
    );
  }

  // This function handles all logic after a successful payment, including saving to Firestore.
  Future<void> _handleSuccessfulOrder(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orders = Provider.of<OrdersProvider>(context, listen: false);
    final List<CartItem> orderedItems = cart.items.values.toList();
    final double total = cart.totalAmount;

    try {
      // Get a reference to the Firestore collection
      final ordersCollection = FirebaseFirestore.instance.collection('orders');

      // Add a new document with the order data
      await ordersCollection.add({
        'totalAmount': total,
        'orderedAt': Timestamp.now(), // Use a server timestamp
        // Convert the list of CartItem objects into a list of Maps
        'items': orderedItems.map((item) => item.toJson()).toList(),
        // TODO: In a real app, you would add a userId here
        // 'userId': 'your_current_user_id',
      });

      // If the database write is successful, proceed with the local logic
      if (!Navigator.of(context).mounted) return;

      orders.addOrder(orderedItems, total);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PlaceholderScreen(
            orderedItems: orderedItems,
            totalAmount: total,
          ),
        ),
      );
      cart.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed and saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // If there's an error, show a message to the user
      if (!Navigator.of(context).mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save order. Please try again. Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cart',
            onPressed: cart.itemCount == 0
                ? null
                : () => _showClearCartConfirmationDialog(context),
          ),
        ],
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
                        color:
                        Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    onPressed: (cart.totalAmount <= 0)
                        ? null
                        : () {
                      // Navigate to the PaymentScreen on press
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => PaymentScreen(
                            totalAmount: cart.totalAmount,
                            onSuccessfulPayment: () =>
                                _handleSuccessfulOrder(context),
                          ),
                        ),
                      );
                    },
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
                return Dismissible(
                  key: ValueKey(item.id),
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child:
                    const Icon(Icons.delete, color: Colors.white, size: 40),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    Provider.of<CartProvider>(context, listen: false)
                        .removeItem(productId);
                  },
                  child: Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
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
                        subtitle: Text(
                            'Total: ₹${(item.price * item.quantity).toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: item.quantity > 1
                                  ? () {
                                cart.removeSingleItem(productId);
                              }
                                  : null,
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                cart.addSingleItem(productId);
                              },
                            ),
                          ],
                        ),
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