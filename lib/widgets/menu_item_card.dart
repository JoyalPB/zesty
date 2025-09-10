import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'dietary_symbol.dart'; // <-- Import our new custom widget
import 'item_details_popup.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isAvailable ? () { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => ItemDetailsPopup(item: item)); } : null,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 50))),
                  if (!item.isAvailable) Container(color: Colors.black.withOpacity(0.6), child: const Center(child: Text('Unavailable', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: Row(
                children: [
                  // --- THIS LINE NOW USES THE CORRECT WIDGET ---
                  DietarySymbol(dietary: item.dietary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}