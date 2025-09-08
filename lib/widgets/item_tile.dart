import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const ItemTile({Key? key, required this.item, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            SizedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120,
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
                      child:
                          item['image'] != null
                              ? Image.network(
                                item['image'],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[850]
                                            : Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                        size: 40.0,
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Center(
                                child: Icon(
                                  Icons.inventory,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                  size: 40.0,
                                ),
                              ),
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
                    // Overlay the text and cost here
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Gold icon and cost
                              if (item['cost'] != null && item['cost'] > 0) ...[
                                Image.asset(
                                  'lib/icons/gold.png',
                                  width: 16,
                                  height: 16,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  '${item['cost']}',
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.yellow[600],
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacer(),
                              ] else ...[
                                Spacer(),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            item['displayName'] ?? 'Unknown Item',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 14.0,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
