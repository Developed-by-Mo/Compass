import 'package:flutter/material.dart';
import 'package:compass/dota_hero.dart';
import 'package:compass/pages/hero_info.dart';

class HeroTile extends StatelessWidget {
  final DotaHero hero;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;

  const HeroTile({
    Key? key,
    required this.hero,
    required this.isFavorited,
    required this.onFavoriteToggle,
  }) : super(key: key);

  Widget getAttributeIcon(String primaryAttr) {
    switch (primaryAttr) {
      case 'all':
        return Image.asset('lib/icons/attr_universal.png', width: 20, height: 20);
      case 'int':
        return Image.asset('lib/icons/attr_intelligence.png', width: 20, height: 20);
      case 'agi':
        return Image.asset('lib/icons/attr_agility.png', width: 20, height: 20);
      case 'str':
        return Image.asset('lib/icons/attr_strength.png', width: 20, height: 20);
      default:
        return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HeroInfo(hero: hero),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            SizedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    Image.network(
                      hero.imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Placeholder for failed image loading
                        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.grey[300];
                        final iconColor = isDarkMode ? Colors.white : Colors.black;

                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: backgroundColor,
                          child: Center(
                            child: Icon(
                              Icons.broken_image, // Placeholder icon
                              color: iconColor,
                              size: 40.0,
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Overlay the text and buttons here
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              getAttributeIcon(hero.primaryAttr),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  hero.localizedName,
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Scrapped favorite feature
                              // GestureDetector(
                              //   onTap: onFavoriteToggle,
                              //   child: AnimatedSwitcher(
                              //     duration: Duration(milliseconds: 300),
                              //     transitionBuilder: (Widget child, Animation<double> animation) {
                              //       return ScaleTransition(
                              //         scale: animation,
                              //         child: child,
                              //       );
                              //     },
                              //     child: Icon(
                              //       isFavorited ? Icons.favorite : Icons.favorite_border,
                              //       key: ValueKey<bool>(isFavorited),
                              //       color: isFavorited ? Colors.red : Colors.white,
                              //       size: 24.0,
                              //       shadows: [
                              //         Shadow(
                              //           blurRadius: 10.0,
                              //           color: Colors.black,
                              //           offset: Offset(1.0, 1.0),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}