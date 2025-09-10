import 'menu_item.dart';

class CartItem {
  final String id; // This is usually the same as the menu item's id
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}