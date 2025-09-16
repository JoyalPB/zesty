import 'package:flutter/material.dart';

class FilterSettings {
  final String dietary;
  final RangeValues priceRange;
  final String sortBy; // <-- ADD THIS NEW PROPERTY

  FilterSettings({
    this.dietary = 'All',
    this.priceRange = const RangeValues(0, 500),
    this.sortBy = 'Default', // <-- ADD THIS WITH A DEFAULT VALUE
  });
}