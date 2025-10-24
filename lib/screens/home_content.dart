import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late Future<String> _usernameFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  FilterSettings _appliedFilters = FilterSettings();

  @override
  void initState() {
    super.initState();
    _usernameFuture = _fetchUsername();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<String> _fetchUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc.data()?['username'] ?? 'Guest';
      }
      return 'Guest';
    } catch (e) {
      print("Error fetching username: $e");
      return 'Friend';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterPopup() async {
    final result = await showModalBottomSheet<FilterSettings>(
        context: context,
        isScrollControlled: true,
        builder: (context) => FilterPopup(initialSettings: _appliedFilters));
    if (result != null) {
      setState(() {
        _appliedFilters = result;
      });
    }
  }

  // --- NEW ---
  // Helper method to build and show the item details popup
  Future<void> _showItemDetailsPopup(MenuItem item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28.0),
                    topRight: Radius.circular(28.0),
                  ),
                  child: Hero(
                    tag: 'item_image_${item.id}', // Ensure this tag matches MenuItemCard
                    child: Image.network(
                      item.imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(
                        height: 200,
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- THIS IS THE NEW REVIEW WIDGET ---
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            item.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${item.reviewCount} reviews)',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // --- END OF NEW REVIEW WIDGET ---
                      const SizedBox(height: 16),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Add to cart logic
                              Navigator.of(context).pop(); // Close dialog
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Add to Cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ... (Your existing FutureBuilder for username)
        FutureBuilder<String>(
          future: _usernameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Hi, ...',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey));
            }
            final username = snapshot.data ?? 'there';
            return Text('Hi, $username!',
                style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
          },
        ),
        const SizedBox(height: 8),
        const Text('What would you like to eat?',
            style: TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 24),
        // ... (Your existing TextField)
        TextField(
            controller: _searchController,
            decoration: InputDecoration(
                hintText: 'Search for food or snacks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none))),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return ErrorScreen(onRetry: () => setState(() {}));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No menu items available.'));
            }

            final allItems = snapshot.data!.docs;
            final allMenuItems = allItems.map((doc) {
              final itemData = doc.data() as Map<String, dynamic>;
              return MenuItem(
                id: doc.id,
                name: itemData['name'] ?? 'No Name',
                price: (itemData['price'] ?? 0.0).toDouble(),
                imageUrl: itemData['image'] ?? '',
                category: itemData['category'] ?? 'General',
                description: itemData['description'] ?? '',
                isAvailable: itemData['available'] ?? false,
                stock: itemData['stock'] ?? 0,
                status: itemData['status'] ?? '',
                dietary: itemData['dietary'] ?? '',
                createdAt: itemData['createdAt'] ?? Timestamp.now(),
                // --- MODIFIED ---
                // Read the new review data from Firestore
                averageRating: (itemData['averageRating'] ?? 0.0).toDouble(),
                reviewCount: itemData['reviewCount'] ?? 0,
              );
            }).toList();

            // ... (Your existing logic for featuredItems, categories, filtering, and sorting)
            final availableForBanner =
            allMenuItems.where((item) => item.isAvailable).toList();
            final shuffledItems = availableForBanner..shuffle();
            final featuredItems = shuffledItems.take(5).toList();
            final categoriesSet = allItems
                .map((doc) =>
            (doc.data() as Map<String, dynamic>)['category'] ??
                'Uncategorized')
                .toSet();
            final categories = ['All', ...categoriesSet.toList()];

            var filteredItems = allItems.where((doc) {
              final itemData = doc.data() as Map<String, dynamic>;
              final itemIsAvailable = (itemData['available'] as bool? ?? false);
              final isAnyFilterActive = _searchQuery.isNotEmpty ||
                  _selectedCategory != 'All' ||
                  _appliedFilters.dietary != 'All' ||
                  _appliedFilters.priceRange != const RangeValues(0, 500) ||
                  _appliedFilters.sortBy != 'Default';
              if (!isAnyFilterActive && !itemIsAvailable) return false;
              final itemName = (itemData['name'] ?? '').toString().toLowerCase();
              final itemCategory = (itemData['category'] ?? '').toString();
              final itemDietary = (itemData['dietary'] ?? '').toString();
              final itemPrice = (itemData['price'] as num? ?? 0).toDouble();
              final matchesCategory = _selectedCategory == 'All' ||
                  itemCategory == _selectedCategory;
              final matchesSearch = itemName.contains(_searchQuery.toLowerCase());
              final matchesDietary = _appliedFilters.dietary == 'All' ||
                  itemDietary == _appliedFilters.dietary;
              final matchesPrice = itemPrice >= _appliedFilters.priceRange.start &&
                  itemPrice <= _appliedFilters.priceRange.end;
              return matchesCategory &&
                  matchesSearch &&
                  matchesDietary &&
                  matchesPrice;
            }).toList();

            final hour = DateTime.now().hour;
            List<String> preferredCategories;
            if (hour < 12) {
              preferredCategories = ['Breakfast', 'Beverages'];
            } else if (hour < 17) {
              preferredCategories = ['Lunch', 'Main Course'];
            } else {
              preferredCategories = ['Main Course', 'Snacks', 'Beverages'];
            }

            filteredItems.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              if (_appliedFilters.sortBy == 'Price: Low-High') {
                return ((dataA)['price'] as num)
                    .compareTo((dataB)['price'] as num);
              } else if (_appliedFilters.sortBy == 'Price: High-Low') {
                return ((dataB)['price'] as num)
                    .compareTo((dataA)['price'] as num);
              }

              // --- MODIFIED ---
              // Add sorting by rating (optional but good)
              if (_appliedFilters.sortBy == 'Rating: High-Low') {
                return ((dataB)['averageRating'] as num? ?? 0)
                    .compareTo((dataA)['averageRating'] as num? ?? 0);
              }

              final stockA = dataA['stock'] ?? 0;
              final stockB = dataB['stock'] ?? 0;
              if (stockA > 0 && stockB == 0) return -1;
              if (stockA == 0 && stockB > 0) return 1;

              final categoryA = dataA['category'] ?? '';
              final categoryB = dataB['category'] ?? '';
              final scoreA = preferredCategories.contains(categoryA) ? 1 : 0;
              final scoreB = preferredCategories.contains(categoryB) ? 1 : 0;
              if (scoreA > scoreB) return -1;
              if (scoreB > scoreA) return 1;

              return (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
            });


            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (Your existing filter/category row)
                Row(children: [
                  IconButton(
                      icon: const Icon(Icons.filter_list_alt),
                      onPressed: _showFilterPopup,
                      tooltip: 'Advanced Filters'),
                  Expanded(
                      child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final isSelected = category == _selectedCategory;
                                return ChoiceChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategory = category;
                                        } else {
                                          _selectedCategory = 'All';
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.teal,
                                    labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                    side: BorderSide.none);
                              })))
                ]),
                const SizedBox(height: 24),
                if (featuredItems.isNotEmpty) ...[
                  FeaturedItemsBanner(featuredItems: featuredItems),
                  const SizedBox(height: 24)
                ],
                // ... (Your existing 'No items found' logic)
                if (filteredItems.isEmpty)
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 48.0, horizontal: 16.0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    (_searchQuery.isNotEmpty ||
                                        _selectedCategory != 'All' ||
                                        _appliedFilters.dietary != 'All')
                                        ? Icons.filter_alt_off_rounded
                                        : Icons.search_off_rounded,
                                    size: 100,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                    (_searchQuery.isNotEmpty ||
                                        _selectedCategory != 'All' ||
                                        _appliedFilters.dietary != 'All')
                                        ? 'No items match your filters.'
                                        : 'No items found for "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey))
                              ]))),
                if (filteredItems.isNotEmpty) ...[
                  const Text('Popular Dishes',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16)
                ],
                if (filteredItems.isNotEmpty)
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final itemDoc = filteredItems[index];
                      final itemData = itemDoc.data() as Map<String, dynamic>;
                      final menuItem = MenuItem(
                        id: itemDoc.id,
                        name: itemData['name'] ?? 'No Name',
                        price: (itemData['price'] ?? 0.0).toDouble(),
                        imageUrl: itemData['image'] ?? '',
                        category: itemData['category'] ?? 'General',
                        description: itemData['description'] ?? '',
                        isAvailable: itemData['available'] ?? false,
                        stock: itemData['stock'] ?? 0,
                        status: itemData['status'] ?? '',
                        dietary: itemData['dietary'] ?? '',
                        createdAt: itemData['createdAt'] ?? Timestamp.now(),
                        // --- MODIFIED ---
                        // Pass the review data to the MenuItem object
                        averageRating: (itemData['averageRating'] ?? 0.0).toDouble(),
                        reviewCount: itemData['reviewCount'] ?? 0,
                      );

                      // --- MODIFIED ---
                      // Wrap the card in an InkWell to make it tappable
                      return InkWell(
                        onTap: () {
                          // Show the popup when tapped
                          _showItemDetailsPopup(menuItem);
                        },
                        child: MenuItemCard(item: menuItem),
                      );
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
