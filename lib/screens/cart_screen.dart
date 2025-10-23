import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zesty_app/screens/placeholder_screens.dart';

// Import your new order confirmation screen
import '../screens/payment_screen.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

// Firestore and OrdersProvider are no longer needed here
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showClearCartConfirmationDialog(BuildContext context) {
    // ... This function remains the same
    final cart = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
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

  // --- THIS FUNCTION IS NOW MUCH SIMPLER ---
  // It no longer saves to the database or clears the cart.
  // Its only job is to navigate to the confirmation screen.
  void _handleSuccessfulOrder(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List<CartItem> orderedItems = cart.items.values.toList();
    final double total = cart.totalAmount;

    // The new logic: Simply navigate and pass the cart data.
    // The OrderConfirmationScreen will handle the rest.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => OrderConfirmationScreen(
          orderedItems: orderedItems,
          totalAmount: total,
        ),
      ),
    );
  }
  // --- END OF SIMPLIFIED FUNCTION ---

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        // ... AppBar code remains the same
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
                      // This part remains the same. It correctly navigates
                      // to the payment screen, which then calls our new,
                      // simplified _handleSuccessfulOrder function.
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
              // ... The rest of the ListView.builder remains the same
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