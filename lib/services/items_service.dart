import 'package:graphql/client.dart';
import '../utils/config.dart';

class ItemsService {
  static final ItemsService _instance = ItemsService._internal();
  factory ItemsService() => _instance;
  ItemsService._internal();

  List<Map<String, dynamic>>? _cachedItems;
  bool _isLoading = false;
  DateTime? _lastFetched;

  // Cache duration - 30 minutes
  final Duration _cacheDuration = const Duration(minutes: 30);

  late final GraphQLClient _client = GraphQLClient(
    link: HttpLink(
      'https://api.stratz.com/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer ${Config.stratzApiKey}',
        'User-Agent': 'STRATZ_API',
        'Content-Type': 'application/json',
      },
    ),
    cache: GraphQLCache(),
  );

  String _formatItemName(String name) {
    // Replace underscores with spaces and capitalize each word
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');
  }

  bool get hasValidCache {
    if (_cachedItems == null || _lastFetched == null) return false;
    return DateTime.now().difference(_lastFetched!) < _cacheDuration;
  }

  Future<List<Map<String, dynamic>>> getItems({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && hasValidCache && _cachedItems != null) {
      return _cachedItems!;
    }

    // Prevent multiple simultaneous requests
    if (_isLoading) {
      // Wait for the current request to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedItems ?? [];
    }

    _isLoading = true;

    try {
      final QueryOptions options = QueryOptions(
        document: gql(r'''
        query ItemDetails {
          constants {
            items { 
              id 
              displayName 
              shortName
              image 
              stat {
                cost
              }
              language {
                description
                lore
                notes
              }
            }
          }
        }
        '''),
      );

      final result = await _client.query(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final items = (result.data?['constants']?['items'] as List?) ?? [];
      final processed =
          items
              .where((it) {
                // Filter out recipes and items without names
                final displayName = (it['displayName'] ?? '').toString().trim();
                final shortName = (it['shortName'] ?? '').toString().trim();

                if (displayName.isEmpty && shortName.isEmpty) {
                  return false; // Skip items without names
                }

                return !displayName.toLowerCase().contains('recipe') &&
                    !shortName.toLowerCase().contains('recipe');
              })
              .map<Map<String, dynamic>>((it) {
                final String img = (it['image'] ?? '').toString();
                final String cleaned = img
                    .split('?')
                    .first
                    .replaceAll('_lg', '');
                final String imageUrl =
                    'https://cdn.stratz.com/images/dota2/items/$cleaned';
                final stat = it['stat'] ?? {};
                final language = it['language'] ?? {};

                // Use displayName if available, otherwise fallback to shortName
                String itemName = (it['displayName'] ?? '').toString().trim();
                if (itemName.isEmpty) {
                  itemName =
                      (it['shortName'] ?? 'Unknown Item').toString().trim();
                }

                // Format the item name (replace underscores and capitalize)
                itemName = _formatItemName(itemName);

                return {
                  'id': it['id'],
                  'displayName': itemName,
                  'image': imageUrl,
                  'cost': stat['cost'] ?? 0,
                  'isNeutral': false, // Will determine this another way
                  'description': language['description'] ?? '',
                  'lore': language['lore'] ?? '',
                  'notes': language['notes'] ?? '',
                };
              })
              .toList();

      _cachedItems = processed;
      _lastFetched = DateTime.now();

      return processed;
    } finally {
      _isLoading = false;
    }
  }

  Map<String, dynamic>? getItemById(int itemId) {
    if (_cachedItems == null) return null;

    try {
      return _cachedItems!.firstWhere((item) => item['id'] == itemId);
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cachedItems = null;
    _lastFetched = null;
  }
}
