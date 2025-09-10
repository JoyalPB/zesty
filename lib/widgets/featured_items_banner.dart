import 'dart:async';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'item_details_popup.dart';

class FeaturedItemsBanner extends StatefulWidget {
  final List<MenuItem> featuredItems;
  const FeaturedItemsBanner({super.key, required this.featuredItems});

  @override
  State<FeaturedItemsBanner> createState() => _FeaturedItemsBannerState();
}

class _FeaturedItemsBannerState extends State<FeaturedItemsBanner> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
      // 1. INCREASE THE WIDTH by making the viewport fraction larger
      viewportFraction: 0.9, // Was 0.85, now 0.9
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.featuredItems.length > 1) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_currentPage < widget.featuredItems.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      });
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. DECREASE THE HEIGHT of the banner
    return SizedBox(
      height: 180, // Was 200, now 180
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) { _stopAutoScroll(); }
              else if (notification is ScrollEndNotification) { _startAutoScroll(); }
              return true;
            },
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                return PageView.builder(
                  controller: _pageController,
                  itemCount: widget.featuredItems.length,
                  onPageChanged: (index) {
                    setState(() { _currentPage = index; });
                  },
                  itemBuilder: (context, index) {
                    final item = widget.featuredItems[index];
                    double scale = 1.0;
                    double opacity = 1.0;
                    if (_pageController.position.haveDimensions) {
                      final page = _pageController.page ?? 0.0;
                      final difference = (page - index).abs();
                      scale = 1.0 - (difference * 0.15);
                      opacity = 1.0 - (difference * 0.5);
                    }
                    return Transform.scale(
                      scale: scale.clamp(0.85, 1.0),
                      child: Opacity(
                        opacity: opacity.clamp(0.5, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0), // Reduced padding slightly
                          child: GestureDetector(
                            onTap: () { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => ItemDetailsPopup(item: item)); },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.fastfood, color: Colors.grey))),
                                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]))),
                                  Positioned(bottom: 16, left: 16, right: 16, child: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10.0, color: Colors.black)]))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.featuredItems.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 24.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}