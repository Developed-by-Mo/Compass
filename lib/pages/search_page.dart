// Search Page

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:compass/pages/player_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PlayerSearchResult> _searchResults = []; // Changed to a custom class
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  String _currentQuery = '';

  Future<void> _searchPlayers(String query) async {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // If query is empty, clear results
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear(); // Explicitly clear results
        _errorMessage = '';
        _currentQuery = '';
      });
      return;
    }

    // Debounce the search to prevent rapid API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // Check if the query has changed during the delay
      if (query != _currentQuery) {
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _searchResults.clear(); // Clear existing results before new search
      });

      try {
        final response = await http.get(
          Uri.parse('https://api.opendota.com/api/search?q=${Uri.encodeComponent(query)}'),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Search request timed out'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // Only update results if the query hasn't changed
          if (mounted && query == _currentQuery) {
            setState(() {
              // Convert to our custom PlayerSearchResult class
              _searchResults = data.map((playerData) => PlayerSearchResult(
                playerName: playerData['personaname'] ?? 'Unknown',
                accountId: playerData['account_id']?.toString() ?? 'N/A',
                initialAvatarUrl: playerData['avatar'] ?? '',
              )).toList();
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch players';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred while searching';
          _isLoading = false;
        });
      }
    });

    // Store the current query
    _currentQuery = query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10) // Slightly lighter black
          : Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 22,
                        color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Search Players",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 22.0,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 13,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchPlayers,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: "Inter",
                      ),
                      cursorColor: isDarkMode ? Colors.white : Colors.black, // Set cursor color
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        hintText: 'Search players...',
                        hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontFamily: "Inter"
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : Colors.grey[800]!,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: "Inter",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // New condition to show initial search prompt
          if (_searchResults.isEmpty && !_isLoading && _searchController.text.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      size: 90,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Find Dota 2 Players",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 40.0, left: 40, bottom: 210),
                      child: Text(
                        "Search by player name or account ID to explore Dota 2 profiles and match history",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final player = _searchResults[index];
                return PlayerCard(
                  key: ValueKey(player.accountId), // Add a unique key
                  playerName: player.playerName,
                  accountId: player.accountId,
                  initialAvatarUrl: player.initialAvatarUrl,
                );
              },
              childCount: _searchResults.length,
            ),
          ),
          if (_searchResults.isEmpty && !_isLoading && _searchController.text.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 70,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 180.0),
                      child: Text(
                        "No players found",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 20,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerSearchResult {
  final String playerName;
  final String accountId;
  final String initialAvatarUrl;

  PlayerSearchResult({
    required this.playerName,
    required this.accountId,
    required this.initialAvatarUrl,
  });
}

class PlayerCard extends StatefulWidget {
  final String playerName;
  final String accountId;
  final String? initialAvatarUrl;

  const PlayerCard({
    super.key,
    required this.playerName,
    required this.accountId,
    this.initialAvatarUrl,
  });

  @override
  _PlayerCardState createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.initialAvatarUrl;
    _fetchPlayerDetails();
  }

  // If the key changes (which happens on new search), this method will be called again
  @override
  void didUpdateWidget(PlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      // Reset the state if the account ID changes
      setState(() {
        _avatarUrl = widget.initialAvatarUrl;
        _isLoading = true;
      });
      _fetchPlayerDetails();
    }
  }

  // Modify the _fetchPlayerDetails method to handle potential race conditions
  Future<void> _fetchPlayerDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.opendota.com/api/players/${widget.accountId}'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Player details request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Only update if the widget is still mounted
        if (mounted) {
          setState(() {
            _avatarUrl = data['profile']?['avatarfull'] ?? widget.initialAvatarUrl;
            _isLoading = false;
          });
        }
      } else {
        _handleErrorState();
      }
    } catch (e) {
      _handleErrorState();
    }
  }

  void _handleErrorState() {
    if (mounted) {
      setState(() {
        _avatarUrl = widget.initialAvatarUrl;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailsPage(
                  playerName: widget.playerName,
                  accountId: widget.accountId,
                  avatarUrl: _avatarUrl ?? '',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: _isLoading
                    ? _buildLoadingAvatar(isDarkMode)
                    : _buildAvatar(isDarkMode),
              ),
              title: Text(
                widget.playerName,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${widget.accountId}',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar(bool isDarkMode) {
    return Container(
      width: 50,
      height: 50,
      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDarkMode) {
    return _avatarUrl != null && _avatarUrl!.isNotEmpty
        ? Image.network(
      _avatarUrl!,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(isDarkMode),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingAvatar(isDarkMode);
      },
    )
        : _buildDefaultAvatar(isDarkMode);
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
}