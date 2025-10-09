import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/order_item.dart'; // Keep your OrderItem model

class OrdersProvider with ChangeNotifier {
  final List<OrderItem> _orders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderItem> get orders {
    return [..._orders];
  }

  // MODIFIED: This is now an async method that returns true/false for success/failure
  Future<bool> addOrder(List<CartItem> cartProducts, double total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User must be logged in to place an order
      return false;
    }

    final timestamp = DateTime.now();

    try {
      // A transaction ensures all database writes succeed or none do. It's the safest way.
      await _firestore.runTransaction((transaction) async {
        // Loop through each product that was in the cart
        for (var product in cartProducts) {
          final productRef = _firestore.collection('items').doc(product.menuItemId);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception('Product not found!');
          }

          final currentStock = productSnapshot.data()!['stock'] as int;

          // If there isn't enough stock, throw an error to cancel the whole transaction
          if (currentStock < product.quantity) {
            throw Exception('Not enough stock for ${product.name}');
          }

          // If there is enough stock, calculate the new stock and update it
          final newStock = currentStock - product.quantity;
          transaction.update(productRef, {'stock': newStock});
        }

        // After all stock updates are checked and staged, create the order document
        final orderRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(timestamp.toIso8601String());

        transaction.set(orderRef, {
          'id': timestamp.toIso8601String(),
          'amount': total,
          'dateTime': timestamp,
          'products': cartProducts.map((cp) => {
            'menuItemId': cp.menuItemId,
            'name': cp.name,
            'quantity': cp.quantity,
            'price': cp.price,
          }).toList(),
        });
      });

      // If the transaction was successful, THEN update the local list
      _orders.insert(
        0,
        OrderItem(
          id: timestamp.toString(),
          amount: total,
          products: cartProducts,
          dateTime: timestamp,
        ),
      );
      notifyListeners();
      return true; // Indicate success

    } catch (error) {
      print("Order failed: $error");
      return false; // Indicate failure
    }
  }
}