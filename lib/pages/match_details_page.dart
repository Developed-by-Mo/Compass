import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:graphql/client.dart';
import 'package:compass/pages/player_details_page.dart';
import 'dart:math';

import '../dota_hero.dart';
import '../services/player_services.dart';
import '../utils/config.dart';
import '../utils/theme_utils.dart';
import 'package:http/http.dart' as http;

import 'hero_info.dart';

class MatchDetailsPage extends StatefulWidget {
  final dynamic matchId;

  const MatchDetailsPage({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchDetailsPageState createState() => _MatchDetailsPageState();
}

enum SortType { networth, goldPerMinute, experiencePerMinute, heroDamage, towerDamage }

SortType _currentSort = SortType.networth;

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  Map<String, dynamic>? _matchData;
  Map<int, DotaHero>? _heroesMap;
  Map<int, String>? _itemImages;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }

  @override
  void dispose() {
    // If you have any controllers, animations, or stream subscriptions, dispose of them here
    super.dispose();
  }

  Widget _buildTeamHeader(String team, bool isWinner, bool isDarkMode) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/images/${team}.png',
              width: 80,
              height: 80,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isWinner
                          ? [
                        Color(0xFF1B5E20),  // Darker green
                        Color(0xFF4CAF50),  // Lighter green
                      ]
                          : [
                        Colors.grey[800]!.withOpacity(0.8),
                        Colors.grey[600]!.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    isWinner ? 'WON' : 'LOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // Item display widget with improved design
  Widget _buildItemImage(Map<int, String>? itemImages, int? itemId, bool isDarkMode) {
    final backgroundColor = isDarkMode
        ? Color.fromARGB(255, 20, 20, 20)
        : Colors.grey[300]!;

    if (itemId == null || itemId == 0 || itemImages == null || !itemImages.containsKey(itemId)) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
              Icons.block,
              color: Colors.grey[600],
              size: 20
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        itemImages[itemId]!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 40,
          height: 40,
          color: backgroundColor,
          child: Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Widget _buildNeutralItemImage(Map<int, String>? itemImages, int? itemId, bool isDarkMode) {
    final backgroundColor = isDarkMode
        ? Color.fromARGB(255, 20, 20, 20)
        : Colors.grey[300]!;

    if (itemId == null || itemId == 0 || itemImages == null || !itemImages.containsKey(itemId)) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[500]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
              Icons.block,
              color: Colors.grey[600],
              size: 20
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.grey[850]! : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          itemImages[itemId]!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading neutral item image: $error');
            print('Failed URL: ${itemImages[itemId]}');
            return Container(
              width: 40,
              height: 40,
              color: backgroundColor,
              child: Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchMatchDetails() async {
    try {
      // Fetch heroes and item images first
      _heroesMap = await PlayerService.fetchHeroes();
      _itemImages = await PlayerService.fetchItemImages();

      // Fetch match details using GraphQL
      final GraphQLClient client = GraphQLClient(
        link: HttpLink(
          'https://api.stratz.com/graphql',
          defaultHeaders: {
            'Authorization': Config.stratzApiKey,
            'User-Agent': 'STRATZ_API'
          },
        ),
        cache: GraphQLCache(),
      );

      final QueryOptions options = QueryOptions(
        document: gql(r'''
        query MatchDetails($matchId: Long!) {
          match(id: $matchId) {
            id
            durationSeconds
            didRadiantWin
            lobbyType
            startDateTime
            players {
              steamAccountId
              heroId
              isRadiant
              kills
              deaths
              assists
              numLastHits
              numDenies
              goldPerMinute
              networth
              experiencePerMinute
              level
              position
              item0Id
              item1Id
              item2Id
              item3Id
              item4Id
              item5Id
              backpack0Id
              backpack1Id
              backpack2Id
              neutral0Id
              towerDamage
              heroDamage
              heroHealing
            }
          }
        }
      '''),
        variables: {
          'matchId': widget.matchId,
        },
      );

      final QueryResult result = await client.query(options);

      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      setState(() {
        _matchData = result.data?['match'];
        _isLoading = false;
      });
    } catch (e) {
      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, bool isDarkMode) {
    final heroId = player['heroId'];
    final heroImageUrl = PlayerService.getHeroImageUrl(heroId, _heroesMap!);
    final heroName = PlayerService.getHeroName(heroId, _heroesMap!);
    final steamAccountId = player['steamAccountId']?.toString();
    final neutralItemId = player['neutral0Id'];
    final dotaHero = _heroesMap?[heroId];
    print('Player Hero ${player['heroId']} - Neutral Item ID: $neutralItemId');
    if (neutralItemId != null && neutralItemId != 0) {
      print('Neutral item image URL: ${_itemImages?[neutralItemId]}');
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchPlayerProfile(steamAccountId ?? ''),
      builder: (context, snapshot) {
        final playerProfile = snapshot.data?['profile'];
        final playerName = playerProfile?['personaname'] ?? 'Unknown Player';
        final avatarUrl = playerProfile?['avatarfull'];

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? Color.fromARGB(255, 20, 20, 20) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Hero Image (Stacked vertically)
                  Column(
                    children: [
                      // Steam Avatar
                      GestureDetector(
                        onTap: () {
                          if (steamAccountId != null && steamAccountId.isNotEmpty && playerName != 'Unknown Player') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerDetailsPage(
                                  playerName: playerName,
                                  accountId: steamAccountId,
                                  avatarUrl: avatarUrl ?? '',
                                  showAppBar: true,
                                ),
                              ),
                            );
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: avatarUrl != null
                              ? Image.network(
                            avatarUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(isDarkMode),
                          )
                              : _buildDefaultAvatar(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Hero Image
                      GestureDetector(
                        onTap: () {
                          if (dotaHero != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HeroInfo(hero: dotaHero),
                              ),
                            );
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            heroImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),

                  // Player Stats and Items
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          heroName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _getPositionText(player['position']),
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${player['kills']}/${player['deaths']}/${player['assists']}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'lib/icons/gold.png',
                              width: 16,
                              height: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${player['networth']}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Items
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildItemImage(_itemImages, player['item${i}Id'], isDarkMode),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 3; i < 6; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildItemImage(_itemImages, player['item${i}Id'], isDarkMode),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildItemImage(_itemImages, player['backpack${i}Id'], isDarkMode),
                            ),
                        ],
                      ),
                    ],
                  ),
                  _buildNeutralItemImage(_itemImages, player['neutral0Id'], isDarkMode),
                ],
              ),

              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(bool isDarkMode) {
    return Container(
      width: 50,
      height: 50,
      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
      child: Icon(
        Icons.person,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
      ),
    );
  }

  String _getPositionText(String position) {
    switch (position) {
      case 'POSITION_1':
        return 'Carry';
      case 'POSITION_2':
        return 'Mid';
      case 'POSITION_3':
        return 'Offlaner';
      case 'POSITION_4':
        return 'Soft Support';
      case 'POSITION_5':
        return 'Hard Support';
      default:
        return position;
    }
  }

  Future<Map<String, dynamic>?> _fetchPlayerProfile(String steamAccountId) async {
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

  Widget _buildHeroStatistics(bool isDarkMode) {
    List<Map<String, dynamic>> sortedPlayers = List.from(_matchData?['players'] ?? []);

    switch (_currentSort) {
      case SortType.goldPerMinute:
        sortedPlayers.sort((a, b) => (b['goldPerMinute'] ?? 0).compareTo(a['goldPerMinute'] ?? 0));
        break;
      case SortType.experiencePerMinute:
        sortedPlayers.sort((a, b) => (b['experiencePerMinute'] ?? 0).compareTo(a['experiencePerMinute'] ?? 0));
        break;
      case SortType.heroDamage:
        sortedPlayers.sort((a, b) => (b['heroDamage'] ?? 0).compareTo(a['heroDamage'] ?? 0));
        break;
      case SortType.towerDamage:
        sortedPlayers.sort((a, b) => (b['towerDamage'] ?? 0).compareTo(a['towerDamage'] ?? 0));
        break;
      case SortType.networth:
        sortedPlayers.sort((a, b) => (b['networth'] ?? 0).compareTo(a['networth'] ?? 0));
        break;
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hero Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatSortButton('GPM', SortType.goldPerMinute, isDarkMode),
              _buildStatSortButton('XPM', SortType.experiencePerMinute, isDarkMode),
              _buildStatSortButton('Hero Damage', SortType.heroDamage, isDarkMode),
              _buildStatSortButton('Tower Damage', SortType.towerDamage, isDarkMode),
            ],
          ),
        ),
        ...sortedPlayers.map((player) => _buildStatRow(player, isDarkMode)).toList(),
      ],
    );
  }

  Widget _buildStatSortButton(String label, SortType sortType, bool isDarkMode) {
    final isSelected = _currentSort == sortType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => setState(() {
          _currentSort = sortType;
        }),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
              : (isDarkMode ? Colors.grey[900] : Colors.grey[200]),
          foregroundColor: isSelected
              ? (isDarkMode ? Colors.white : Colors.black)
              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> player, bool isDarkMode) {
    final heroId = player['heroId'];
    final heroImageUrl = PlayerService.getHeroImageUrl(heroId, _heroesMap!);

    String getDisplayValue() {
      switch (_currentSort) {
        case SortType.goldPerMinute:
          return 'GPM: ${player['goldPerMinute'] ?? 'N/A'}';
        case SortType.experiencePerMinute:
          return 'XPM: ${player['experiencePerMinute'] ?? 'N/A'}';
        case SortType.heroDamage:
          return 'Hero Damage: ${player['heroDamage'] ?? 'N/A'}';
        case SortType.towerDamage:
          return 'Tower Damage: ${player['towerDamage'] ?? 'N/A'}';
        default:
          return 'Net Worth: ${player['networth'] ?? 'N/A'}';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Color.fromARGB(255, 20, 20, 20) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              heroImageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              getDisplayValue(),
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10)
          : Colors.white,
      appBar: AppBar(
        surfaceTintColor: isDarkMode
            ? const Color.fromARGB(255, 10, 10, 10)
            : Colors.white,
        title: Text(
          'Match Details',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 10, 10, 10)
            : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.grey[200] : Colors.black,))
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match Overview
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Match ID: ${widget.matchId}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Match Duration: ${_formatMatchDuration(_matchData?['durationSeconds'])}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${_matchData?['didRadiantWin'] ? 'Radiant' : 'Dire'} Victory',
                    style: TextStyle(
                      color: _matchData?['didRadiantWin']
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            SizedBox(height: 20),

            // Radiant Players
            _buildTeamHeader('Radiant', _matchData?['didRadiantWin'] ?? false, isDarkMode),
            ..._matchData?['players'] != null
                ? (_matchData!['players'] as List)
                .where((player) => player['isRadiant'] == true)
                .map((player) => _buildPlayerCard(player, isDarkMode))
                .toList()
                : [],

            SizedBox(height: 60),

// Dire Players
            _buildTeamHeader('Dire', !(_matchData?['didRadiantWin'] ?? false), isDarkMode),
            ..._matchData?['players'] != null
                ? (_matchData!['players'] as List)
                .where((player) => player['isRadiant'] == false)
                .map((player) => _buildPlayerCard(player, isDarkMode))
                .toList()
                : [],_buildHeroStatistics(isDarkMode),],
        ),
      ),
    );
  }

  String _formatMatchDuration(int? durationSeconds) {
    if (durationSeconds == null) return 'Unknown';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}