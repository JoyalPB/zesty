import 'package:flutter/material.dart';

class DietarySymbol extends StatelessWidget {
  final String dietary;
  final double size;

  const DietarySymbol({super.key, required this.dietary, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    Color symbolColor;
    if (dietary.toLowerCase() == 'veg') {
      symbolColor = Colors.green;
    } else if (dietary.toLowerCase() == 'non-veg') {
      symbolColor = Colors.red;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(border: Border.all(color: symbolColor, width: 1.5)),
      child: Center(
        child: Icon(Icons.circle, color: symbolColor, size: size * 0.6),
      ),
    );
  }
}