import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zesty_app/screens/placeholder_screens.dart';

import '../screens/payment_screen.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

// Import the OrderConfirmationScreen and the enum
import '../screens/placeholder_screens.dart';

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

  // UPDATE THIS FUNCTION to use selected items
  void _handleSuccessfulOrder(BuildContext context, OrderPlacementType orderType) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // --- THIS IS THE KEY CHANGE ---
    // We now pass the SELECTED items and total, not the whole cart
    final List<CartItem> orderedItems = cart.selectedCartItems;
    final double total = cart.selectedTotalAmount;
    // --- END OF CHANGE ---

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => OrderConfirmationScreen(
          orderedItems: orderedItems, // Pass selected items
          totalAmount: total,        // Pass selected total
          orderType: orderType,
        ),
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
                  // --- UPDATE The "Total" text ---
                  Text(
                    'Selected (${cart.selectedItemCount})', // Show selected count
                    style: const TextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      // --- UPDATE Chip to show selected total ---
                      '₹${cart.selectedTotalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color:
                        Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    // --- UPDATE onPressed logic ---
                    onPressed: (cart.selectedTotalAmount <= 0) // Disable if no items are selected
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => PaymentScreen(
                            // Pass the selected total to the payment screen
                            totalAmount: cart.selectedTotalAmount,
                            onSuccessfulPayment: () =>
                            // It's an order of *all selected items*
                            _handleSuccessfulOrder(context, OrderPlacementType.allInOne),
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

                // Get the selection state for this item
                final bool isSelected = cart.selectedItems[productId] ?? false;

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
                      // --- CONVERT ListTile to CheckboxListTile ---
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          cart.toggleItemSelection(productId);
                        },
                        controlAffinity: ListTileControlAffinity.leading, // Checkbox at the start
                        secondary: Row(
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
                        title: Text(item.name),
                        subtitle: Text(
                            'Total: ₹${(item.price * item.quantity).toStringAsFixed(2)}'),
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