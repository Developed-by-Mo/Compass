import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:compass/widgets/gradient_landing_button.dart';
import 'dart:ui';

import '../widgets/animated_shadow_button.dart';

class LandingPage extends StatelessWidget {
  final bool isDarkMode;

  const LandingPage({super.key, this.isDarkMode = true});

  @override
  Widget build(BuildContext context) {

    // Set system UI overlay style for transparency
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.light, // Light icons/text in status bar
      systemNavigationBarColor: Colors.transparent, // Make navigation bar transparent
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light, // Light icons in navigation bar
    ));

    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    return Scaffold(
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Background image
              Container(
                width: screenWidth,
                height: screenHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/images/LandingBG.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Dark overlay with gradient
              Container(
                width: screenWidth,
                height: screenHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.black87,
                    ],
                  ),
                ),
              ),

              // Blur effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Content
                    Column(
                      children: [
                        const SizedBox(height: 80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "lib/icons/compass-logo.png",
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color.fromARGB(255, 66, 66, 66),
                              width: 90.0,
                              height: 90.0,
                            ),
                            const SizedBox(width: 0),
                            Text(
                              "C O M P A S S",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 33.0,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color.fromARGB(255, 66, 66, 66),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "P  O  W  E  R  E  D      B  Y      S  T  R  A  T  Z",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color.fromARGB(255, 66, 66, 66),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Features Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.track_changes,
                            text: 'Track your favorite heroes',
                            description:
                            'Monitor hero performance, win rates, and individual stats.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            icon: Icons.analytics,
                            text: 'Analyze match statistics',
                            description:
                            'Deep dive into comprehensive match data and insights.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            icon: Icons.update,
                            text: 'Get real-time updates',
                            description:
                            'Stay informed with live match and player information.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            icon: Icons.favorite_border,
                            text: 'Community-Driven Project',
                            description:
                            'This app is a non-profit passion project\nCreated to serve the Dota 2 community\nNo ads, no monetization',
                          ),
                        ],
                      ),
                    ),

                    // Get Started Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GradientButtonFb1(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/home');
                        },
                        text: 'Get Started',
                      ),
                    ),
                    SizedBox(height: 10)
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
    required String description,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
