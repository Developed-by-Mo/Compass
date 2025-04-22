import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DotaNewsCarousel extends StatefulWidget {
  @override
  _DotaNewsCarouselState createState() => _DotaNewsCarouselState();
}

class _DotaNewsCarouselState extends State<DotaNewsCarousel> {
  List<Map<String, String>> newsItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDotaNews();
  }

  Future<void> fetchDotaNews() async {
    const url =
        'https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=570&count=5';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newsList = data['appnews']['newsitems'] as List;

        setState(() {
          newsItems = newsList.map((news) {
            final String? content = news['contents'];

            // Replace {STEAM_CLAN_IMAGE} with the correct base URL
            final String baseUrl = 'https://clan.fastly.steamstatic.com/images/';
            final String processedContent =
                content?.replaceAll('{STEAM_CLAN_IMAGE}', baseUrl) ?? '';

            // Regex to extract image URLs
            final RegExp imageRegex = RegExp(
              r'https?://[^\s]+(?:png|jpg|jpeg|gif)',
              caseSensitive: false,
            );
            final matches = imageRegex.allMatches(processedContent).toList();
            final String? imageUrl = matches.isNotEmpty
                ? matches.first.group(0) // Get the first valid image URL
                : null;

            // Parse and clean up the content
            final parsedContent = parse(processedContent);
            String plainHtmlText = parsedContent.body?.text ?? 'No description available';

            // Further clean up plainHtmlText to remove any lingering URLs
            plainHtmlText = plainHtmlText.replaceAll(RegExp(r'https?://[^\s]+'), '');
            plainHtmlText = plainHtmlText.replaceAll(RegExp(r'{.*?}'), ''); // Remove placeholders
            plainHtmlText = plainHtmlText.replaceAll(RegExp(r'\[.*?\]'), ''); // Remove BBCode
            plainHtmlText = plainHtmlText.trim();

            // Decode HTML entities
            final unescapedContent = HtmlUnescape().convert(plainHtmlText);

            return {
              'title': news['title'] as String,
              'description': unescapedContent.isNotEmpty
                  ? unescapedContent
                  : 'No description available',
              'imageUrl': imageUrl ??
                  'https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg', // Fallback image
              'link': news['url'] as String,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching news: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.grey[200] : Colors.black,));
    }

    if (newsItems.isEmpty) {
      return Center(child: Text('No news available'));
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 275,
        autoPlay: true,
        enlargeCenterPage: true,
        autoPlayInterval: Duration(seconds: 5),
        aspectRatio: 16 / 9,
      ),
      items: newsItems.map((news) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(news['imageUrl']!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? Colors.black54 : Colors.black45,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      news['title']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Inter",
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      news['description']!.length > 100
                          ? '${news['description']!.substring(0, 100)}...'
                          : news['description']!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey[200],
                        fontSize: 14,
                        fontFamily: "Inter",
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final url = news['link']!;
                        _launchUrl(url);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.red[700]
                            : Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Read More',
                        style: TextStyle(fontFamily: "Inter"),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

// Method to launch a URL using url_launcher
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url); // Parse the string into a Uri object
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}
