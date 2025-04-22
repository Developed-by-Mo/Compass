import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';

class PlayerAppBar extends StatelessWidget {
  final String playerName;
  final String avatarUrl;
  final bool isDarkMode;
  final String accountId;
  final VoidCallback? onLogout;  // Added onLogout callback

  const PlayerAppBar({
    super.key,
    required this.playerName,
    required this.avatarUrl,
    required this.isDarkMode,
    required this.accountId,
    this.onLogout,  // Added to constructor
  });


  String get steamProfileUrl {
    final steamId64 = int.parse(accountId) + 76561197960265728;
    return "https://steamcommunity.com/profiles/$steamId64";
  }

  void _openSteamProfile() async {
    final url = Uri.parse(steamProfileUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      surfaceTintColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10)
          : Colors.white,
      iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 10, 10, 10)
          : Colors.white,
      actions: [
        if (onLogout != null) // Only show logout if callback is provided
          IconButton(
            icon: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white : Colors.white,
            ),
            onPressed: onLogout,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                playerName,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[200]!,
                ),
              ),
            ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: _openSteamProfile,
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 30.0),
                    child: SvgPicture.asset(
                      'lib/icons/steam-brands-solid.svg',
                      color: isDarkMode ? Colors.grey[200] : Colors.grey[200],
                      height: 24,
                      width: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
        background: _buildBackground(),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDarkMode ? Colors.grey[900]! : Colors.grey[700]!,
                  isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                ],
              ),
            ),
          ),
        Positioned(
          left: 20,
          bottom: 70,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.white,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person,
                size: 40,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400])
                : null,
          ),
        ),
      ],
    );
  }
}
