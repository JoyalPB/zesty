import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import 'dietary_symbol.dart';

class ItemDetailsPopup extends StatefulWidget {
  final MenuItem item;
  final List<MenuItem> allItems;
  const ItemDetailsPopup({super.key, required this.item, required this.allItems});

  @override
  State<ItemDetailsPopup> createState() => _ItemDetailsPopupState();
}

class _ItemDetailsPopupState extends State<ItemDetailsPopup> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.item.isAvailable;
    final bool isStockLimitReached = _quantity >= widget.item.stock;
    final totalButtonPrice = widget.item.price * _quantity;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.only(top: 8.0), child: Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(15.0), child: Image.network(widget.item.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox(height: 150, child: Icon(Icons.fastfood, size: 80, color: Colors.grey)))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Row(children: [DietarySymbol(dietary: widget.item.dietary, size: 22), const SizedBox(width: 8), Expanded(child: Text(widget.item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))])), const SizedBox(width: 16), Text('₹${widget.item.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))]),
                const SizedBox(height: 8),
                const Row(children: [Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star, color: Colors.amber, size: 20), Icon(Icons.star_half, color: Colors.amber, size: 20), SizedBox(width: 8), Text('(125 ratings)', style: TextStyle(color: Colors.grey, fontSize: 14))]),
                if (widget.item.status == 'low-stock' && isAvailable) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20), const SizedBox(width: 8), Text('Only ${widget.item.stock} left in stock!', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold))]))],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.item.description.isEmpty ? 'No description available.' : widget.item.description}\n\n'
                        'Ingredients: Made with fresh, locally sourced produce. Please contact staff for specific allergen information. ',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (isAvailable && widget.item.stock > 0) ? Theme.of(context).primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: (isAvailable && widget.item.stock > 0)
                  ? () {
                final cart = Provider.of<CartProvider>(context, listen: false);
                cart.addItems(widget.item, _quantity);
                Navigator.of(context).pop();
              }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildQuantityButton(icon: Icons.remove, onPressed: isAvailable && _quantity > 1 ? () => setState(() => _quantity--) : null),
                      const SizedBox(width: 12),
                      Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _buildQuantityButton(icon: Icons.add, onPressed: isAvailable && !isStockLimitReached ? () => setState(() => _quantity++) : null),
                    ],
                  ),
                  Text('Add Item | ₹${totalButtonPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback? onPressed}) {
    return Material(
      color: Colors.white.withOpacity(onPressed == null ? 0.2 : 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, size: 20, color: onPressed == null ? Colors.white54 : Colors.white),
        ),
      ),
    );
  }
}
