import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Helper method to show the confirmation dialog
  Future<void> _showClearCartDialog(BuildContext context, CartProvider cart) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Empty Cart?'),
          content: const Text('Are you sure you want to remove all items from your cart?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirm', style: TextStyle(color: Colors.red)),
              onPressed: () {
                cart.clearCart();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Your Cart'),
        // The "Empty Cart" button is here
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Empty Cart',
              onPressed: () => _showClearCartDialog(context, cart),
            ),
        ],
      ),
      bottomNavigationBar: cart.items.isEmpty ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, -3))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 14)), Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
            ElevatedButton(
              onPressed: () {
                cart.clearCart(); // This is your friend's part
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proceeding to Checkout...'), backgroundColor: Colors.green));
              },
              child: const Text('Checkout', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      body: cart.items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.remove_shopping_cart, size: 100, color: Colors.grey[300]), const SizedBox(height: 20), const Text('Your Cart is Empty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)), const SizedBox(height: 8), const Text('Looks like you haven\'t added anything yet.', style: TextStyle(fontSize: 16, color: Colors.grey))]))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: cart.items.length,
        itemBuilder: (ctx, i) {
          final cartItem = cart.items.values.toList()[i];
          final menuItemId = cart.items.keys.toList()[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))]),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(cartItem.imageUrl, width: 70, height: 70, fit: BoxFit.cover)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cartItem.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('₹${cartItem.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey))]),
                ),
                // The complete set of controls, including the trash icon
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove, size: 22, color: Colors.black54), onPressed: () => Provider.of<CartProvider>(context, listen: false).removeSingleItem(menuItemId)),
                    Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add, size: 22, color: Colors.black54), onPressed: () => Provider.of<CartProvider>(context, listen: false).addSingleItem(menuItemId)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove all ${cartItem.name}',
                      onPressed: () => Provider.of<CartProvider>(context, listen: false).removeItem(menuItemId),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}