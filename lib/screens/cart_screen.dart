import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Provider.of here to avoid repetitive code inside the builder
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: cart.items.isEmpty
          ? const Center(
        child: Text('Your cart is empty.', style: TextStyle(fontSize: 20, color: Colors.grey)),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items.values.toList()[i];
                // We get the key (which is the original menu item ID)
                final menuItemId = cart.items.keys.toList()[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(cartItem.imageUrl)),
                    title: Text(cartItem.name),
                    subtitle: Text('Price: ₹${cartItem.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- MINUS BUTTON (NOW WORKING) ---
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20, color: Colors.red),
                          onPressed: () {
                            // We use listen: false because we are just calling a function.
                            Provider.of<CartProvider>(context, listen: false).removeSingleItem(menuItemId);
                          },
                        ),
                        Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16)),
                        // --- PLUS BUTTON (NOW WORKING) ---
                        IconButton(
                          icon: const Icon(Icons.add, size: 20, color: Colors.green),
                          onPressed: () {
                            // This now correctly calls our new function.
                            Provider.of<CartProvider>(context, listen: false).addSingleItem(menuItemId);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // The summary card at the bottom
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Total', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    child: const Text('PLACE ORDER'),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}