import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  // --- 1. ADDED FOR SELECTION ---
  Map<String, bool> _selectedItems = {};
  // -----------------------------

  // Add an instance of Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, CartItem> get items => {..._items};

  // --- 2. ADDED GETTER ---
  Map<String, bool> get selectedItems => {..._selectedItems};
  // -----------------------

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

  // --- 3. ADDED GETTERS for selected items ---
  double get selectedTotalAmount {
    double total = 0.0;
    _selectedItems.forEach((productId, isSelected) {
      if (isSelected && _items.containsKey(productId)) {
        total += _items[productId]!.price * _items[productId]!.quantity;
      }
    });
    return total;
  }

  List<CartItem> get selectedCartItems {
    final List<CartItem> items = [];
    _selectedItems.forEach((productId, isSelected) {
      if (isSelected && _items.containsKey(productId)) {
        items.add(_items[productId]!);
      }
    });
    return items;
  }

  int get selectedItemCount {
    int count = 0;
    _selectedItems.forEach((key, isSelected) {
      if (isSelected) {
        count++;
      }
    });
    return count;
  }
  // ------------------------------------------

  // --- 4. ADDED THIS METHOD ---
  void toggleItemSelection(String productId) {
    if (_selectedItems.containsKey(productId)) {
      _selectedItems[productId] = !_selectedItems[productId]!;
    } else {
      _selectedItems[productId] = true; // Select by default on first tap
    }
    notifyListeners();
  }
  // --------------------------

  Future<void> clearCart() async {
    if (_items.isEmpty) return;

    final batch = _firestore.batch();

    _items.forEach((menuItemId, cartItem) {
      final docRef = _firestore.collection('items').doc(menuItemId);
      batch.update(docRef, {'stock': FieldValue.increment(cartItem.quantity)});
    });

    await batch.commit();

    _items.clear();
    _selectedItems.clear(); // --- MODIFIED ---
    notifyListeners();
  }

  Future<void> removeItem(String menuItemId) async {
    if (!_items.containsKey(menuItemId)) return;

    final itemQuantity = _items[menuItemId]!.quantity;
    final docRef = _firestore.collection('items').doc(menuItemId);

    await docRef.update({'stock': FieldValue.increment(itemQuantity)});

    _items.remove(menuItemId);
    _selectedItems.remove(menuItemId); // --- MODIFIED ---
    notifyListeners();
  }

  Future<bool> addItem(MenuItem menuItem, {int quantity = 1}) async {
    final docRef = _firestore.collection('items').doc(menuItem.id);

    return await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        print('Error: Document for item ID ${menuItem.id} does not exist in the "items" collection!');
        return false;
      }
      final dynamic stockData = snapshot.data()!['stock'];
      final int currentStock = (stockData is num) ? stockData.toInt() : 0;


      if (currentStock >= quantity) {
        transaction.update(docRef, {'stock': FieldValue.increment(-quantity)});

        if (_items.containsKey(menuItem.id)) {
          _items.update(menuItem.id, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity + quantity, price: existing.price, imageUrl: existing.imageUrl));
        } else {
          _items.putIfAbsent(menuItem.id, () => CartItem(id: DateTime.now().toString(), menuItemId: menuItem.id, name: menuItem.name, quantity: quantity, price: menuItem.price, imageUrl: menuItem.imageUrl));
        }
        return true; // Success
      } else {
        return false; // Failure
      }
    }).then((success) {
      if (success) notifyListeners();
      return success;
    });
  }

  Future<void> addSingleItem(String menuItemId) async {
    if (!_items.containsKey(menuItemId)) return;

    final docRef = _firestore.collection('items').doc(menuItemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final dynamic stockData = snapshot.data()?['stock'];
      final int currentStock = (stockData is num) ? stockData.toInt() : 0;

      if (currentStock > 0) {
        transaction.update(docRef, {'stock': FieldValue.increment(-1)});
        _items.update(menuItemId, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity + 1, price: existing.price, imageUrl: existing.imageUrl));
      }
    });

    notifyListeners();
  }

  Future<void> removeSingleItem(String menuItemId) async {
    if (!_items.containsKey(menuItemId)) return;

    final docRef = _firestore.collection('items').doc(menuItemId);

    await docRef.update({'stock': FieldValue.increment(1)});

    if (_items[menuItemId]!.quantity > 1) {
      _items.update(menuItemId, (existing) => CartItem(id: existing.id, menuItemId: existing.menuItemId, name: existing.name, quantity: existing.quantity - 1, price: existing.price, imageUrl: existing.imageUrl));
    } else {
      _items.remove(menuItemId);
      _selectedItems.remove(menuItemId); // --- MODIFIED ---
    }
    notifyListeners();
  }

  // --- 5. ADDED THIS NEW METHOD for clearing selected items after checkout ---
  Future<void> removeSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final batch = _firestore.batch();
    List<String> keysToRemove = [];

    // Loop through selected items to prep batch and local removal list
    _selectedItems.forEach((menuItemId, isSelected) {
      if (isSelected && _items.containsKey(menuItemId)) {
        // 1. Add key to local removal list
        keysToRemove.add(menuItemId);

        // 2. Prep batch to restore stock to Firestore
        final itemQuantity = _items[menuItemId]!.quantity;
        final docRef = _firestore.collection('items').doc(menuItemId);
        batch.update(docRef, {'stock': FieldValue.increment(itemQuantity)});
      }
    });

    if (keysToRemove.isEmpty) return;

    // Commit all stock updates to Firestore at once
    await batch.commit();

    // Now, update local state
    for (var key in keysToRemove) {
      _items.remove(key);
      _selectedItems.remove(key);
    }

    notifyListeners();
  }
// ----------------------------------------------------------------------
}