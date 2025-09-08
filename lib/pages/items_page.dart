import 'package:flutter/material.dart';

import '../utils/theme_utils.dart';
import '../widgets/item_tile.dart';
import 'item_detail_page.dart';
import '../services/items_service.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ItemsService _itemsService = ItemsService();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems =
            _allItems.where((i) {
              final name = (i['displayName'] ?? '').toString().toLowerCase();
              return name.contains(q);
            }).toList();
      }
    });
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final items = await _itemsService.getItems();

      setState(() {
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load items';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.grey[200] : Colors.black,
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Text(
          _error,
          style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        // Add top spacing similar to search page
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.backpack,
                  size: 22,
                  color:
                      isDarkMode
                          ? Colors.white
                          : const Color.fromARGB(255, 66, 66, 66),
                ),
                const SizedBox(width: 10),
                Text(
                  "Items",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 22.0,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode
                            ? Colors.white
                            : const Color.fromARGB(255, 66, 66, 66),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      hintText: 'Search Items...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    cursorColor: isDarkMode ? Colors.white : Colors.black,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _filteredItems.isNotEmpty
            ? SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _filteredItems[index];
                  return ItemTile(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailPage(item: item),
                        ),
                      );
                    },
                  );
                }, childCount: _filteredItems.length),
              ),
            )
            : SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: const Color.fromARGB(255, 82, 82, 82),
                      size: 80.0,
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 140.0),
                      child: Text(
                        "No items found",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 24.0,
                          color: const Color.fromARGB(255, 82, 82, 82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        SliverToBoxAdapter(
          child:
              _filteredItems.isNotEmpty
                  ? SizedBox(height: 90)
                  : null, // Space at the bottom only when there are items
        ),
      ],
    );
  }
}
