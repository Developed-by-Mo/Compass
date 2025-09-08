import 'package:flutter/material.dart';

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailPage({Key? key, required this.item}) : super(key: key);

  String _stripHtmlTags(String htmlString) {
    // Remove HTML tags using RegExp
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color.fromARGB(255, 20, 20, 20) : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color.fromARGB(255, 20, 20, 20) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          item['displayName'] ?? 'Item Details',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      item['image'] != null
                          ? Image.network(
                            item['image'],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  Icons.inventory,
                                  size: 60,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                          )
                          : Icon(
                            Icons.inventory,
                            size: 60,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Item Name
            Text(
              item['displayName'] ?? 'Unknown Item',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Item Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cost
                  if (item['cost'] != null && item['cost'] > 0) ...[
                    Row(
                      children: [
                        Image.asset(
                          'lib/icons/gold.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item['cost']}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Neutral Item (only show if we have the information)
                  if (item['isNeutral'] == true) ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Neutral Item: Yes',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Description if available
                  if (item['description'] != null &&
                      item['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stripHtmlTags(item['description'].toString()),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Lore if available
                  if (item['lore'] != null &&
                      item['lore'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Lore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['lore'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        fontFamily: 'Inter',
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Notes if available
                  if (item['notes'] != null &&
                      item['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['notes'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
