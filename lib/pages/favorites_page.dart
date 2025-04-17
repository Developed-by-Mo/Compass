import 'package:flutter/material.dart';
import 'package:test_dota_api_app/dota_hero.dart';
import 'package:test_dota_api_app/widgets/hero_tile.dart';

class FavoritesPage extends StatefulWidget {
  final List<DotaHero> allHeroes;
  final Map<int, bool> favoriteStatus;
  final Function(int) toggleFavorite;

  const FavoritesPage({
    super.key,
    required this.allHeroes,
    required this.favoriteStatus,
    required this.toggleFavorite,
  });

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter to show only favorited heroes
    List<DotaHero> favoritedHeroes = widget.allHeroes
        .where((hero) => widget.favoriteStatus[hero.id] == true)
        .toList();

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10) // Slightly lighter black
          : Colors.white,
      body: favoritedHeroes.isNotEmpty
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 22,
                        color: isDarkMode ? Colors.white : const Color.fromARGB(255, 66, 66, 66),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Favorites",
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
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      DotaHero hero = favoritedHeroes[index];
                      return HeroTile(
                        hero: hero,
                        isFavorited: widget.favoriteStatus[hero.id] ?? false,
                        onFavoriteToggle: () {
                          widget.toggleFavorite(hero.id);
                          // Remove hero from list when unfavorited
                          setState(() {
                            favoritedHeroes = widget.allHeroes
                                .where(
                                    (hero) => widget.favoriteStatus[hero.id] == true)
                                .toList();
                          });
                        },
                      );
                    },
                    childCount: favoritedHeroes.length,
                  ),
                ),
              ],
            )
          : Center(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 90,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Favorite Heroes",
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Tap the heart icon on hero tiles to save your favorite Dota 2 heroes for quick access",
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
    );
  }
}
