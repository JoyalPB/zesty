// In: ../models/menu_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final String description;
  final bool isAvailable;
  final int stock;
  final String status;
  final String dietary;
  final Timestamp createdAt;

  // --- ADD THESE TWO LINES ---
  final double averageRating;
  final int reviewCount;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.isAvailable,
    required this.stock,
    required this.status,
    required this.dietary,
    required this.createdAt,

    // --- ADD THESE TO THE CONSTRUCTOR ---
    // We give them default values in case they don't exist in Firestore yet
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });
}