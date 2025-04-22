// Hero Info Page

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:compass/dota_hero.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:graphql/client.dart';
import 'package:compass/utils/config.dart';

import 'hero_items_page.dart';

class CustomToggle extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final Function(int) onToggle;
  final bool isDarkMode;

  const CustomToggle({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onToggle,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 300,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(
          items.length,
              (index) {
            bool isSelected = selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onToggle(index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode ? Colors.grey[800] : Colors.grey[600])
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      items[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode ? Colors.white70 : Colors.black87),
                        fontFamily: "Inter",
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HeroInfo extends StatefulWidget {
  final DotaHero hero;

  const HeroInfo({
    Key? key,
    required this.hero,
  }) : super(key: key);

  @override
  _HeroInfoState createState() => _HeroInfoState();
}

class _HeroInfoState extends State<HeroInfo> {
  List<Map<String, dynamic>> _matchups = [];
  String _searchQuery = '';
  String _sortOption = 'Highest Win Rate';
  bool _isLoading = true;
  int _currentTabIndex = 0;
  Map<String, dynamic> _heroStats = {};
  bool _isStatsLoading = false;

  Future<DotaHero> fetchCompleteHeroData(int heroId) async {
    final response = await http.get(Uri.parse('https://api.opendota.com/api/heroes'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      // Find the hero with matching ID
      var heroData = jsonResponse.firstWhere((hero) => hero['id'] == heroId);
      return DotaHero.fromJson(heroData);
    } else {
      throw Exception('Failed to load hero data');
    }
  }

  // STRATZ API setup with User-Agent header
  final HttpLink httpLink = HttpLink(
    'https://api.stratz.com/graphql',
    defaultHeaders: {
      'Authorization': Config.stratzApiKey,
      'User-Agent': 'STRATZ_API'
    },
  );

  Widget _buildMatchupItem(Map<String, dynamic> matchup, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        try {
          // Fetch complete hero data before navigation
          DotaHero completeHero = await fetchCompleteHeroData(matchup['opponent_hero_id']);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HeroInfo(hero: completeHero),
            ),
          );
        } catch (error) {
          print('Error fetching complete hero data: $error');
          // Optionally show an error message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load hero details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background with blur
              Stack(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: Image.network(
                      matchup['opponent_hero_image'],
                      width: double.infinity,
                      height: 100.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          alignment: Alignment.center,
                          child: Icon(Icons.error, size: 50, color: Colors.redAccent),
                        );
                      },
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: double.infinity,
                      height: 100.0,
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              // Foreground content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        matchup['opponent_hero_image'],
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
                            matchup['opponent_hero_name'],
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Games Played: ${matchup['games_played']}',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white70,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Win Rate: ${matchup['win_rate']}%',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Add a subtle arrow icon to indicate it's clickable
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchHeroStats() async {
    setState(() {
      _isStatsLoading = true;
    });

    try {
      final QueryOptions options = QueryOptions(
        document: gql(r'''
        query HeroStats($heroId: Short!) {
          constants {
            hero(id: $heroId) {
              stats {
                attackType
                startingArmor
                startingMagicArmor
                startingDamageMin
                startingDamageMax
                attackRate
                attackRange
                strengthBase
                intelligenceBase
                agilityBase
                hpRegen
                mpRegen
                moveSpeed
                moveTurnRate
                visionDaytimeRange
                visionNighttimeRange
                complexity
              }
            }
          }
        }
      '''),
        variables: {
          'heroId': widget.hero.id,
        },
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        print('GraphQL Error: ${result.exception.toString()}');
        throw Exception('Failed to load hero stats');
      }

      setState(() {
        _heroStats = result.data?['constants']['hero']['stats'] ?? {};
        _isStatsLoading = false;
      });
    } catch (error) {
      setState(() {
        _isStatsLoading = false;
      });
      print('Error fetching hero stats: $error');
    }
  }

  late GraphQLClient _client;

  // HTTP client for hero names with User-Agent header
  final http.Client _httpClient = http.Client();

  @override
  void initState() {
    super.initState();
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
    fetchMatchupDetails();
    fetchHeroStats();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  // Get attribute icon similar to how it's done in hero_tile.dart
  Widget getAttributeIcon(String primaryAttr) {
    switch (primaryAttr) {
      case 'all':
        return Image.asset('lib/icons/attr_universal.png', width: 24, height: 24);
      case 'int':
        return Image.asset('lib/icons/attr_intelligence.png', width: 24, height: 24);
      case 'agi':
        return Image.asset('lib/icons/attr_agility.png', width: 24, height: 24);
      case 'str':
        return Image.asset('lib/icons/attr_strength.png', width: 24, height: 24);
      default:
        return SizedBox();
    }
  }

  Future<void> fetchMatchupDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QueryOptions options = QueryOptions(
        document: gql(r'''
        query HeroVsHeroMatchup($heroId: Short!) {
          heroStats {
            heroVsHeroMatchup(heroId: $heroId) {
              advantage {
                heroId
                vs {
                  heroId1
                  heroId2
                  winRateHeroId1
                  winRateHeroId2
                  matchCount
                  winCount
                }
              }
              disadvantage {
                heroId
                vs {
                  heroId1
                  heroId2
                  winRateHeroId1
                  winRateHeroId2
                  matchCount
                  winCount
                }
              }
            }
          }
        }
      '''),
        variables: {
          'heroId': widget.hero.id,
        },
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        print('GraphQL Error: ${result.exception.toString()}');
        throw Exception('Failed to load hero matchups');
      }

      // Fetch all heroes to get names
      final heroNamesResponse = await _httpClient.get(
        Uri.parse('https://api.opendota.com/api/heroes'),
      );

      Map<int, String> heroNames = {};
      if (heroNamesResponse.statusCode == 200) {
        List<dynamic> heroesJson = json.decode(heroNamesResponse.body);
        heroNames = {for (var hero in heroesJson) hero['id']: hero['localized_name']};
      }

      // Process matchup data
      List<Map<String, dynamic>> matchupDetails = [];
      Set<int> processedHeroIds = {};

      // Process advantage matchups
      var advantageMatchups = result.data?['heroStats']['heroVsHeroMatchup']['advantage'] ?? [];
      for (var advantageGroup in advantageMatchups) {
        var vsList = advantageGroup['vs'];
        for (var matchup in vsList) {
          int opponentHeroId = matchup['heroId1'] == widget.hero.id
              ? matchup['heroId2']
              : matchup['heroId1'];

          if (processedHeroIds.contains(opponentHeroId)) continue;

          // Calculate correct win rate based on the hero's perspective
          double heroWinRate, opponentWinRate;
          if (matchup['heroId1'] == widget.hero.id) {
            heroWinRate = (matchup['winCount'] / matchup['matchCount']) * 100;
            opponentWinRate = (matchup['matchCount'] - matchup['winCount']) / matchup['matchCount'] * 100;
          } else {
            opponentWinRate = (matchup['winCount'] / matchup['matchCount']) * 100;
            heroWinRate = (matchup['matchCount'] - matchup['winCount']) / matchup['matchCount'] * 100;
          }

          String opponentHeroName = heroNames[opponentHeroId] ?? 'Unknown Hero';
          String opponentHeroImage = 'https://cdn.dota2.com/apps/dota2/images/heroes/${opponentHeroName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '')}_full.png';
          opponentHeroImage = DotaHero(
              id: opponentHeroId,
              name: opponentHeroName,
              localizedName: opponentHeroName,
              primaryAttr: '',
              attackType: '',
              roles: []
          ).imageUrl;

          matchupDetails.add({
            'opponent_hero_name': opponentHeroName,
            'games_played': matchup['matchCount'],
            'win_rate': heroWinRate.toStringAsFixed(2),
            'opponent_win_rate': opponentWinRate.toStringAsFixed(2),
            'opponent_hero_image': opponentHeroImage,
            'opponent_hero_id': opponentHeroId,
            'is_advantage': true,
          });

          processedHeroIds.add(opponentHeroId);
        }
      }

      // Process disadvantage matchups
      var disadvantageMatchups = result.data?['heroStats']['heroVsHeroMatchup']['disadvantage'] ?? [];
      for (var disadvantageGroup in disadvantageMatchups) {
        var vsList = disadvantageGroup['vs'];
        for (var matchup in vsList) {
          int opponentHeroId = matchup['heroId1'] == widget.hero.id
              ? matchup['heroId2']
              : matchup['heroId1'];

          if (processedHeroIds.contains(opponentHeroId)) continue;

          // Calculate correct win rate based on the hero's perspective
          double heroWinRate, opponentWinRate;
          if (matchup['heroId1'] == widget.hero.id) {
            heroWinRate = (matchup['winCount'] / matchup['matchCount']) * 100;
            opponentWinRate = (matchup['matchCount'] - matchup['winCount']) / matchup['matchCount'] * 100;
          } else {
            opponentWinRate = (matchup['winCount'] / matchup['matchCount']) * 100;
            heroWinRate = (matchup['matchCount'] - matchup['winCount']) / matchup['matchCount'] * 100;
          }

          String opponentHeroName = heroNames[opponentHeroId] ?? 'Unknown Hero';
          String opponentHeroImage = 'https://cdn.dota2.com/apps/dota2/images/heroes/${opponentHeroName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '')}_full.png';

          matchupDetails.add({
            'opponent_hero_name': opponentHeroName,
            'games_played': matchup['matchCount'],
            'win_rate': heroWinRate.toStringAsFixed(2),
            'opponent_win_rate': opponentWinRate.toStringAsFixed(2),
            'opponent_hero_image': opponentHeroImage,
            'opponent_hero_id': opponentHeroId,
            'is_advantage': false,
          });

          processedHeroIds.add(opponentHeroId);
        }
      }

      _sortMatchups(matchupDetails);

      setState(() {
        _matchups = matchupDetails;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching matchups: $error');
    }
  }



  void _sortMatchups(List<Map<String, dynamic>> matchups) {
    if (_sortOption == 'Highest Win Rate') {
      matchups.sort((a, b) => double.parse(b['win_rate']).compareTo(double.parse(a['win_rate'])));
    } else if (_sortOption == 'Lowest Win Rate') {
      matchups.sort((a, b) => double.parse(a['win_rate']).compareTo(double.parse(b['win_rate'])));
    } else if (_sortOption == 'Alphabetically') {
      matchups.sort((a, b) => a['opponent_hero_name'].compareTo(b['opponent_hero_name']));
    }
  }

  Widget _buildStatsSection() {
    if (_isStatsLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.grey[200],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildStatRow('Attack Type', _heroStats['attackType'] ?? 'N/A'),
          _buildStatRow('Starting Damage',
              '${_heroStats['startingDamageMin'] ?? 'N/A'} - ${_heroStats['startingDamageMax'] ?? 'N/A'}'),
          _buildStatRow('Attack Range', _heroStats['attackRange']?.toString() ?? 'N/A'),
          _buildStatRow('Base Strength', _heroStats['strengthBase']?.toString() ?? 'N/A'),
          _buildStatRow('Base Intelligence', _heroStats['intelligenceBase']?.toString() ?? 'N/A'),
          _buildStatRow('Base Agility', _heroStats['agilityBase']?.toString() ?? 'N/A'),
          _buildStatRow('HP Regen', _heroStats['hpRegen']?.toString() ?? 'N/A'),
          _buildStatRow('MP Regen', _heroStats['mpRegen']?.toString() ?? 'N/A'),
          _buildStatRow('Move Speed', _heroStats['moveSpeed']?.toString() ?? 'N/A'),
          _buildStatRow('Complexity', _heroStats['complexity']?.toString() ?? 'N/A'),
        ]),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white70,
              fontFamily: "Inter",
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    // Filter the matchups based on the search query
    List<Map<String, dynamic>> filteredMatchups = _matchups.where((matchup) {
      return matchup['opponent_hero_name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10)
          : Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            surfaceTintColor: isDarkMode ? const Color.fromARGB(255, 10, 10, 10) : Colors.white,
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode ? const Color.fromARGB(255, 10, 10, 10) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred background using hero image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.hero.imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.6),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Hero details centered in the flexible space
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          // Hero image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.network(
                              widget.hero.imageUrl,
                              width: 140.0,
                              height: 140.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Hero name and attribute
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.hero.localizedName,
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 5),
                              getAttributeIcon(widget.hero.primaryAttr),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          // Roles
                          Text(
                            'Roles: ${widget.hero.roles.join(', ')}',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 16.0,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Matchups Section
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CustomToggle(
                      items: const ['Matchups', 'Items', 'Stats'],
                      selectedIndex: _currentTabIndex,
                      onToggle: (index) {
                        setState(() {
                          _currentTabIndex = index;
                        });
                      },
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  SizedBox(height: 10.0),

                  // Conditional content based on selected tab
                  if (_currentTabIndex == 0) ...[
                    Text(
                      'Matchups',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 10.0),
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
                          hintText: 'Search Matchups...',
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
                    SizedBox(height: 10.0),
                    if (!_isLoading) DropdownButton<String>(
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                      padding: EdgeInsets.only(left: 10, right: 10),
                      value: _sortOption,
                      items: <String>[
                        'Highest Win Rate',
                        'Lowest Win Rate',
                        'Alphabetically',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600),),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _sortOption = newValue!;
                          _sortMatchups(_matchups);
                          filteredMatchups = _matchups.where((matchup) {
                            return matchup['opponent_hero_name']
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ] else if (_currentTabIndex == 1) ...[
                    Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        )
                    ),
                    SizedBox(height: 10.0),
                    HeroItems(
                      heroId: widget.hero.id,
                    ),
                  ] else ...[
                    Text(
                      'Hero Stats',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Show loading indicator or content based on loading state
          if (_currentTabIndex == 2)
            _buildStatsSection()
          else if (_currentTabIndex == 0)
            _isLoading
                ? SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index >= filteredMatchups.length) {
                      return null;
                    }
                    return _buildMatchupItem(filteredMatchups[index], isDarkMode);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}