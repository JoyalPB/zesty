import 'package:flutter/material.dart';
import 'dart:math'; // For rotation
import '../models/menu_item.dart';
import 'dietary_symbol.dart';
import 'item_details_popup.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  // Helper for the DIAGONAL "Unavailable" banner
  Widget _buildCornerBanner({required String text, required Color color}) {
    return Positioned(
      top: 25,
      left: -30,
      child: Transform.rotate(
        angle: -pi / 4,
        child: Container(
          color: color.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      ),
    );
  }

  // --- NEW: Helper for the HORIZONTAL "Out of Stock" banner ---
  Widget _buildBottomBanner({required String text, required Color color}) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // The new semi-transparent background
        color: color.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 50)),
                    ),
                  ),

                  // --- UPDATED LOGIC TO SHOW THE CORRECT BANNER ---

                  // Case 1: The item is completely unavailable.
                  // Show a grey overlay AND the DIAGONAL "Unavailable" banner.
                  if (!item.isAvailable)
                    Stack(
                      children: [
                        Positioned.fill(
                          child: Container(color: Colors.black.withOpacity(0.5)),
                        ),
                        _buildCornerBanner(text: 'Unavailable', color: Colors.black),
                      ],
                    ),

                  // Case 2: The item is available but has zero stock.
                  // Show ONLY the new HORIZONTAL "Out of Stock" banner.
                  if (item.isAvailable && item.stock == 0)
                    _buildBottomBanner(text: 'Out of Stock', color: Colors.red),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: Row(
                children: [
                  DietarySymbol(dietary: item.dietary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  if (item.status == 'low-stock' && item.isAvailable)
                    Chip(
                      label: Text('Low Stock', style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}