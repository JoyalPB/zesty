import 'menu_item.dart';

class CartItem {
  final String id;
  final String menuItemId; // <-- ADD THIS
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.menuItemId, // <-- ADD THIS
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}