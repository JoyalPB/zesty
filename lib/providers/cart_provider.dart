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

  // Function for the "Empty Cart" button
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Function for the trash can icon
  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void addItems(MenuItem menuItem, int quantity) {
    if (_items.containsKey(menuItem.id)) {
      _items.update(menuItem.id, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity + quantity, price: existing.price, imageUrl: existing.imageUrl));
    } else {
      _items.putIfAbsent(menuItem.id, () => CartItem(id: DateTime.now().toString(), menuItemId: menuItem.id, name: menuItem.name, quantity: quantity, price: menuItem.price, imageUrl: menuItem.imageUrl));
    }
    notifyListeners();
  }

  void addSingleItem(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    _items.update(menuItemId, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity + 1, price: existing.price, imageUrl: existing.imageUrl));
    notifyListeners();
  }

  void removeSingleItem(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    if (_items[menuItemId]!.quantity > 1) {
      _items.update(menuItemId, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity - 1, price: existing.price, imageUrl: existing.imageUrl));
    } else {
      _items.remove(menuItemId); // If only one is left, remove it completely
    }
    notifyListeners();
  }
}