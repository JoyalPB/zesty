import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/filter_settings.dart';
import '../models/menu_item.dart';
import '../widgets/filter_popup.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/featured_items_banner.dart';
import 'error_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // ... (All your state variables and functions are the same)
  final _searchController = TextEditingController(); String _searchQuery = ''; String _selectedCategory = 'All'; FilterSettings _appliedFilters = FilterSettings();
  @override
  void initState() { super.initState(); _searchController.addListener(() { setState(() { _searchQuery = _searchController.text; }); }); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  Future<void> _showFilterPopup() async { final result = await showModalBottomSheet<FilterSettings>(context: context, isScrollControlled: true, builder: (context) => FilterPopup(initialSettings: _appliedFilters)); if (result != null) { setState(() { _appliedFilters = result; }); } }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ... (Header and Search Bar are the same)
        const Text('Hi, Akshay!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('What would you like to eat?', style: TextStyle(fontSize: 18, color: Colors.grey)), const SizedBox(height: 24), TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search for food or snacks...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none))), const SizedBox(height: 24),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
            if (snapshot.hasError) return ErrorScreen(onRetry: () => setState(() {}));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No menu items available.'));

            final allItems = snapshot.data!.docs;
            // ... (Logic to build banner and categories is the same)
            final allMenuItems = allItems.map((doc) { final itemData = doc.data() as Map<String, dynamic>; return MenuItem(id: doc.id, name: itemData['name'] ?? 'No Name', price: (itemData['price'] ?? 0.0).toDouble(), imageUrl: itemData['image'] ?? '', category: itemData['category'] ?? 'General', description: itemData['description'] ?? '', isAvailable: itemData['available'] ?? false, stock: itemData['stock'] ?? 0, status: itemData['status'] ?? '', dietary: itemData['dietary'] ?? '', createdAt: itemData['createdAt'] ?? Timestamp.now()); }).toList();
            final availableForBanner = allMenuItems.where((item) => item.isAvailable).toList();
            final shuffledItems = availableForBanner..shuffle();
            final featuredItems = shuffledItems.take(5).toList();
            final categoriesSet = allItems.map((doc) => (doc.data() as Map<String, dynamic>)['category'] ?? 'Uncategorized').toSet();
            final categories = ['All', ...categoriesSet.toList()];

            var filteredItems = allItems.where((doc) { /* ... filtering logic is the same ... */ final itemData = doc.data() as Map<String, dynamic>; final itemIsAvailable = (itemData['available'] as bool? ?? false); final isAnyFilterActive = _searchQuery.isNotEmpty || _selectedCategory != 'All' || _appliedFilters.dietary != 'All' || _appliedFilters.priceRange != const RangeValues(0, 500) || _appliedFilters.sortBy != 'Default'; if (!isAnyFilterActive && !itemIsAvailable) return false; final itemName = (itemData['name'] ?? '').toString().toLowerCase(); final itemCategory = (itemData['category'] ?? '').toString(); final itemDietary = (itemData['dietary'] ?? '').toString(); final itemPrice = (itemData['price'] as num? ?? 0).toDouble(); final matchesCategory = _selectedCategory == 'All' || itemCategory == _selectedCategory; final matchesSearch = itemName.contains(_searchQuery.toLowerCase()); final matchesDietary = _appliedFilters.dietary == 'All' || itemDietary == _appliedFilters.dietary; final matchesPrice = itemPrice >= _appliedFilters.priceRange.start && itemPrice <= _appliedFilters.priceRange.end; return matchesCategory && matchesSearch && matchesDietary && matchesPrice; }).toList();

            // --- THIS IS THE NEW, ADVANCED SORTING LOGIC ---

            // 1. Determine the current time of day
            final hour = DateTime.now().hour;
            List<String> preferredCategories;
            if (hour < 12) { // Morning
              preferredCategories = ['Breakfast', 'Beverages'];
            } else if (hour < 17) { // Afternoon
              preferredCategories = ['Lunch', 'Main Course'];
            } else { // Evening
              preferredCategories = ['Main Course', 'Snacks', 'Beverages'];
            }

            // 2. Apply the multi-level sort
            filteredItems.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              // First, check for user override from the filter popup
              if (_appliedFilters.sortBy == 'Price: Low-High') {
                return ((dataA)['price'] as num).compareTo((dataB)['price'] as num);
              } else if (_appliedFilters.sortBy == 'Price: High-Low') {
                return ((dataB)['price'] as num).compareTo((dataA)['price'] as num);
              }

              // If user sort is 'Default', apply our smart sorting
              // Primary Sort: In-stock vs Out-of-stock
              final stockA = dataA['stock'] ?? 0;
              final stockB = dataB['stock'] ?? 0;
              if (stockA > 0 && stockB == 0) return -1; // a comes first
              if (stockA == 0 && stockB > 0) return 1;  // b comes first

              // Secondary Sort: Time-of-day preference
              final categoryA = dataA['category'] ?? '';
              final categoryB = dataB['category'] ?? '';
              final scoreA = preferredCategories.contains(categoryA) ? 1 : 0;
              final scoreB = preferredCategories.contains(categoryB) ? 1 : 0;
              if (scoreA > scoreB) return -1; // a (preferred) comes first
              if (scoreB > scoreA) return 1;  // b (preferred) comes first

              // Tertiary Sort: Alphabetical (as a tie-breaker)
              return (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (The rest of the UI build is exactly the same)
                Row(children: [ IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: _showFilterPopup, tooltip: 'Advanced Filters'), Expanded(child: SizedBox(height: 40, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (context, index) => const SizedBox(width: 8), itemBuilder: (context, index) { final category = categories[index]; final isSelected = category == _selectedCategory; return ChoiceChip(label: Text(category), selected: isSelected, onSelected: (selected) { setState(() { if (selected) { _selectedCategory = category; } else { _selectedCategory = 'All'; }}); }, backgroundColor: Colors.grey[200], selectedColor: Colors.teal, labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide.none); })))]),
                const SizedBox(height: 24),
                if (featuredItems.isNotEmpty) ...[FeaturedItemsBanner(featuredItems: featuredItems), const SizedBox(height: 24)],
                if (filteredItems.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon((_searchQuery.isNotEmpty || _selectedCategory != 'All' || _appliedFilters.dietary != 'All') ? Icons.filter_alt_off_rounded : Icons.search_off_rounded, size: 100, color: Colors.grey[300]), const SizedBox(height: 16), Text((_searchQuery.isNotEmpty || _selectedCategory != 'All' || _appliedFilters.dietary != 'All') ? 'No items match your filters.' : 'No items found for "$_searchQuery"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))]))),
                if (filteredItems.isNotEmpty) ...[const Text('Popular Dishes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16)],
                if (filteredItems.isNotEmpty) GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final itemDoc = filteredItems[index];
                    final itemData = itemDoc.data() as Map<String, dynamic>;
                    final menuItem = MenuItem(id: itemDoc.id, name: itemData['name'] ?? 'No Name', price: (itemData['price'] ?? 0.0).toDouble(), imageUrl: itemData['image'] ?? '', category: itemData['category'] ?? 'General', description: itemData['description'] ?? '', isAvailable: itemData['available'] ?? false, stock: itemData['stock'] ?? 0, status: itemData['status'] ?? '', dietary: itemData['dietary'] ?? '', createdAt: itemData['createdAt'] ?? Timestamp.now());
                    return MenuItemCard(item: menuItem);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}