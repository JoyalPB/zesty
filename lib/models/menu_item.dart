import 'package:cloud_firestore/cloud_firestore.dart'; // Import this for the Timestamp type

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
  final Timestamp createdAt; // <-- ADD THIS NEW PROPERTY

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
    required this.createdAt, // <-- ADD THIS TO THE CONSTRUCTOR
  });
}