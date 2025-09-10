import 'package:flutter/material.dart';
import '../models/filter_settings.dart';

class FilterPopup extends StatefulWidget {
  final FilterSettings initialSettings;
  const FilterPopup({super.key, required this.initialSettings});

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  late String _selectedDietary;
  late RangeValues _currentPriceRange;
  late String _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _selectedDietary = widget.initialSettings.dietary;
    _currentPriceRange = widget.initialSettings.priceRange;
    _selectedSortBy = widget.initialSettings.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final dietaryOptions = ['All', 'veg', 'non-veg'];
    final sortOptions = ['Default', 'Price: Low-High', 'Price: High-Low'];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Dietary Preference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: dietaryOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final diet = dietaryOptions[index];
                return FilterChip(label: Text(diet[0].toUpperCase() + diet.substring(1)), selected: _selectedDietary == diet, onSelected: (sel) { if (sel) { setState(() { _selectedDietary = diet; }); }}, selectedColor: Colors.teal.withOpacity(0.2), checkmarkColor: Colors.teal);
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), Text('₹${_currentPriceRange.start.round()} - ₹${_currentPriceRange.end.round()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)) ]),
          RangeSlider(values: _currentPriceRange, min: 0, max: 500, divisions: 50, activeColor: Colors.teal, onChanged: (values) { setState(() { _currentPriceRange = values; }); }),
          const SizedBox(height: 24),
          const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: sortOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sort = sortOptions[index];
                return FilterChip(label: Text(sort), selected: _selectedSortBy == sort, onSelected: (selected) { if (selected) { setState(() { _selectedSortBy = sort; }); }}, selectedColor: Colors.teal.withOpacity(0.2), checkmarkColor: Colors.teal);
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // --- THIS IS THE UPDATED "CLEAR" BUTTON ---
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // It now just resets the local state inside the popup.
                    setState(() {
                      final defaultSettings = FilterSettings();
                      _selectedDietary = defaultSettings.dietary;
                      _currentPriceRange = defaultSettings.priceRange;
                      _selectedSortBy = defaultSettings.sortBy;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    final newSettings = FilterSettings(dietary: _selectedDietary, priceRange: _currentPriceRange, sortBy: _selectedSortBy);
                    // The "Apply" button is the one that closes the popup.
                    Navigator.of(context).pop(newSettings);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}