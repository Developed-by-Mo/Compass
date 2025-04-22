// Player Services

import 'dart:convert';

import 'package:graphql/client.dart';

import 'package:http/http.dart' as http;

import '../dota_hero.dart';
import '../utils/config.dart';

class PlayerService {
  static const _baseUrl = 'https://api.opendota.com/api';
  static final HttpLink _httpLink = HttpLink(
    'https://api.stratz.com/graphql',
    defaultHeaders: {
      'Authorization': Config.stratzApiKey,
      'User-Agent': 'STRATZ_API'
    },
  );

  static Future<Map<int, DotaHero>> fetchHeroes() async {
    final response = await http.get(Uri.parse('$_baseUrl/heroes'));

    if (response.statusCode == 200) {
      final List<dynamic> heroesData = json.decode(response.body);
      final Map<int, DotaHero> heroesMap = {};

      for (var heroData in heroesData) {
        final hero = DotaHero.fromJson(heroData);
        heroesMap[hero.id] = hero;
      }

      return heroesMap;
    } else {
      throw Exception('Failed to fetch heroes');
    }
  }

  static Future<Map<int, String>> fetchItemImages() async {
    final QueryOptions options = QueryOptions(
      document: gql(r'''
    query ItemDetails {
      constants {
        items {
          id
          image
          name
        }
      }
    }
  '''),
    );

    final QueryResult result = await _client.query(options);

    Map<int, String> itemImages = {};
    final itemData = result.data?['constants']['items'] ?? [];

    for (var item in itemData) {
      if (item['name'] != null) {
        String itemName = item['name'] as String;

        // Remove 'item_' prefix if it exists
        if (itemName.startsWith('item_')) {
          itemName = itemName.substring(5); // Remove 'item_' prefix
        }

        // Construct the URL with the sanitized name
        String imageUrl = 'https://cdn.stratz.com/images/dota2/items/$itemName.png';
        itemImages[item['id']] = imageUrl;
      }
    }

    return itemImages;
  }

  // Create a GraphQL client
  static final GraphQLClient _client = GraphQLClient(
    link: _httpLink,
    cache: GraphQLCache(),
  );

  static Future<List<Map<String, dynamic>>> fetchWinrateHistory(String accountId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(r'''
      query WinrateHistory($steamAccountId: Long!, $take: Int!) {
        player(steamAccountId: $steamAccountId) {
          matches(request: {take: $take}) {
            id
            didRadiantWin
            players {
              steamAccountId
              isRadiant
            }
          }
        }
      }
      '''),
        variables: {
          'steamAccountId': int.parse(accountId),
          'take': 100, // Fetch 100 matches
        },
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        print('GraphQL Exception: ${result.exception}');
        throw Exception('Failed to fetch winrate history from STRATZ');
      }

      final playerData = result.data?['player'];
      if (playerData == null || playerData['matches'] == null) {
        throw Exception('No matches data available');
      }

      final matches = (playerData['matches'] as List)
          .cast<Map<String, dynamic>>()
          .toList();

