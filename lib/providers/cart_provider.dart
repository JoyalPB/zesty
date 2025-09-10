import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount {
    int count = 0;
    _items.forEach((key, cartItem) { count += cartItem.quantity; });
    return count;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) { total += cartItem.price * cartItem.quantity; });
    return total;
  }

  // --- THIS IS THE NEW, MORE POWERFUL FUNCTION ---
  // It can add a specific quantity of an item to the cart.
  void addItems(MenuItem menuItem, int quantity) {
    if (_items.containsKey(menuItem.id)) {
      // If the item already exists, we just add the new quantity to the old one.
      _items.update(
        menuItem.id,
            (existing) => CartItem(
            id: existing.id,
            name: existing.name,
            quantity: existing.quantity + quantity, // The key change
            price: existing.price,
            imageUrl: existing.imageUrl),
      );
    } else {
      // If it's a new item, we add it with the specified quantity.
      _items.putIfAbsent(
        menuItem.id,
            () => CartItem(
            id: DateTime.now().toString(),
            name: menuItem.name,
            quantity: quantity, // The key change
            price: menuItem.price,
            imageUrl: menuItem.imageUrl),
      );
    }
    notifyListeners();
  }

  // This function is now deprecated but we can leave it for now.
  void addItem(MenuItem menuItem) {
    addItems(menuItem, 1);
  }

  void addSingleItem(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    _items.update(menuItemId, (existing) => CartItem(id: existing.id, name: existing.name, quantity: existing.quantity + 1, price: existing.price, imageUrl: existing.imageUrl));
    notifyListeners();
  }

  void removeSingleItem(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    if (_items[menuItemId]!.quantity > 1) {
      _items.update(menuItemId, (existing) => CartItem(id: existing.id, name: existing.name, quantity: existing.quantity - 1, price: existing.price, imageUrl: existing.imageUrl));
    } else {
      _items.remove(menuItemId);
    }
    notifyListeners();
  }
}