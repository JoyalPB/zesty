import 'package:flutter/material.dart';

class AppColors {
  // --- PRIMARY COLORS ---
  // A custom MaterialColor swatch generated from our primary orange.
  // This allows Flutter to have different shades for different UI states.
  static const MaterialColor primaryOrange = MaterialColor(
    _primaryOrangeValue,
    <int, Color>{
      50:  Color(0xFFFFF2EF),
      100: Color(0xFFFFE0D8),
      200: Color(0xFFFECAB9),
      300: Color(0xFFFDAF9A),
      400: Color(0xFFFB9B82),
      500: Color(_primaryOrangeValue),
      600: Color(0xFFF96646),
      700: Color(0xFFF25A3D),
      800: Color(0xFFEC4F35),
      900: Color(0xFFE03C25),
    },
  );
  static const int _primaryOrangeValue = 0xFFF97316; // The main orange from the logo

  // The deep purple from the logo
  static const Color primaryPurple = Color(0xFF8A3A8A);

  // --- ACCENT & OTHER COLORS ---
  static const Color accentGreen = Color(0xFF84CC16);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF6B7280);
}