      // Calculate rolling winrate every 10 matches
      List<Map<String, dynamic>> winrateHistory = [];
      int currentWins = 0;
      int currentMatches = 0;

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];

        // Find the player's match data
        final playerMatchData = (match['players'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (player) => player['steamAccountId'].toString() == accountId,
          orElse: () => <String, dynamic>{},
        );

        if (playerMatchData.isEmpty) continue;

        // Determine if this match was a win
        bool isPlayerRadiant = playerMatchData['isRadiant'] ?? false;
        bool didPlayerWin = match['didRadiantWin'] == isPlayerRadiant;

        // Update current wins and matches
        currentMatches++;
        if (didPlayerWin) {
          currentWins++;
        }

        // Record winrate every 10 matches
        if (currentMatches % 10 == 0) {
          winrateHistory.add({
            'matchCount': currentMatches,
            'winrate': currentMatches > 0
                ? (currentWins / currentMatches * 100).toStringAsFixed(2)
                : '0.00'
          });
        }
      }

      // Ensure we add the final winrate point if not already added
      if (currentMatches % 10 != 0) {
        winrateHistory.add({
          'matchCount': currentMatches,
          'winrate': currentMatches > 0
              ? (currentWins / currentMatches * 100).toStringAsFixed(2)
              : '0.00'
        });
      }

      return winrateHistory;
    } catch (error, stackTrace) {
      print('Error fetching winrate history from STRATZ: $error');
      print('Stacktrace: $stackTrace');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchPlayerProfile(String steamAccountId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.opendota.com/api/players/$steamAccountId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching player profile: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> fetchPlayerStats(String accountId) async {
    try {
      // Create a more verbose GraphQL client with error handling
      final GraphQLClient client = GraphQLClient(
        link: HttpLink(
          'https://api.stratz.com/graphql',
          defaultHeaders: {
            'Authorization': Config.stratzApiKey,
            'Content-Type': 'application/json',
            'User-Agent': 'STRATZ_API'
          },
        ),
        cache: GraphQLCache(),
      );

      final QueryOptions options = QueryOptions(
        document: gql(r'''
      query PlayerStats($steamAccountId: Long!) {
        player(steamAccountId: $steamAccountId) {
          matchCount
          winCount
          firstMatchDate
        }
      }
      '''),
        variables: {
          'steamAccountId': int.parse(accountId),
        },
      );

      final QueryResult result = await client.query(options);

      // Detailed error logging
      if (result.hasException) {
        print('Full GraphQL Exception: ${result.exception}');

        // Check specific types of exceptions
        if (result.exception?.linkException != null) {
          print('Link Exception: ${result.exception?.linkException}');
        }

        if (result.exception?.graphqlErrors.isNotEmpty == true) {
          result.exception?.graphqlErrors.forEach((error) {
            print('GraphQL Error: ${error.message}');
          });
        }

        throw Exception('Detailed GraphQL query failed');
      }

      // More robust data extraction
      final playerData = result.data?['player'];
      if (playerData == null) {
        print('No player data found for account ID: $accountId');
        throw Exception('No player data available');
      }

      return {
        'matchCount': playerData['matchCount'] ?? 0,
        'winCount': playerData['winCount'] ?? 0,
        'firstMatchDate': playerData['firstMatchDate'] ?? 0,
      };
    } catch (error, stackTrace) {
      print('Comprehensive error fetching player stats:');
      print('Error: $error');
      print('Stacktrace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHeroStats(String accountId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players/$accountId/heroes'),
    );

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch hero stats');
    }
  }

  static String convertToRelativeTime(int epochSeconds) {
    // Convert epoch seconds to DateTime
    final matchDateTime = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    final now = DateTime.now();

    // Calculate the difference
    final difference = now.difference(matchDateTime);

    // Convert to different time units
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentMatches(String accountId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(r'''
    query RecentMatches($steamAccountId: Long!, $take: Int!) {
      player(steamAccountId: $steamAccountId) {
        matches(request: {take: $take}) {
          id
          didRadiantWin
          durationSeconds
          startDateTime
          endDateTime
          numHumanPlayers
          gameMode
          lobbyType
          players {
            steamAccountId
            heroId
            isRadiant
            kills
            deaths
            assists
            item0Id
            item1Id
            item2Id
            item3Id
            item4Id
            item5Id
          }
        }
      }
    }
  '''),
        variables: {
          'steamAccountId': int.parse(accountId),
          'take': 20, // Limit to the 10 most recent matches
        },
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        print('GraphQL Exception: ${result.exception}');
        throw Exception('Failed to fetch recent matches from STRATZ');
      }

      final playerData = result.data?['player'];
      if (playerData == null || playerData['matches'] == null) {
        throw Exception('No matches data available');
      }

      final matches = (playerData['matches'] as List)
          .map((match) {
        // Find the player's specific match data
        final playerMatchData = (match['players'] as List)
            .cast<Map<String, dynamic>>() // Ensure type casting
            .firstWhere(
              (player) => player['steamAccountId'].toString() == accountId,
          orElse: () => <String, dynamic>{}, // Return an empty map instead of null
        );

        // If no player match data found, skip this match
        if (playerMatchData.isEmpty) return null;

        return {
          'id': match['id'] ?? 0,
          'hero_id': playerMatchData['heroId'] ?? 0,
          'player_slot': playerMatchData['isRadiant'] == true ? 0 : 5,
          'radiant_win': match['didRadiantWin'] ?? false,
          'startDateTime': match['startDateTime'] ?? 0,
          'duration': match['durationSeconds'] ?? 0,
          'kills': playerMatchData['kills'] ?? 0,
          'deaths': playerMatchData['deaths'] ?? 0,
          'assists': playerMatchData['assists'] ?? 0,
          'gameMode': match['gameMode'] ?? 'Unknown',
          // Add item IDs to the match data
          'item0Id': playerMatchData['item0Id'] ?? 0,
          'item1Id': playerMatchData['item1Id'] ?? 0,
          'item2Id': playerMatchData['item2Id'] ?? 0,
          'item3Id': playerMatchData['item3Id'] ?? 0,
          'item4Id': playerMatchData['item4Id'] ?? 0,
          'item5Id': playerMatchData['item5Id'] ?? 0,
        };
      })
          .whereType<Map<String, dynamic>>() // Filter out any null entries
          .toList();

      return matches;
    } catch (error, stackTrace) {
      print('Error fetching recent matches from STRATZ: $error');
      print('Stacktrace: $stackTrace');
      rethrow;
    }
  }


  // static Future<List<Map<String, dynamic>>> fetchRecentMatches(String accountId) async {
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/players/$accountId/recentMatches'),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
  //   } else {
  //     throw Exception('Failed to fetch recent matches');
  //   }
  // }

  static String getHeroImageUrl(int heroId, Map<int, DotaHero> heroesMap) {
    if (heroesMap.containsKey(heroId)) {
      final hero = heroesMap[heroId]!;
      String formattedName = hero.localizedName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '');

      // Check for custom URL first
      if (DotaHero.urlExceptions.containsKey(formattedName)) {
        return DotaHero.urlExceptions[formattedName]!;
      }

      // Apply name exceptions if needed
      if (DotaHero.nameExceptions.containsKey(formattedName)) {
        formattedName = DotaHero.nameExceptions[formattedName]!;
      }

      // Default URL
      return 'https://cdn.dota2.com/apps/dota2/images/heroes/${formattedName}_full.png';
    }
    return ''; // Return empty string if hero not found
  }

  static String getHeroName(int heroId, Map<int, DotaHero> heroesMap) {
    return heroesMap.containsKey(heroId)
        ? heroesMap[heroId]!.localizedName
        : 'Unknown Hero';
  }
}