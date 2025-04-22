import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true;
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _updateSystemNavigationBarColor(isDarkMode);
  }

  static Future<void> toggleTheme(bool isDarkMode) async {
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await _updateSystemNavigationBarColor(isDarkMode);
  }

  static Future<void> _updateSystemNavigationBarColor(bool isDarkMode) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (isDarkMode) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.grey[900],
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.grey[300],
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // Adjust top bar icon brightness based on theme
      ));
    }
  }
}
