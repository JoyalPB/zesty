// lib/screens/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart' show OrdersProvider;

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersData = Provider.of<OrdersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: ordersData.orders.isEmpty
          ? const Center(
        child: Text('You have no orders yet!'),
      )
          : ListView.builder(
        itemCount: ordersData.orders.length,
        itemBuilder: (ctx, i) {
          final order = ordersData.orders[i];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ExpansionTile(
              title: Text('₹${order.amount.toStringAsFixed(2)}'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy hh:mm a').format(order.dateTime),
              ),
              children: order.products
                  .map(
                    (prod) => ListTile(
                  leading: CircleAvatar(
                    child: Text('${prod.quantity}x'),
                  ),
                  title: Text(prod.name),
                  trailing: Text(
                      '₹${(prod.price * prod.quantity).toStringAsFixed(2)}'),
                ),
              )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}