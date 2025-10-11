// lib/models/cart_item.dart

class CartItem {
  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  // Updated method to include 'menuItemId'
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId, // <-- The important addition
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}