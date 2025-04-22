// Home Page

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:compass/dota_hero.dart';
import 'package:http/http.dart' as http;
import 'package:compass/pages/search_page.dart';
import 'package:compass/pages/settings_page.dart';
import 'dart:convert';
import 'package:compass/pages/steam_login_page.dart';
import 'package:compass/widgets/hero_tile.dart';
import '../widgets/news_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  late Future<List<DotaHero>> futureHeroes;
  late List<DotaHero> allHeroes = [];
  late List<DotaHero> filteredHeroes = [];
  TextEditingController searchController = TextEditingController();
  int selectedIndex = 0;
  PageController _pageController = PageController();
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Map to store favorite status by hero id
  Map<int, bool> favoriteStatus = {};

  Future<List<DotaHero>> fetchDotaHeroes() async {
    final response = await http.get(Uri.parse('https://api.opendota.com/api/heroes'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<DotaHero> heroes = jsonResponse.map((hero) => DotaHero.fromJson(hero)).toList();

      // Sort the list alphabetically by hero's localized name
      heroes.sort((a, b) => a.localizedName.compareTo(b.localizedName));

      return heroes;
    } else {
      throw Exception('Failed to load heroes');
    }
  }

  @override
  void initState() {
    super.initState();
    futureHeroes = fetchDotaHeroes();
    futureHeroes.then((heroes) {
      setState(() {
        allHeroes = heroes;
        filteredHeroes = heroes;
      });
      _loadFavoriteStatus();
    });
    searchController.addListener(_onSearchChanged);
  }

  _onSearchChanged() {
    setState(() {
      filteredHeroes = allHeroes
          .where((hero) =>
              hero.localizedName.toLowerCase().contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

  void toggleFavorite(int heroId) async {
    setState(() {
      favoriteStatus[heroId] = !(favoriteStatus[heroId] ?? false);
    });
    _saveFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteIds = prefs.getStringList('favoriteHeroes');

    if (favoriteIds != null) {
      setState(() {
        favoriteStatus = {for (var id in favoriteIds) int.parse(id): true};
      });
    }
  }

  Future<void> _saveFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteIds = favoriteStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.toString())
        .toList();
    await prefs.setStringList('favoriteHeroes', favoriteIds);
  }

  @override
  void dispose() {
    searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

      // Set system UI overlay style properly and completely
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Make status bar transparent
    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
  ));

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierColor: isDarkMode
              ? Colors.black.withOpacity(0.8)
              : Colors.black.withOpacity(0.3),
          builder: (context) => AlertDialog(
            backgroundColor: isDarkMode
                ? const Color.fromARGB(255, 10, 10, 10)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Exit App',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to exit?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.grey[900]
                              : Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white54
                                : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.white10
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          SystemNavigator.pop();
                        },
                        child: Text(
                          'Exit',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // Bottom padding
            ],
          ),
        );

        return shouldExit ?? false;
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 10, 10, 10)
            : Colors.white,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // Ensures the column takes only necessary space
        children: [
          CurvedNavigationBar(
            key: _bottomNavigationKey,
            backgroundColor: Colors.transparent, // Transparent to show scaffold background
            color: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
            buttonBackgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            height: 60,
            animationDuration: Duration(milliseconds: 300),
            items: const [
              Icon(Icons.list, size: 30),
              Icon(Icons.person, size: 30), // icon was previously favorite_border
              Icon(Icons.search, size: 30),
              Icon(Icons.settings, size: 30),
            ],
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          // Spacer below the navigation bar
          Container(
            height: 15,
            color: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!, // Match the nav bar's color
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
            final CurvedNavigationBarState? navBarState = _bottomNavigationKey.currentState;
            navBarState?.setPage(index);
          });
        },
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildHeroesPage(),
          _buildFavoritesPage(),
          _buildSearchPage(),
          _buildSettingsPage(),
        ],
      ),
    ),
    );
  }

  Widget _buildHeroesPage() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<DotaHero>>(
      future: futureHeroes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.grey[200] : Colors.black,));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(top:16.0, left:16.0, right: 16.0, bottom: 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "lib/icons/compass-logo.png",
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                            width: 63.0,
                            height: 63.0,
                          ),
                          SizedBox(width: 0),
                          Text(
                            "C O M P A S S",
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "P  O  W  E  R  E  D      B  Y      S  T  R  A  T  Z",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    DotaNewsCarousel(),
                    SizedBox(height: 25.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              'Heroes',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                hintText: 'Search Heroes...',
                                hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontFamily: "Inter"),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              cursorColor: isDarkMode ? Colors.white : Colors.black,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
              filteredHeroes.isNotEmpty
                  ? SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5, // Adjust for better fit
                    crossAxisSpacing: 10, // Horizontal spacing
                    mainAxisSpacing: 0, // Reduce vertical spacing
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      DotaHero hero = filteredHeroes[index];
                      return HeroTile(
                        hero: hero,
                        isFavorited: favoriteStatus[hero.id] ?? false,
                        onFavoriteToggle: () => toggleFavorite(hero.id),
                      );
                    },
                    childCount: filteredHeroes.length,
                  ),
                )
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
                        padding: const EdgeInsets.only(bottom:140.0),
                        child: Text(
                          "No heroes found",
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
        child: filteredHeroes.isNotEmpty ? SizedBox(height: 90): null // Space at the bottom of the hero list so that it's not covered by the nav bar
                    )],
          );
        } else {
          return Center(child: Text('No data found'));
        }
      },
    );
  }

  Widget _buildFavoritesPage() {
    return const SteamLoginPage();
  }

  Widget _buildSearchPage() {
    return SearchPage();
  }

  Widget _buildSettingsPage() {
    return SettingsPage();
  }
}