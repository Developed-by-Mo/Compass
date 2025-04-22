// main.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:compass/pages/home_page.dart';
import 'package:compass/pages/landing_page.dart';
import 'package:compass/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    SystemUiOverlay.top,
  ]);

  // Load the theme and check if it's the user's first launch
  await ThemeProvider.loadTheme();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(MainApp(isFirstLaunch: isFirstLaunch));

  if (isFirstLaunch) {
    await prefs.setBool('isFirstLaunch', false);
  }}

Future<void> clearPrefs() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.clear();
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class MainApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MainApp({required this.isFirstLaunch, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          scrollBehavior: AppScrollBehavior(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          initialRoute: isFirstLaunch ? '/landing' : '/home',
          routes: {
            '/landing': (context) => const LandingPage(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}
