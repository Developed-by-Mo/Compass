import 'package:flutter/material.dart';
import '../dota_hero.dart';
import '../pages/hero_info.dart';
import '../services/player_services.dart';
import '../utils/theme_utils.dart';

class HeroesTab extends StatelessWidget {
  final List<Map<String, dynamic>> heroStats;
  final Map<int, DotaHero> heroesMap;
  final bool isDarkMode;

  const HeroesTab({
    super.key,
    required this.heroStats,
    required this.heroesMap,
    required this.isDarkMode,
  });

  String _calculateWinRate(int games, int wins) {
    if (games == 0) return '0%';
    return '${((wins / games) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Heroes',
            style: ThemeUtils.getHeadingStyle(isDarkMode),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: heroStats.length,
          itemBuilder: (context, index) {
            final hero = heroStats[index];
            final heroId = hero['hero_id'];
            final games = hero['games'] ?? 0;
            final wins = hero['win'] ?? 0;

            final imageUrl = PlayerService.getHeroImageUrl(heroId, heroesMap);
            final heroName = PlayerService.getHeroName(heroId, heroesMap);
            final dotaHero = heroesMap[heroId];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
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
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      )
                          : _buildErrorImage(),
                    ),
                    title: Text(
                      heroName,
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextColor(isDarkMode),
                      ),
                    ),
                    subtitle: Text(
                      'Games: $games | Win Rate: ${_calculateWinRate(games, wins)}',
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          wins.toString(),
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.green[400] : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 100)
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width: 50,
      height: 50,
      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
      child: Icon(
        Icons.videogame_asset,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
      ),
    );
  }
}