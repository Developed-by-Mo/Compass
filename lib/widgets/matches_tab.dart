import 'package:flutter/material.dart';
import '../dota_hero.dart';
import '../pages/match_details_page.dart';
import '../services/player_services.dart';
import '../utils/theme_utils.dart';

class MatchesTab extends StatelessWidget {
  final List<Map<String, dynamic>> recentMatches;
  final Map<int, DotaHero> heroesMap;
  final bool isDarkMode;
  final Map<int, String> itemImages;

  const MatchesTab({
    super.key,
    required this.recentMatches,
    required this.heroesMap,
    required this.isDarkMode,
    required this.itemImages,
  });

  String _formatMatchResult(Map<String, dynamic> match) {
    final bool isRadiant = match['player_slot'] <= 4;
    final bool didWin = match['radiant_win'] == (isRadiant ? true : false);
    return didWin ? 'Win' : 'Loss';
  }

  Color _getResultColor(bool isWin) {
    if (isWin) {
      return const Color(0xFF2E7D32); // Dark green
    } else {
      return const Color(0xFFC62828); // Dark red
    }
  }

  String _formatMatchDuration(int durationSeconds) {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String _formatGameMode(String mode) {
    switch (mode) {
      case 'ALL_PICK':
        return 'All Pick';
      case 'CAPTAINS_MODE':
        return 'Captains Mode';
      case 'RANDOM_DRAFT':
        return 'Random Draft';
      case 'SINGLE_DRAFT':
        return 'Single Draft';
      case 'ALL_RANDOM':
        return 'All Random';
      case 'ALL_PICK_RANKED':
        return 'Ranked All Pick';
      case 'TURBO':
        return 'Turbo';
      case 'ABILITY_DRAFT':
        return 'Ability Draft';
      default:
      // Convert other modes from UPPER_CASE to Title Case
        return mode.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Recent Matches',
            style: ThemeUtils.getHeadingStyle(isDarkMode),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentMatches.length,
          itemBuilder: (context, index) {
            final match = recentMatches[index];
            final heroId = match['hero_id'] ?? 0;
            final imageUrl = PlayerService.getHeroImageUrl(heroId, heroesMap);
            final gameMode = _formatGameMode(match['gameMode'] ?? 'UNKNOWN');
            final matchResult = _formatMatchResult(match);
            final isWin = matchResult == 'Win';

            return GestureDetector(
              onTap: () {
                final matchId = match['id'];
                if (matchId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchDetailsPage(
                        matchId: matchId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to retrieve match details')),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameMode,
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            color: ThemeUtils.getTextColor(isDarkMode),
                          ),
                        ),
                        Text(
                          PlayerService.convertToRelativeTime(match['startDateTime']),
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          matchResult,
                          style: TextStyle(
                            fontFamily: "Inter",
                            color: _getResultColor(isWin),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' | ${_formatMatchDuration(match['duration'])}',
                          style: TextStyle(
                            fontFamily: "Inter",
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildItemImage(match['item0Id'], itemImages),
                          _buildItemImage(match['item1Id'], itemImages),
                          _buildItemImage(match['item2Id'], itemImages),
                          _buildItemImage(match['item3Id'], itemImages),
                          _buildItemImage(match['item4Id'], itemImages),
                          _buildItemImage(match['item5Id'], itemImages),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 100)
      ],
    );
  }

  Widget _buildItemImage(int? itemId, Map<int, String> itemImages) {
    if (itemId == null || itemId == 0 || !itemImages.containsKey(itemId)) {
      return Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(2),
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      );
    }

    return Container(
      margin: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          itemImages[itemId]!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 28,
            height: 28,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              size: 20,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ),
      ),
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