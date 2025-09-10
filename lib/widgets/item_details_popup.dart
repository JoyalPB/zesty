import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import 'dietary_symbol.dart';

class ItemDetailsPopup extends StatefulWidget {
  final MenuItem item;
  const ItemDetailsPopup({super.key, required this.item});
  @override
  State<ItemDetailsPopup> createState() => _ItemDetailsPopupState();
}

class _ItemDetailsPopupState extends State<ItemDetailsPopup> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.item.isAvailable;
    final bool isStockLimitReached = _quantity >= widget.item.stock;

    // The old helper function is now gone.

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), ClipRRect(borderRadius: BorderRadius.circular(15.0), child: Image.network(widget.item.imageUrl, height: 200, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Icon(Icons.fastfood, size: 80, color: Colors.grey)))), const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // --- USE OUR NEW, RELIABLE WIDGET ---
                      DietarySymbol(dietary: widget.item.dietary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('₹${widget.item.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: 8),
            // ... (Rating, Description, Quantity, and Button are the same) ...
            const Row(children: [Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star_half, color: Colors.amber, size: 20), SizedBox(width: 8), Text('(125 ratings)', style: TextStyle(color: Colors.grey, fontSize: 14))]), const SizedBox(height: 16), Text(widget.item.description.isEmpty ? 'No description available.' : widget.item.description, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis), const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: Icon(Icons.remove_circle_outline, color: isAvailable ? Colors.red : Colors.grey, size: 30), onPressed: isAvailable ? () { if (_quantity > 1) { setState(() { _quantity--; }); } } : null), const SizedBox(width: 16), Text('$_quantity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isAvailable ? Colors.black : Colors.grey)), const SizedBox(width: 16), IconButton(icon: Icon(Icons.add_circle_outline, color: (isAvailable && !isStockLimitReached) ? Colors.green : Colors.grey, size: 30), onPressed: (isAvailable && !isStockLimitReached) ? () { setState(() { _quantity++; }); } : null)]), const SizedBox(height: 16), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: (isAvailable && widget.item.stock > 0) ? Colors.teal : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: (isAvailable && widget.item.stock > 0) ? () { final cart = Provider.of<CartProvider>(context, listen: false); cart.addItems(widget.item, _quantity); Navigator.of(context).pop(); } : null, child: Text((isAvailable && widget.item.stock > 0) ? 'Add $_quantity to Cart - ₹${(widget.item.price * _quantity).toStringAsFixed(2)}' : 'Out of Stock', style: const TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }
}