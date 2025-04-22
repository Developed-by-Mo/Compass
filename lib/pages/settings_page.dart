// Settings Page

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:compass/theme_provider.dart'; // Import theme provider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false; // Initially dark mode
  final websiteUri = Uri.parse('https://buymeacoffee.com/developedbymo');
  final contactUri = Uri.parse('https://developedbymo.me/#contact');
  final sourceCodeUri = Uri.parse('https://github.com/Developed-by-Mo/Compass');

  @override
  void initState() {
    super.initState();
    // Load the current theme mode to reflect the saved state
    isDarkMode = ThemeProvider.themeModeNotifier.value == ThemeMode.dark;
  }

  // Method to launch a URL using url_launcher
  Future<void> _launchUrl(Uri uri) async {
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    // Set tile color based on theme mode (light or dark)
    final tileColor = theme.brightness == Brightness.dark
        ? Colors.grey[900] // Dark mode color
        : Colors.grey[300]; // Light mode color (light grey)

    // Custom switch colors for dark mode
    final switchActiveColor = theme.brightness == Brightness.dark
        ? Colors.grey[400] // Grey color for dark mode when active
        : Colors.grey[400]; // Default color for light mode when active

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Scaffold(
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 10, 10, 10) // Slightly lighter black
            : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? const Color.fromARGB(255, 10, 10, 10) // Slightly lighter black
              : Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings, // Settings icon
                size: 22,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : const Color.fromARGB(255, 66, 66, 66),
              ),
              const SizedBox(width: 10), // Space between icon and text
              Text(
                "Settings",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : const Color.fromARGB(255, 66, 66, 66),
                ),
              ),
            ],
          ),
          centerTitle: true, // Keep the title centered
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dark Mode Tile
              _buildTile(
                icon: Icons.brightness_6,
                label: "Dark Mode",
                trailing: Switch(
                  value: isDarkMode,
                  activeColor: switchActiveColor,
                  inactiveTrackColor: Colors.grey[200],
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                      ThemeProvider.toggleTheme(isDarkMode);
                    });
                  },
                ),
                color: tileColor,
                textColor: textColor,
              ),
              // Source Code Tile
              GestureDetector(
                onTap: () => _launchUrl(sourceCodeUri), // Launch source code URL
                child: _buildTile(
                  icon: Icons.code,
                  label: "Source Code",
                  color: tileColor,
                  textColor: textColor,
                ),
              ),
              // Buy Me a Coffee Tile
              GestureDetector(
                onTap: () => _launchUrl(websiteUri),
                child: _buildTile(
                  icon: Icons.local_cafe,
                  label: "Buy me a coffee!",
                  color: tileColor,
                  textColor: textColor,
                ),
              ),
              // Contact Me Tile
              GestureDetector(
                onTap: () => _launchUrl(contactUri),
                child: _buildTile(
                  icon: Icons.email,
                  label: "Contact me",
                  color: tileColor,
                  textColor: textColor,
                ),
              ),
              Spacer(), // Push the disclaimer to the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 66.0),
                child: Text(
                  "Disclaimer: All the data provided is retrieved via the OpenDota public API. Data may occasionally be outdated or inaccurate. This App is not affiliated with Valve Corporation or Dota 2.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor?.withOpacity(0.7),
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a reusable tile
  Widget _buildTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    required Color? color,
    required Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}