import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zesty_app/screens/placeholder_screens.dart'; // Make sure this path is correct for your project

import '../models/cart_item.dart'; // Make sure this path is correct for your project
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart'; // Make sure this path is correct for your project

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showFakePaymentDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text('Pay a total of ₹${cart.totalAmount.toStringAsFixed(2)}?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Pay Now'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleSuccessfulOrder(context);
            },
          )
        ],
      ),
    );
  }

  void _handleSuccessfulOrder(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orders = Provider.of<OrdersProvider>(context, listen: false);

    final List<CartItem> orderedItems = cart.items.values.toList();
    final double total = cart.totalAmount;

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
        content: Text('Order placed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showClearCartConfirmationDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.itemCount == 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Do you want to permanently remove all items from your cart?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Clear It'),
            onPressed: () {
              Navigator.of(ctx).pop();
              cart.clearCart();
            },
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_shopping_cart_outlined),
            tooltip: 'Clear Cart',
            onPressed: () => _showClearCartConfirmationDialog(context),
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
                        color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                cart.removeSingleItem(productId);
                              },
                              tooltip: 'Remove one',
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                cart.addSingleItem(productId);
                              },
                              tooltip: 'Add one',
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