// player_details_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

import '../dota_hero.dart';
import '../services/player_services.dart';
import '../widgets/player_app_bar.dart';
import '../widgets/stats_tab.dart';
import '../widgets/heroes_tab.dart';
import '../widgets/matches_tab.dart';
import '../utils/theme_utils.dart';

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

class PlayerDetailsPage extends StatefulWidget {
  final String playerName;
  final String accountId;
  final String avatarUrl;
  final bool showAppBar;
  final bool isTab;
  final VoidCallback? onLogout;

  const PlayerDetailsPage({
    super.key,
    required this.playerName,
    required this.accountId,
    required this.avatarUrl,
    this.showAppBar = false,
    this.isTab = false,
    this.onLogout,
  });

  @override
  State<PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  int _currentTabIndex = 0;
  List<Map<String, dynamic>> _heroStats = [];
  List<Map<String, dynamic>> _recentMatches = [];
  Map<int, DotaHero> _heroesMap = {};
  bool _isLoading = true;
  String _errorMessage = '';
  Map<int, String> itemImages = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Fetch item images before other data
      itemImages = await PlayerService.fetchItemImages();

      await _fetchHeroes();
      await Future.wait([
        _fetchHeroStats(),
        _fetchRecentMatches()
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while initializing data';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHeroes() async {
    try {
      _heroesMap = await PlayerService.fetchHeroes();
    } catch (e) {
      throw Exception('Error fetching heroes: $e');
    }
  }

  Future<void> _fetchHeroStats() async {
    try {
      final data = await PlayerService.fetchHeroStats(widget.accountId);
      setState(() {
        _heroStats = data;
        _isLoading = _recentMatches.isEmpty;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch hero stats';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentMatches() async {
    try {
      final data = await PlayerService.fetchRecentMatches(widget.accountId);
      setState(() {
        _recentMatches = data;
        _isLoading = _heroStats.isEmpty;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch recent matches';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10)
          : Colors.white,
      body: CustomScrollView(
        slivers: [
          PlayerAppBar(
            accountId: widget.accountId,
            playerName: widget.playerName,
            avatarUrl: widget.avatarUrl,
            isDarkMode: isDarkMode,
            onLogout: widget.onLogout,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CustomToggle(
                  items: const ['Overview', 'Heroes', 'Matches'],
                  selectedIndex: _currentTabIndex,
                  onToggle: (index) => setState(() => _currentTabIndex = index),
                  isDarkMode: isDarkMode,
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.grey[800]!,
                  ),
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: isDarkMode ? Colors.red[300] : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Builder(
                builder: (_) {
                  switch (_currentTabIndex) {
                    case 0:
                      print("Account ID: " +  widget.accountId);
                      return StatsTab(
                        accountId: widget.accountId,
                        isDarkMode: isDarkMode,
                      );
                    case 1:
                      return HeroesTab(
                        heroStats: _heroStats,
                        heroesMap: _heroesMap,
                        isDarkMode: isDarkMode,
                      );
                    case 2:
                      return MatchesTab(
                        recentMatches: _recentMatches,
                        heroesMap: _heroesMap,
                        isDarkMode: isDarkMode,
                        itemImages: itemImages,
                      );
                    default:
                      return Center(
                        child: Text(
                          "Invalid Tab",
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        ),
                      );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}