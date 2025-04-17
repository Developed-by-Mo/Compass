import 'package:flutter/material.dart';
import 'package:graphql/client.dart';

import '../utils/config.dart';

class HeroItems extends StatefulWidget {
  final int heroId;

  const HeroItems({Key? key, required this.heroId}) : super(key: key);

  @override
  _HeroItemsState createState() => _HeroItemsState();
}

class _HeroItemsState extends State<HeroItems> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String _sortOption = 'Most Purchased';
  String _searchQuery = '';

  late GraphQLClient _client;

  final HttpLink httpLink = HttpLink(
    'https://api.stratz.com/graphql',
    defaultHeaders: {
      'Authorization': Config.stratzApiKey,
      'User-Agent': 'STRATZ_API'
    },
  );

  @override
  void initState() {
    super.initState();
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
    _fetchItemData();
  }

  Future<void> _fetchItemData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final purchaseOptions = QueryOptions(
        document: gql(r'''
      query HeroItemPurchases($heroId: Short!) {
        heroStats {
          itemFullPurchase(heroId: $heroId, bracketBasicIds: []) {
            itemId
            matchCount
            winCount
          }
          itemBootPurchase(heroId: $heroId, bracketBasicIds: []) {
            itemId
            matchCount
            winCount
          }
          itemNeutral(heroId: $heroId, bracketBasicIds: []) {
            itemId
            matchCount
            winCount
          }
        }
      }
    '''),
        variables: {
          'heroId': widget.heroId,
        },
      );

      final itemsOptions = QueryOptions(
        document: gql(r'''
      query ItemDetails {
        constants {
          items {
            id
            displayName
            image
          }
        }
      }
    '''),
      );

      // Fetch both queries concurrently
      final results = await Future.wait([
        _client.query(purchaseOptions),
        _client.query(itemsOptions),
      ]);

      final purchaseResult = results[0];
      final itemsResult = results[1];

      // Extract raw data
      final fullPurchases = purchaseResult.data!['heroStats']['itemFullPurchase'] as List;
      final bootPurchases = purchaseResult.data!['heroStats']['itemBootPurchase'] as List;
      final neutralPurchases = purchaseResult.data!['heroStats']['itemNeutral'] as List;
      final itemDetails = itemsResult.data!['constants']['items'] as List;

      // Create a map of itemId to item details
      final itemDetailsMap = {
        for (var item in itemDetails) item['id']: item,
      };

      // Aggregate all purchases
      final aggregatedPurchases = <int, Map<String, dynamic>>{};

      void processPurchases(List<dynamic> purchases) {
        for (var purchase in purchases) {
          final itemId = purchase['itemId'] as int;
          if (!aggregatedPurchases.containsKey(itemId)) {
            aggregatedPurchases[itemId] = {
              'matchCount': purchase['matchCount'] as int,
              'winCount': purchase['winCount'] as int,
            };
          } else {
            aggregatedPurchases[itemId]!['matchCount'] += purchase['matchCount'] as int;
            aggregatedPurchases[itemId]!['winCount'] += purchase['winCount'] as int;
          }
        }
      }

      // Process each category of purchases
      processPurchases(fullPurchases);
      processPurchases(bootPurchases);
      processPurchases(neutralPurchases);

      // Convert aggregated data into the final format
      final processedItems = aggregatedPurchases.entries.map((entry) {
        final itemId = entry.key;
        final stats = entry.value;
        final itemDetail = itemDetailsMap[itemId];

        if (itemDetail == null || itemDetail['image'] == null) return null;

        final matchCount = stats['matchCount'] as int;
        final winCount = stats['winCount'] as int;

        return {
          'id': itemId,
          'name': itemDetail['displayName'] ?? 'Unknown Item',
          'image': 'https://cdn.stratz.com/images/dota2/items/${itemDetail['image'].split('?').first.replaceAll('_lg', '')}',
          'matchCount': matchCount,
          'winCount': winCount,
          'winRate': (winCount / matchCount * 100).toStringAsFixed(2),
        };
      }).whereType<Map<String, dynamic>>().toList();

      // Sort by match count initially
      processedItems.sort((a, b) => b['matchCount'].compareTo(a['matchCount']));

      setState(() {
        _items = processedItems;
        _filteredItems = processedItems;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching item data: $error');
      setState(() {
        _isLoading = false;
        _items = [];
        _filteredItems = [];
      });
    }
  }


  List<Map<String, dynamic>> _getDisplayItems() {
    // Filter items based on search query
    var filteredItems = _searchQuery.isEmpty
        ? _items
        : _items.where((item) =>
        item['name'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    // Create a copy to avoid modifying the original list
    var sortedItems = List<Map<String, dynamic>>.from(filteredItems);

    // Apply sorting
    switch (_sortOption) {
      case 'Most Purchased':
        sortedItems.sort((a, b) =>
            int.parse(b['matchCount'].toString()).compareTo(int.parse(a['matchCount'].toString()))
        );
        break;
      case 'Highest Win Rate':
        sortedItems.sort((a, b) =>
            double.parse(b['winRate']).compareTo(double.parse(a['winRate']))
        );
        break;
      case 'Lowest Win Rate':
        sortedItems.sort((a, b) =>
            double.parse(a['winRate']).compareTo(double.parse(b['winRate']))
        );
        break;
    }

    return sortedItems;
  }

  void _sortItems(List<Map<String, dynamic>> items) {
    switch (_sortOption) {
      case 'Most Purchased':
        items.sort((a, b) => int.parse(b['matchCount'].toString()).compareTo(int.parse(a['matchCount'].toString())));
        break;
      case 'Highest Win Rate':
        items.sort((a, b) => double.parse(b['winRate']).compareTo(double.parse(a['winRate'])));
        break;
      case 'Lowest Win Rate':
        items.sort((a, b) => double.parse(a['winRate']).compareTo(double.parse(b['winRate'])));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    // Get display items (filtered and sorted)
    final displayItems = _getDisplayItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextField(
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              hintText: 'Search Items...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontFamily: "Inter",
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15.0),
            ),
            cursorColor: isDarkMode ? Colors.white : Colors.black,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontFamily: "Inter",
            ),
          ),
        ),
        SizedBox(height: 10),
        DropdownButton<String>(
          borderRadius: BorderRadius.circular(10),
          dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
          padding: EdgeInsets.only(left: 10, right: 10),
          value: _sortOption,
          items: <String>[
            'Most Purchased',
            'Highest Win Rate',
            'Lowest Win Rate',
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600), // Text color
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _sortOption = newValue!;
            });
          },
          iconEnabledColor: isDarkMode ? Colors.white : Colors.black, // Dropdown arrow color
          style: TextStyle(
            color: Colors.white, // Text color for the selected item
            fontSize: 16,
          ),
        ),

        SizedBox(height: 10),
        _isLoading
            ? Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 140.0),
            child: CircularProgressIndicator(
              color: isDarkMode ? Colors.grey[200] : Colors.black,
            ),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            var item = displayItems[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16.0),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item['image'],
                      width: 70.0,
                      height: 70.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, size: 50);
                      },
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Matches: ${item['matchCount']}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          'Win Rate: ${item['winRate']}%',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}