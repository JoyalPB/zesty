import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';

// 1. Converted to a StatefulWidget
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 2. A stream to listen for LIVE stock updates for items in the cart
  Stream<QuerySnapshot>? _cartItemsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cart = Provider.of<CartProvider>(context);
    final cartItemIds = cart.items.keys.toList();
    if (cartItemIds.isNotEmpty) {
      // 3. Create a targeted query for ONLY the items in the cart
      _cartItemsStream = FirebaseFirestore.instance
          .collection('items')
          .where(FieldPath.documentId, whereIn: cartItemIds)
          .snapshots();
    } else {
      _cartItemsStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart'), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.remove_shopping_cart, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text('Your Cart is Empty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('Looks like you haven\'t added anything yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // 4. Wrap the UI in a StreamBuilder to get live data
    return StreamBuilder<QuerySnapshot>(
      stream: _cartItemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not verify stock. Please try again.'));
        }

        // 5. Create a map of the LIVE stock counts from Firestore
        final liveStockMap = <String, int>{};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            liveStockMap[doc.id] = (doc.data() as Map<String, dynamic>)['stock'] ?? 0;
          }
        }

        // 6. Identify which cart items are now invalid
        final invalidItems = <String>[];
        cart.items.forEach((menuItemId, cartItem) {
          final liveStock = liveStockMap[menuItemId] ?? 0;
          if (cartItem.quantity > liveStock) {
            invalidItems.add(menuItemId);
          }
        });

        final bool isCheckoutDisabled = invalidItems.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(title: const Text('Your Cart'), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, -3))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 14)), Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
                ElevatedButton(
                  // 7. Disable the button if any item is invalid
                  style: ElevatedButton.styleFrom(backgroundColor: isCheckoutDisabled ? Colors.grey : Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: isCheckoutDisabled ? null : () {
                    // This is your friend's part, so for now we just clear the cart
                    cart.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proceeding to Checkout...'), backgroundColor: Colors.green));
                  },
                  child: const Text('Checkout', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // 8. Show a general warning banner if any item is invalid
              if (isCheckoutDisabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Text(
                    'Some items in your cart have limited stock. Please update your quantities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final menuItemId = cart.items.keys.toList()[i];
                    final cartItem = cart.items[menuItemId]!;
                    final isInvalid = invalidItems.contains(menuItemId);
                    final currentStock = liveStockMap[menuItemId] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        // 9. Add a red border to invalid items
                        border: isInvalid ? Border.all(color: Colors.red, width: 2) : null,
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Row( /* ... Row with image, name, quantity controls ... */
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(cartItem.imageUrl, width: 70, height: 70, fit: BoxFit.cover)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(cartItem.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('₹${cartItem.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey))]),
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove, size: 20, color: Colors.red), onPressed: () => Provider.of<CartProvider>(context, listen: false).removeSingleItem(menuItemId)),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(icon: Icon(Icons.add, size: 20, color: (cartItem.quantity >= currentStock) ? Colors.grey : Colors.green), onPressed: (cartItem.quantity >= currentStock) ? null : () => Provider.of<CartProvider>(context, listen: false).addSingleItem(menuItemId)),
                                ],
                              ),
                            ],
                          ),
                          // 10. Show a specific warning on invalid items
                          if (isInvalid)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Only $currentStock left in stock. Please reduce quantity.',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
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