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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  FilterSettings _appliedFilters = FilterSettings();

  @override
  void initState() { super.initState(); _searchController.addListener(() { setState(() { _searchQuery = _searchController.text; }); }); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _showFilterPopup() async {
    final result = await showModalBottomSheet<FilterSettings>(
      context: context, isScrollControlled: true,
      builder: (context) => FilterPopup(initialSettings: _appliedFilters),
    );
    if (result != null) {
      setState(() { _appliedFilters = result; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Hi, Akshay!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('What would you like to eat?', style: TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search for food or snacks...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none))),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
            if (snapshot.hasError) return ErrorScreen(onRetry: () => setState(() {}));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No menu items available.'));

            final allDocs = snapshot.data!.docs;
            final allMenuItems = allDocs.map((doc) {
              final itemData = doc.data() as Map<String, dynamic>;
              return MenuItem(id: doc.id, name: itemData['name'] ?? 'No Name', price: (itemData['price'] ?? 0.0).toDouble(), imageUrl: itemData['image'] ?? '', category: itemData['category'] ?? 'General', description: itemData['description'] ?? '', isAvailable: itemData['available'] ?? false, stock: itemData['stock'] ?? 0, status: itemData['status'] ?? '', dietary: itemData['dietary'] ?? '', createdAt: itemData['createdAt'] ?? Timestamp.now());
            }).toList();

            final availableForBanner = allMenuItems.where((item) => item.isAvailable).toList();
            final shuffledItems = availableForBanner..shuffle();
            final featuredItems = shuffledItems.take(5).toList();

            final categoriesSet = allMenuItems.map((item) => item.category).toSet();
            final categories = ['All', ...categoriesSet.toList()];

            final isAnyFilterActive = _searchQuery.isNotEmpty || _selectedCategory != 'All' || _appliedFilters.dietary != 'All' || _appliedFilters.priceRange != const RangeValues(0, 500) || _appliedFilters.sortBy != 'Default';

            var filteredItems = allMenuItems.where((item) {
              if (!isAnyFilterActive && !item.isAvailable) return false;
              final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
              final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesDietary = _appliedFilters.dietary == 'All' || item.dietary == _appliedFilters.dietary;
              final matchesPrice = item.price >= _appliedFilters.priceRange.start && item.price <= _appliedFilters.priceRange.end;
              return matchesCategory && matchesSearch && matchesDietary && matchesPrice;
            }).toList();

            final hour = DateTime.now().hour;
            List<String> preferredCategories;
            if (hour < 12) { preferredCategories = ['Breakfast', 'Beverages']; } else if (hour < 17) { preferredCategories = ['Lunch', 'Main Course']; } else { preferredCategories = ['Main Course', 'Snacks', 'Beverages']; }

            filteredItems.sort((a, b) {
              if (_appliedFilters.sortBy == 'Price: Low-High') return a.price.compareTo(b.price);
              if (_appliedFilters.sortBy == 'Price: High-Low') return b.price.compareTo(a.price);
              if ((a.stock > 0 && b.stock == 0)) return -1;
              if ((a.stock == 0 && b.stock > 0)) return 1;
              final scoreA = preferredCategories.contains(a.category) ? 1 : 0;
              final scoreB = preferredCategories.contains(b.category) ? 1 : 0;
              if (scoreA != scoreB) return scoreB.compareTo(scoreA);
              return a.name.compareTo(b.name);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: _showFilterPopup, tooltip: 'Advanced Filters'), Expanded(child: SizedBox(height: 40, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (context, index) => const SizedBox(width: 8), itemBuilder: (context, index) { final category = categories[index]; final isSelected = category == _selectedCategory; return ChoiceChip(label: Text(category), selected: isSelected, onSelected: (selected) { setState(() { if (selected) { _selectedCategory = category; } else { _selectedCategory = 'All'; }}); }, backgroundColor: Colors.grey[200], selectedColor: Theme.of(context).primaryColor, labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide.none); })))]),
                const SizedBox(height: 24),
                if (featuredItems.isNotEmpty) ...[FeaturedItemsBanner(featuredItems: featuredItems, allItems: allMenuItems), const SizedBox(height: 24)],
                if (filteredItems.isNotEmpty) ...[const Text('Popular Dishes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16)],
                if (filteredItems.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isAnyFilterActive ? Icons.filter_alt_off_rounded : Icons.search_off_rounded, size: 100, color: Colors.grey[300]), const SizedBox(height: 16), Text(isAnyFilterActive ? 'No items match your filters.' : 'No items found for "$_searchQuery"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))]))),
                if (filteredItems.isNotEmpty) GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final menuItem = filteredItems[index];
                    // Pass the complete list of items to the card
                    return MenuItemCard(item: menuItem, allItems: allMenuItems);
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

