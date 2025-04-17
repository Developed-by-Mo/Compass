// utils/theme_utils.dart
import 'package:flutter/material.dart';

class ThemeUtils {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black87;
  }

  static TextStyle getHeadingStyle(bool isDarkMode) {
    return TextStyle(
      fontFamily: "Inter",
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: getTextColor(isDarkMode),
    );
  }
}